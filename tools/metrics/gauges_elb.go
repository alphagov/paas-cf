package main

import (
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/pingdumb"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

func ELBNodeFailureCountGauge(
	logger lager.Logger,
	config pingdumb.ReportConfig,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
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
		return w.WriteMetrics([]m.Metric{
			{
				Kind:  m.Gauge,
				Time:  time.Now(),
				Name:  "aws.elb.unhealthy_node_count",
				Value: float64(len(failures)),
				Unit:  "count",
			},
			{
				Kind:  m.Gauge,
				Time:  time.Now(),
				Name:  "aws.elb.healthy_node_count",
				Value: float64(len(r.Checks) - len(failures)),
				Unit:  "count",
			},
		})
	})
}
