package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"code.cloudfoundry.org/lager"
)

type CostByPlan struct {
	PlanGUID string  `json:"plan_guid"`
	Cost     float64 `json:"cost"`
}

func BillingCostsGauge(
	logger lager.Logger,
	endpoint string,
	interval time.Duration,
	plans map[string]string,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		lsession := logger.Session("billing-gauges")
		costs, err := GetCostsByPlan(lsession, endpoint)
		if err != nil {
			lsession.Error("Failed to get billing costs metrics", err)
			return err
		}

		metrics := CostsByPlanGauges(costs, plans)

		lsession.Info("Writing billing metrics")
		return w.WriteMetrics(metrics)
	})
}

func GetCostsByPlan(logger lager.Logger, endpoint string) ([]CostByPlan, error) {
	lsession := logger.Session("billing-metrics")
	lsession.Info("Started Billing metrics")
	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	httpClient := http.DefaultClient

	resp, err := httpClient.Do(req)

	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Returned statuscode from costs endpoint %d", resp.StatusCode)
	}
	bodyBuffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	totalCosts := make([]CostByPlan, 0)
	err = json.Unmarshal(bodyBuffer, &totalCosts)
	if err != nil {
		return nil, err
	}

	lsession.Info("Finished Billing metrics")
	return totalCosts, nil
}

func CostsByPlanGauges(totalCosts []CostByPlan, plans map[string]string) []Metric {
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
