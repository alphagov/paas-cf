package main

import (
	"code.cloudfoundry.org/lager"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
	"time"
)

func RDSDBInstancesGauge(
	logger lager.Logger,
	rds *rds.RDSService,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("rds-db-instances-gauge")
		count, err := countRDSDBInstance(rds)
		if err != nil {
			lsess.Error("count-db-instances", err)
			return err
		}
		metrics := []m.Metric{
			{
				Kind:  "gauge",
				Name:  "aws.rds.dbinstances.count",
				Value: float64(count),
				Unit:  "count",
			},
		}

		return w.WriteMetrics(metrics)
	})
}

func countRDSDBInstance(service *rds.RDSService) (int, error) {
	total := 0

	err := service.Client.DescribeDBInstancesPages(
		&awsrds.DescribeDBInstancesInput{},
		func(out *awsrds.DescribeDBInstancesOutput, lastPage bool) bool {
			total = total + len(out.DBInstances)
			return true
		},
	)

	if err != nil {
		return 0, err
	}

	return total, nil
}
