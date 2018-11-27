package main

import (
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/alphagov/paas-cf/tools/metrics/pingdumb"
)

func ELBNodeFailureCountGauge(logger lager.Logger, config pingdumb.ReportConfig, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		r, err := pingdumb.GetReport(config)
		if err != nil {
			return err
		}
		failures := r.Failures()
		for _, failedCheck := range failures {
			logger.Info("elb-node-failure", lager.Data{
				"addr":  failedCheck.Addr,
				"start": failedCheck.Start.Format(time.RFC3339Nano),
				"stop":  failedCheck.Start.Format(time.RFC3339Nano),
				"err":   failedCheck.Err().Error(),
			})
		}
		return w.WriteMetrics([]Metric{
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "aws.elb.unhealthy_node_count",
				Value: float64(len(failures)),
				Unit:  "count",
			},
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "aws.elb.healthy_node_count",
				Value: float64(len(r.Checks) - len(failures)),
				Unit:  "count",
			},
		})
	})
}
