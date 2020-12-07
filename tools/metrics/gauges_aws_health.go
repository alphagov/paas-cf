package main

import (
	"code.cloudfoundry.org/lager"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/health"
	"time"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var AWSHealthServicesToAlertOn = []string {
	"ACM",
	"CLOUDFRONT",
	"EC2",
	"ELASTICACHE",
	"ELASTICLOADBALANCING",
	"NATGATEWAY",
	"RDS",
	"ROUTE53",
	"S3",
	"SES",
	"SHIELD",
	"SQS",
	"VPC",
	"WAF",
}

func AWSHealthEventsGauge(
	logger lager.Logger,
	region string,
	healthService health.HealthServiceInterface,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("aws-health-events-gauge")
		metrics := []m.Metric{}

		for _, svcName := range AWSHealthServicesToAlertOn {
			lsess.Info("request-events", lager.Data{"sevice": svcName})
			count, err := healthService.CountOpenEventsForServiceInRegion(svcName, region)

			if err != nil {
				lsess.Error("request-events", err)
				return err
			}

			metrics = append(metrics, m.Metric{
				Kind: m.Gauge,
				Name: "aws.health.active.events",
				Tags: []m.MetricTag{
					{"service", svcName},
				},
				Value: float64(count),
			})

		}


		return w.WriteMetrics(metrics)
	})
}
