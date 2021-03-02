package main

import (
	"code.cloudfoundry.org/lager"
	"fmt"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas"
	"github.com/aws/aws-sdk-go/aws"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
	awsservicequotas "github.com/aws/aws-sdk-go/service/servicequotas"
	"time"
)

func RDSDBInstancesGauge(
	logger lager.Logger,
	rds *rds.RDSService,
	serviceQuotas *servicequotas.ServiceQuotas,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("rds-db-instances-gauge")
		count, err := countRDSDBInstance(rds)
		if err != nil {
			lsess.Error("count-db-instances", err)
			return err
		}
		quota, err := getRDSServiceQuota(serviceQuotas)
		if err != nil {
			lsess.Error("get-db-quota", err)
			return err
		}
		metrics := []m.Metric{
			{
				Kind:  "gauge",
				Name:  "aws.rds.dbinstances.count",
				Value: float64(count),
				Unit:  "count",
			},
			{
				Kind:  "gauge",
				Name:  "aws.rds.dbinstances.quota.count",
				Value: quota,
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

func getRDSServiceQuota(service *servicequotas.ServiceQuotas) (float64, error) {
	out, err := service.Client.GetServiceQuota(&awsservicequotas.GetServiceQuotaInput{
		QuotaCode:   aws.String("L-7B6409FD"),
		ServiceCode: aws.String("rds"),
	})

	if err != nil {
		return float64(0), err
	}

	quota := out.Quota

	if quota.ErrorReason != nil {
		return float64(0), fmt.Errorf(*quota.ErrorReason.ErrorMessage)
	}

	return *quota.Value, nil
}
