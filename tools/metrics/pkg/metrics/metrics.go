package metrics

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	multierror "github.com/hashicorp/go-multierror"
)

const (
	Gauge   EventKind = "gauge"
	Counter EventKind = "counter"
)

var (
	EOS = errors.New("End Of Stream")
)

type EventKind string

type MetricWriter interface {
	WriteMetrics([]Metric) error
}
type MetricReader interface {
	ReadMetric() (Metric, error)
}

type MetricCloser interface {
	Close()
}

type MetricReadCloser interface {
	MetricReader
	MetricCloser
}

type MetricTags []MetricTag
type MetricTag struct {
	Label string
	Value string
}

func (t MetricTag) String() string {
	return fmt.Sprintf("%s:%s", t.Label, t.Value)
}

func (ts MetricTags) String() string {
	var strs []string
	for _, t := range ts {
		strs = append(strs, t.String())
	}

	return strings.Join(strs, ",")
}

type Metric struct {
	ID    string
	Kind  EventKind
	Name  string
	Time  time.Time
	Value float64
	Tags  MetricTags
	Unit  string
}

func (m Metric) String() string {
	return fmt.Sprintf(
		"[%s] id=%s %s:%s=%.04f %s (%s)",
		m.Time.Format("2006-01-02T15:04:05-0700"),
		m.ID,
		m.Kind,
		m.Name,
		m.Value,
		m.Unit,
		m.Tags.String(),
	)
}

type PollFunc func(MetricWriter) error

func NewMetricPoller(interval time.Duration, fn PollFunc) MetricReadCloser {
	buf := NewMetricBuffer(8) // 8 = buffer size ... arbitarily chosen
	go func() {
		for {
			select {
			case <-buf.ctx.Done():
				return
			default:
				err := fn(buf)
				if err != nil {
					buf.Events <- Event{Err: err}
				}
			}
			time.Sleep(interval)
		}
	}()
	return buf
}

type Event struct {
	Metric Metric
	Err    error
}

type MetricBuffer struct {
	Events chan Event
	ctx    context.Context
	cancel context.CancelFunc
}

func (eq *MetricBuffer) WriteMetrics(ms []Metric) error {
	for _, m := range ms {
		eq.Events <- Event{Metric: m}
	}
	return nil
}

func (eq *MetricBuffer) ReadMetric() (Metric, error) {
	ev, ok := <-eq.Events
	if !ok {
		return Metric{}, EOS
	}
	return ev.Metric, ev.Err
}

func (eq *MetricBuffer) Close() {
	eq.cancel()
}

func NewMetricBuffer(n int) *MetricBuffer {
	events := make(chan Event, n)
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		<-ctx.Done()
		close(events)
	}()
	return &MetricBuffer{events, ctx, cancel}
}

func NewMultiMetricReader(rs ...MetricReader) MetricReadCloser {
	buf := NewMetricBuffer(len(rs))
	go func() {
		<-buf.ctx.Done()
		for _, r := range rs {
			switch rr := r.(type) {
			case MetricCloser:
				rr.Close()
			}
		}
	}()
	for _, r := range rs {
		go func(r MetricReader) {
			for {
				if err := CopyMetrics(buf, r); err != nil {
					buf.Events <- Event{Err: err}
				}
			}
		}(r)
	}
	return buf
}

func CopyMetrics(dst MetricWriter, src MetricReader) error {
	for {
		ev, err := src.ReadMetric()
		if err == EOS {
			if dstc, ok := dst.(MetricCloser); ok {
				dstc.Close()
			}
			return nil
		} else if err != nil {
			return err
		}
		if err := dst.WriteMetrics([]Metric{ev}); err != nil {
			return err
		}
	}
}

// MultiMetricWriter is a writer which forwards the received events to multiple writers
type MultiMetricWriter struct {
	writers []MetricWriter
}

// NewMultiMetricWriter creates a new MultiMetricWriter instance
func NewMultiMetricWriter(writers ...MetricWriter) *MultiMetricWriter {
	return &MultiMetricWriter{
		writers: writers,
	}
}

// AddWriter registers a new writer
func (m *MultiMetricWriter) AddWriter(writer MetricWriter) {
	m.writers = append(m.writers, writer)
}

// WriteMetrics forwards the received events to the registered writers
func (m *MultiMetricWriter) WriteMetrics(metrics []Metric) error {
	var errs error
	for _, writer := range m.writers {
		err := writer.WriteMetrics(metrics)
		if err != nil {
			errs = multierror.Append(errs, err)
		}
	}

	return errs
}
