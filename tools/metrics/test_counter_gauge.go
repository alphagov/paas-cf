package main

import "time"

func TestCounterGauge(interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}
		metrics = append(metrics, Metric{
			Kind:  Counter,
			Time:  time.Now(),
			Name:  "test.counter",
			Value: 1,
			Unit:  "count",
		})
		return w.WriteMetrics(metrics)
	})
}
