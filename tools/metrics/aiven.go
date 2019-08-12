package main

import (
	"strconv"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/aiven"
)

func AivenCostGauge(client *aiven.Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}
		invoices, err := client.GetInvoices()
		if err != nil {
			return err
		}

		for _, invoice := range invoices {
			if invoice.State == "estimate" {
				currentCost, err := strconv.ParseFloat(invoice.Cost, 64)
				if err != nil {
					return err
				}
				metrics = append(metrics, Metric{
					Kind:  Gauge,
					Time:  time.Now(),
					Name:  "aiven.estimated.cost",
					Value: currentCost,
					Unit:  "pounds",
				})
			}
		}

		return w.WriteMetrics(metrics)
	})
}
