package main

import (
	"code.cloudfoundry.org/lager"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"strings"
	"time"
)

func CustomDomainCDNMetricsCollector(logger lager.Logger, cloudFront CloudFrontServiceInterface, cloudWatch CloudWatchService, interval time.Duration, ) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		logSess := logger.Session("custom-domain-cdn-metrics-collector")
		logSess.Info("fetching-custom-domains")
		domains, err := cloudFront.CustomDomains()
		if err != nil {
			return err
		}

		distinctDistributionIds := map[string]bool{}
		for _, d := range domains {
			if _, ok := distinctDistributionIds[d.DistributionId]; !ok {
				distinctDistributionIds[d.DistributionId] = true
			}
		}

		var logkeys []string
		for id := range distinctDistributionIds {
			logkeys = append(logkeys, id)
		}
		logSess.Info("distributions-discovered", lager.Data{"distribution-ids": logkeys})

		var metrics []Metric
		for distributionId := range distinctDistributionIds {
			ms, err := getMetricsForDistribution(distributionId, cloudWatch, logSess)
			if err != nil {
				return err
			}

			for _, m := range ms {
				metrics = append(metrics, m)
			}
		}

		return w.WriteMetrics(metrics)
	})

}

func getMetricsForDistribution(id string, cloudWatch CloudWatchService, logger lager.Logger) ([]Metric, error) {
	logger.Info("get-metrics-for-distribution", lager.Data{"distribution-id": id})
	cloudwatchOutputs, err := cloudWatch.GetCDNMetricsForDistribution(id)

	if err != nil {
		return nil, err
	}

	var metrics []Metric
	for _, output := range cloudwatchOutputs {
		if len(output.Datapoints) == 0 {
			logger.Info("get-metrics-for-distribution", lager.Data{"distribution-id": id, "metric-name": *output.Label})
			continue
		}



		switch aws.StringValue(output.Label) {
		case "Requests", "BytesDownloaded", "BytesUploaded":
			{
				logger.Info(
					"metric-discovered",
					lager.Data{
						"distribution-id": id,
						"cloudwatch-metric-name": *output.Label,
						"prometheus-metric-name": metricName(*output.Label),
						"metric-value": output.Datapoints[0].Sum,
					},
				)

				unit := ""
				if *output.Label == "BytesDownloaded" || *output.Label == "BytesUploaded" {
					unit = "bytes"
				}

				metrics = append(metrics, Metric{
					Kind:  Counter,
					Name:  metricName(*output.Label),
					Time:  time.Now(),
					Value: *output.Datapoints[0].Sum,
					Tags:  metricLabels(id),
					Unit:  unit,
				})
			}

		case "TotalErrorRate", "4xxErrorRate", "5xxErrorRate":
			{
				logger.Info(
					"metric-discovered",
					lager.Data{
						"distribution-id": id,
						"cloudwatch-metric-name": *output.Label,
						"prometheus-metric-name": metricName(*output.Label),
						"metric-value": output.Datapoints[0].Average,
					},
				)

				metrics = append(metrics, Metric{
					Kind:  Gauge,
					Name:  metricName(*output.Label),
					Time:  time.Now(),
					Value: *output.Datapoints[0].Average,
					Tags:  metricLabels(id),
					Unit:  "ratio",
				})
			}

		default:
			err = errors.New("unexpected metric: " + *output.Label)
			logger.Error("get-metrics-for-distribution", err, lager.Data{"distribution-id": id, "metric-name": *output.Label})
			return nil, err
		}
	}

	return metrics, nil
}

func metricLabels(id string) []string {
	return []string{
		fmt.Sprintf("distribution_id:%s", id),
	}
}

func metricName(metric string) string {
	return fmt.Sprintf("aws_cloudfront_%s", strings.ToLower(metric))
}
