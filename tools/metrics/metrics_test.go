package main

import (
	"fmt"
	"reflect"
	"testing"
	"time"

	"github.com/pkg/errors"
)

func TestMetricBufferIsMetricWriter(t *testing.T) {
	var i interface{} = NewMetricBuffer(1)
	if _, ok := i.(MetricWriter); !ok {
		t.Fatalf("should be a MetricWriter")
	}
}

func TestMetricBufferIsMetricReader(t *testing.T) {
	var i interface{} = NewMetricBuffer(1)
	if _, ok := i.(MetricReader); !ok {
		t.Fatalf("should be a MetricReader")
	}
}

func TestMetricBufferIsMetricCloser(t *testing.T) {
	var i interface{} = NewMetricBuffer(1)
	if _, ok := i.(MetricCloser); !ok {
		t.Fatalf("should be a MetricCloser")
	}
}

func TestMetricBuffer(t *testing.T) {
	metrics := []Metric{
		{
			Name:  "test.metric.a",
			Kind:  Gauge,
			Value: 1,
		},
		{
			Name:  "test.metric.b",
			Kind:  Gauge,
			Value: 2.5,
		},
	}
	buf := NewMetricBuffer(8)
	t.Run("write slice of metrics to buffer", func(t *testing.T) {
		err := buf.WriteMetrics(metrics)
		if err != nil {
			t.Fatal(err)
		}
	})
	for i := 0; i < len(metrics); i++ {
		t.Run(fmt.Sprintf("Read %dth ('%s') metric from buffer", i, metrics[i].Name), func(t *testing.T) {
			m, err := buf.ReadMetric()
			if err != nil {
				t.Fatal(err)
			}
			if m.Value != metrics[i].Value {
				t.Fatalf("expected metric.Value to be %d got %d", metrics[i].Value, m.Value)
			}
		})
	}
	t.Run("Read should block until closed", func(t *testing.T) {
		go func() {
			time.Sleep(100 * time.Millisecond)
			buf.Close()
		}()
		_, err := buf.ReadMetric()
		if err != EOS {
			t.Fatalf("expected EOS got: %v", err)
		}
	})
}

func TestMetricPoller(t *testing.T) {
	var r MetricReadCloser = NewMetricPoller(100*time.Millisecond, func(w MetricWriter) error {
		return w.WriteMetrics([]Metric{
			{
				Name:  "test.poller",
				Time:  time.Now(),
				Kind:  Gauge,
				Value: 1,
			},
		})

	})
	t.Run("collect 5x intervals worth of data", func(t *testing.T) {
		wait := time.After(100 * 9 * time.Millisecond)
		metrics := []Metric{}
		reading := true
		for reading {
			select {
			case <-wait:
				reading = false
			default:
				m, err := r.ReadMetric()
				if err != nil {
					t.Fatal(err)
				}
				metrics = append(metrics, m)
			}
		}
		if len(metrics) > 11 || len(metrics) < 9 {
			t.Fatal("expected to collect roughly ~10 metrics over ~1 second got %v", len(metrics))
		}
	})
	t.Run("close should end polling", func(t *testing.T) {
		go func() {
			time.Sleep(10 * time.Millisecond)
			r.Close()
		}()
		_, err := r.ReadMetric()
		if err != EOS {
			t.Fatalf("expected EOS got: %v", err)
		}
	})
}

func TestMetricPollerError(t *testing.T) {
	bang := errors.New("BANG!")
	poller := NewMetricPoller(1000*time.Millisecond, func(w MetricWriter) error {
		return bang
	})
	defer poller.Close()
	_, err := poller.ReadMetric()
	if err != bang {
		t.Fatalf("expected poller to return error 'BANG!' got: %v", err)
	}
}

func TestCopyMetrics(t *testing.T) {
	inp := []Metric{
		{Name: "test.a"},
		{Name: "test.b"},
		{Name: "test.c"},
	}
	src := NewMetricBuffer(8)
	go func() {
		if err := src.WriteMetrics(inp); err != nil {
			t.Error(err)
		}
		src.Close()
	}()

	dst := NewMetricBuffer(8)
	go func() {
		if err := CopyMetrics(dst, src); err != nil {
			t.Error(err)
		}
	}()

	out := []Metric{}
	func() {
		for {
			m, err := dst.ReadMetric()
			if err == EOS {
				return
			} else if err != nil {
				t.Fatal(err)
			}
			out = append(out, m)
		}
	}()

	if !reflect.DeepEqual(inp, out) {
		t.Fatalf("expected src == dst, got: %v", out)
	}
}

func TestMultiMetricReader(t *testing.T) {
	buffers := []*MetricBuffer{
		NewMetricBuffer(4),
		NewMetricBuffer(4),
		NewMetricBuffer(4),
	}
	readers := make([]MetricReader, len(buffers))
	for i := 0; i < len(readers); i++ {
		readers[i] = buffers[i]
	}
	multi := NewMultiMetricReader(readers...)

	expectedError := fmt.Errorf("BANG!")
	buffers[0].events <- event{
		metric: Metric{Name: "should not be seen"},
		err:    expectedError,
	}

	for i := 0; i < len(buffers); i++ {
		buffers[i].WriteMetrics([]Metric{
			{Name: fmt.Sprintf("test.multi.buf%d", i)},
		})
	}

	metrics := map[string]bool{}
	errors := []error{}
	for i := 0; i < len(buffers)+1; i++ {
		m, err := multi.ReadMetric()
		if err != nil {
			errors = append(errors, err)
		} else {
			metrics[m.Name] = true
		}
	}

	t.Run("reading", func(t *testing.T) {
		if !reflect.DeepEqual(errors, []error{expectedError}) {
			t.Fatalf("expected error(s) %q got: %q", expectedError, errors)
		}

		if len(metrics) != len(buffers) {
			t.Fatalf("expected to read %d metrics out from the MultiReader got: %v", len(buffers), len(metrics))
		}

		for i := 0; i < len(buffers); i++ {
			name := fmt.Sprintf("test.multi.buf%d", i)
			t.Run(name, func(t *testing.T) {
				if !metrics[name] {
					t.Fatalf("%s metric not read from MultiReader", name)
				}
			})
		}
	})

	t.Run("closing", func(t *testing.T) {
		multi.Close()
		if _, err := multi.ReadMetric(); err != EOS {
			t.Fatal("expected MultReader to be closed")
		}
		for i := 0; i < len(buffers); i++ {
			if _, err := buffers[i].ReadMetric(); err != EOS {
				t.Fatalf("expected buffer%d to be closed", i)
			}
		}
	})
}
