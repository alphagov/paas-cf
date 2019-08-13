package main

import (
	"strconv"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/aiven"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

func AivenCostGauge(client *aiven.Client, interval time.Duration) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		metrics := []m.Metric{}
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
				metrics = append(metrics, m.Metric{
					Kind:  m.Gauge,
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
