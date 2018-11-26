package main

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	multierror "github.com/hashicorp/go-multierror"
)

const (
	Gauge   eventKind = "gauge"
	Counter eventKind = "counter"
)

var (
	EOS = errors.New("End Of Stream")
)

type eventKind string

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

type Metric struct {
	ID    string
	Kind  eventKind
	Name  string
	Time  time.Time
	Value float64
	Tags  []string
}

func (m Metric) String() string {
	return fmt.Sprintf(
		"[%s] id=%s %s:%s=%.04f (%s)",
		m.Time.Format("2006-01-02T15:04:05-0700"),
		m.ID,
		m.Kind,
		m.Name,
		m.Value,
		strings.Join(m.Tags, ","),
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
					buf.events <- event{err: err}
				}
			}
			time.Sleep(interval)
		}
	}()
	return buf
}

type event struct {
	metric Metric
	err    error
}

type MetricBuffer struct {
	events chan event
	ctx    context.Context
	cancel context.CancelFunc
}

func (eq *MetricBuffer) WriteMetrics(ms []Metric) error {
	for _, m := range ms {
		eq.events <- event{metric: m}
	}
	return nil
}

func (eq *MetricBuffer) ReadMetric() (Metric, error) {
	ev, ok := <-eq.events
	if !ok {
		return Metric{}, EOS
	}
	return ev.metric, ev.err
}

func (eq *MetricBuffer) Close() {
	eq.cancel()
}

func NewMetricBuffer(n int) *MetricBuffer {
	events := make(chan event, n)
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
					buf.events <- event{err: err}
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
