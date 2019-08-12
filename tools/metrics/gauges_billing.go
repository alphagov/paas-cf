package main

import (
	"time"

	"code.cloudfoundry.org/lager"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/billing"
)

func BillingCostsGauge(
	logger lager.Logger,
	endpoint string,
	interval time.Duration,
	plans map[string]string,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		lsession := logger.Session("billing-gauges")
		billing := billing.NewClient(endpoint, lsession)

		costs, err := billing.GetCostsByPlan()
		if err != nil {
			lsession.Error("Failed to get billing costs metrics", err)
			return err
		}

		metrics := CostsByPlanGauges(costs, plans)

		lsession.Info("Writing billing metrics")
		return w.WriteMetrics(metrics)
	})
}

func CostsByPlanGauges(totalCosts []billing.CostByPlan, plans map[string]string) []Metric {
	metrics := make([]Metric, 0)

	for _, plan := range totalCosts {
		metrics = append(metrics, Metric{
			Kind:  Gauge,
			Time:  time.Now(),
			Name:  "billing.total.costs",
			Value: plan.Cost,
			Tags: MetricTags{
				MetricTag{Label: "plan_guid", Value: plan.PlanGUID},
				MetricTag{Label: "name", Value: plans[plan.PlanGUID]},
			},
			Unit: "pounds",
		})
	}

	return metrics
}
