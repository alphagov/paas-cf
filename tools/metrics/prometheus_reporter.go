package main

import (
	"strings"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/prometheus/client_golang/prometheus"
)

// PrometheusReporter is translating events into Prometheus metrics
type PrometheusReporter struct {
	registry   prometheus.Registerer
	metricVecs map[string]interface{}
}

// NewPrometheusReporter creates a new PrometheusReporter instance
func NewPrometheusReporter(registry prometheus.Registerer) *PrometheusReporter {
	return &PrometheusReporter{
		registry:   registry,
		metricVecs: map[string]interface{}{},
	}
}

// WriteMetrics converts the received metrics into Prometheus metrics.
// Any metrics are registered in the Prometheus registry the first time they created and we update these metrics later.
// This was we can manage counters correctly.
func (p *PrometheusReporter) WriteMetrics(events []Metric) error {
	var errs error
	for _, event := range events {
		labels := prometheus.Labels{}
		labelNames := make([]string, len(event.Tags))
		for i, tag := range event.Tags {
			tagParts := strings.SplitN(tag, ":", 2)
			labelNames[i] = tagParts[0]
			labels[tagParts[0]] = tagParts[1]
		}

		metricName := strings.Replace(event.Name, ".", "_", -1)

		if event.Unit != "" {
			if !strings.HasSuffix(metricName, event.Unit) {
				metricName = metricName + "_" + strings.ToLower(event.Unit)
			}
		}

		switch event.Kind {
		case Counter:
			vec, exists := p.metricVecs[event.Name]
			if !exists {
				counterVec := prometheus.NewCounterVec(prometheus.CounterOpts{
					Namespace: "paas",
					Name:      metricName,
				}, labelNames)
				p.registry.MustRegister(counterVec)
				p.metricVecs[event.Name] = counterVec
				vec = counterVec
			}

			metric, err := vec.(*prometheus.CounterVec).GetMetricWith(labels)
			if err != nil {
				errs = multierror.Append(err)
				continue
			}

			metric.Add(event.Value)
		case Gauge:
			vec, exists := p.metricVecs[event.Name]
			if !exists {
				gaugeVec := prometheus.NewGaugeVec(prometheus.GaugeOpts{
					Namespace: "paas",
					Name:      metricName,
				}, labelNames)
				p.registry.MustRegister(gaugeVec)
				p.metricVecs[event.Name] = gaugeVec
				vec = gaugeVec
			}

			metric, err := vec.(*prometheus.GaugeVec).GetMetricWith(labels)
			if err != nil {
				errs = multierror.Append(err)
				continue
			}
			metric.Set(event.Value)
		}
	}

	return errs
}
