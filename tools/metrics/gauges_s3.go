package main

import (
	"time"

	"code.cloudfoundry.org/lager"
	awss3 "github.com/aws/aws-sdk-go/service/s3"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/s3"
)

func S3BucketsGauge(
	logger lager.Logger,
	s3Service *s3.S3Service,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		metrics := []m.Metric{}

		buckets, err := s3Service.Client.ListBuckets(&awss3.ListBucketsInput{})

		if err != nil {
			return err
		}

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "aws.s3.buckets.count",
			Value: float64(len(buckets.Buckets)),
			Unit:  "count",
		})

		return w.WriteMetrics(metrics)
	})
}
