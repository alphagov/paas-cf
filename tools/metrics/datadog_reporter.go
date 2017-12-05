package main

import (
	"context"
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/pkg/errors"
	datadog "gopkg.in/zorkian/go-datadog-api.v2"
)

type DatadogConfig struct {
	ApiKey        string        // Datadog API Key
	AppKey        string        // Datadog App key (optional)
	Logger        lager.Logger  // A logger to use
	BatchSize     int           // Max size of batch before sending
	BatchInterval time.Duration // Max time to wait before sending anyway
	Tags          []string      // Tags added to ALL metrics
}

// DatadogReporter implements MetricWriter to allow sending Metrics to
// Datadog. Metrics will be delivered in batches to prevent issues with
// rate limiting and to make more effcient use of network resources.
type DatadogReporter struct {
	client *datadog.Client
	queue  chan datadog.Metric
	ctx    context.Context
	cancel context.CancelFunc
	cfg    DatadogConfig
}

func (r *DatadogReporter) send(data []datadog.Metric) error {
	if len(data) < 1 {
		return nil
	}
	if err := r.client.PostMetrics(data); err != nil {
		return errors.Wrap(err, "failed to write metric to datadog")
	}
	r.cfg.Logger.Debug("successfully-sent-batch", lager.Data{
		"size": len(data),
	})
	return nil
}

// reporter sends the metrics to datadog in batches of `size` or every `interval`
// (which ever comes first)
func (r *DatadogReporter) reporter() {
	batch := []datadog.Metric{}
	timeout := time.After(r.cfg.BatchInterval)
	send := func() {
		if err := r.send(batch); err != nil {
			r.cfg.Logger.Error("failed-to-report", err)
			return
		}
		batch = []datadog.Metric{}
		timeout = time.After(r.cfg.BatchInterval)
	}
	for {
		select {
		case m := <-r.queue:
			batch = append(batch, m)
			if len(batch) >= r.cfg.BatchSize {
				r.cfg.Logger.Debug("batch-ready-for-send", lager.Data{
					"condition": "batch-size",
				})
				send()
			}
		case <-timeout:
			r.cfg.Logger.Debug("batch-ready-for-send", lager.Data{
				"condition": "interval",
			})
			send()
		case <-r.ctx.Done():
			r.cfg.Logger.Debug("reporter-closed")
			return
		}
	}
}

// WriteMetrics implements MetricWriter. Metrics are buffered
// in batches not written immediately to rate limit api calls
func (r *DatadogReporter) WriteMetrics(events []Metric) error {
	for _, ev := range events {
		if ev.Kind == Counter {
			r.cfg.Logger.Debug("skipping-metric", lager.Data{
				"reason": "skipping event of Kind=Counter since datadog does not support counter metrics via API",
				"time":   ev.Time.String(),
				"name":   ev.Name,
				"value":  ev.Value,
				"kind":   ev.Kind,
			})
			continue
		}
		maxAge := time.Now().Add(-1 * time.Hour)
		if ev.Time.Before(maxAge) {
			r.cfg.Logger.Debug("skipping-metric", lager.Data{
				"reason": "skipping event as datadog only supports timestamps 1hr in past or 10mins in future",
				"time":   ev.Time.String(),
				"name":   ev.Name,
				"value":  ev.Value,
				"kind":   ev.Kind,
			})
			continue
		}
		m := datadog.Metric{}
		m.SetMetric(ev.Name)
		m.SetType(string(ev.Kind))
		m.Points = []datadog.DataPoint{
			{float64(ev.Time.Unix()), ev.Value},
		}
		m.Tags = append(r.cfg.Tags, ev.Tags...)
		r.cfg.Logger.Info("reporting-metric", lager.Data{
			"time":  ev.Time.String(),
			"name":  ev.Name,
			"value": ev.Value,
			"kind":  ev.Kind,
			"tags":  ev.Tags,
		})
		r.queue <- m
	}
	return nil
}

func (r *DatadogReporter) Close() {
	r.cancel()
}

// Create a new MetricWriter that will send events to DataDog
func NewDatadogReporter(cfg DatadogConfig) MetricWriter {
	ctx, cancel := context.WithCancel(context.Background())
	r := &DatadogReporter{
		queue:  make(chan datadog.Metric, cfg.BatchSize*2),
		ctx:    ctx,
		cancel: cancel,
		client: datadog.NewClient(cfg.ApiKey, cfg.AppKey),
		cfg:    cfg,
	}
	go r.reporter()
	return r
}
