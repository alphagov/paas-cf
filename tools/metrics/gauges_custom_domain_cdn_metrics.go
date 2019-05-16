package main

import (
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"strings"
	"time"
)

func CustomDomainCDNMetricsCollector(
	cloudFront CloudFrontServiceInterface,
	cloudWatch CloudWatchService,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
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

		var metrics []Metric
		for distributionId := range distinctDistributionIds {

			ms, err := getMetricsForDistribution(distributionId, cloudWatch)
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

func getMetricsForDistribution(id string, cloudWatch CloudWatchService) ([]Metric, error) {
	cloudwatchOutputs, err := cloudWatch.GetCDNMetricsForDistribution(id)

	if err != nil {
		return nil, err
	}

	var metrics []Metric
	for _, output := range cloudwatchOutputs {
		if len(output.Datapoints) == 0 {
			continue
		}

		switch aws.StringValue(output.Label) {
		case "Requests", "BytesDownloaded", "BytesUploaded":
			{
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
			return nil, errors.New("unexpected metric: " + *output.Label)
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
