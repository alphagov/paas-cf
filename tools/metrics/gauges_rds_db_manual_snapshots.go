package main

import (
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas"
	"github.com/aws/aws-sdk-go/aws"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
	awsservicequotas "github.com/aws/aws-sdk-go/service/servicequotas"
)

func RDSDBManualSnapshotsGauge(
	logger lager.Logger,
	rds *rds.RDSService,
	serviceQuotas *servicequotas.ServiceQuotas,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("rds-db-manual-snapshots-gauge")
		count, err := countRDSManualSnapshots(rds)
		if err != nil {
			lsess.Error("count-manual-snapshots", err)
			return err
		}
		quota, err := getRDSManualSnapshotQuota(serviceQuotas)
		if err != nil {
			lsess.Error("get-db-quota", err)
			return err
		}
		metrics := []m.Metric{
			{
				Kind:  "gauge",
				Name:  "aws.rds.manual.snapshot.count",
				Value: float64(count),
				Unit:  "count",
			},
			{
				Kind:  "gauge",
				Name:  "aws.rds.manual.snapshot.quota.count",
				Value: quota,
				Unit:  "count",
			},
		}

		return w.WriteMetrics(metrics)
	})
}

func countRDSManualSnapshots(service *rds.RDSService) (int, error) {
	snapshots, err := service.Client.DescribeDBSnapshots(
		&awsrds.DescribeDBSnapshotsInput{
			SnapshotType: aws.String("manual"),
		})

	if err != nil {
		return 0, err
	}

	return len(snapshots.DBSnapshots), nil
}

func getRDSManualSnapshotQuota(service *servicequotas.ServiceQuotas) (float64, error) {
	out, err := service.Client.GetServiceQuota(&awsservicequotas.GetServiceQuotaInput{
		QuotaCode:   aws.String("L-9B510759"),
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
