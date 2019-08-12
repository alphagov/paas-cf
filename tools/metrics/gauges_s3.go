package main

import (
	"time"

	"code.cloudfoundry.org/lager"
	awss3 "github.com/aws/aws-sdk-go/service/s3"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/s3"
)

func S3BucketsGauge(
	logger lager.Logger,
	s3Service *s3.S3Service,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}

		buckets, err := s3Service.Client.ListBuckets(&awss3.ListBucketsInput{})

		if err != nil {
			return err
		}

		metrics = append(metrics, Metric{
			Kind:  Gauge,
			Time:  time.Now(),
			Name:  "aws.s3.buckets.count",
			Value: float64(len(buckets.Buckets)),
			Unit:  "count",
		})

		return w.WriteMetrics(metrics)
	})
}
