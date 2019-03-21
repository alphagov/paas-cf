package main

import (
	"code.cloudfoundry.org/lager"
	"github.com/aws/aws-sdk-go/service/s3"
	"time"
)

func S3BucketsGauge(
	logger lager.Logger,
	s3Service *S3Service,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}

		buckets, err := s3Service.Client.ListBuckets(&s3.ListBucketsInput{})

		if err != nil {
			return err
		}

		metrics = append(metrics, Metric{
			Kind: Gauge,
			Time: time.Now(),
			Name: "aws.s3.buckets.count",
			Value: float64(len(buckets.Buckets)),
			Unit: "count",
		})

		return w.WriteMetrics(metrics)
	})
}
