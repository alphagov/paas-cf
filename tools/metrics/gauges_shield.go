package main

import (
	"code.cloudfoundry.org/lager"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/shield"
	"time"
)

func ShieldOngoingAttacksGauge(
	logger lager.Logger,
	shieldService shield.ShieldServiceInterface,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		logSess := logger.Session("shield-ongoing-attacks-gauge")
		logSess.Info("count-ongoing-attacks")

		count, err := shieldService.CountOnGoingAttacks()

		if err != nil {
			logSess.Error("count-ongoing-attacks", err)
			return err
		}

		metric := m.Metric{
			Kind:  m.Gauge,
			Name:  "aws.shield.ongoing_attacks",
			Value: float64(count),
			Unit:  "count",
		}

		return w.WriteMetrics([]m.Metric{metric})
	})
}
