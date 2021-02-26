package main

import (
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	awscloudfront "github.com/aws/aws-sdk-go/service/cloudfront"
)

func CloudfrontDistributionInstancesGauge(
	logger lager.Logger,
	cloudfront *cloudfront.CloudFrontService,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("cloudfront-distribution-instances-gauge")
		count, err := countCloudfrontDistributionInstance(cloudfront)
		if err != nil {
			lsess.Error("count-distribution-instances", err)
			return err
		}
		if err != nil {
			lsess.Error("count-distribution-instances", err)
			return err
		}
		metrics := []m.Metric{
			{
				Kind:  "gauge",
				Name:  "aws.cloudfront.distributions.count",
				Value: float64(count),
				Unit:  "count",
			},
		}

		return w.WriteMetrics(metrics)
	})
}

func countCloudfrontDistributionInstance(service *cloudfront.CloudFrontService) (int64, error) {
	listDistributionsOutput, err := service.Client.ListDistributions(
		&awscloudfront.ListDistributionsInput{})

	if err != nil {
		return 0, err
	}

	return *listDistributionsOutput.DistributionList.Quantity, nil
}
