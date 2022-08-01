package metrics_test

import (
	"fmt"
	"time"

	"github.com/pkg/errors"

	. "github.com/onsi/gomega"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("Casting", func() {
	It("a MetricBuffer should be a MetricWriter", func() {
		var i interface{} = m.NewMetricBuffer(1)
		_, ok := i.(m.MetricWriter)
		Expect(ok).To(Equal(true))
	})

	It("a MetricBuffer should be a MetricReader", func() {
		var i interface{} = m.NewMetricBuffer(1)
		_, ok := i.(m.MetricReader)
		Expect(ok).To(Equal(true))
	})

	It("a MetricBuffer should be a MetricCloser", func() {
		var i interface{} = m.NewMetricBuffer(1)
		_, ok := i.(m.MetricCloser)
		Expect(ok).To(Equal(true))
	})
})

var _ = Describe("MetricBuffer", func() {
	It("should support writing some metrics then reading them", func() {
		metrics := []m.Metric{
			{
				Name:  "test.metric.a",
				Kind:  m.Gauge,
				Value: 1,
			},
			{
				Name:  "test.metric.b",
				Kind:  m.Gauge,
				Value: 2.5,
			},
		}

		buf := m.NewMetricBuffer(8)

		err := buf.WriteMetrics(metrics)
		Expect(err).NotTo(HaveOccurred())

		for i := 0; i < len(metrics); i++ {
			m, err := buf.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(m.Value).To(Equal(metrics[i].Value))
		}

		go func() {
			time.Sleep(100 * time.Millisecond)
			buf.Close()
		}()

		_, err = buf.ReadMetric()
		Expect(err).To(MatchError(m.EOS), "Expected EOS")
	})
})

var _ = Describe("MetricPoller", func() {
	It("should collect data then stop when closed", func() {
		var r m.MetricReadCloser = m.NewMetricPoller(
			100*time.Millisecond,
			func(w m.MetricWriter) error {
				return w.WriteMetrics([]m.Metric{
					{
						Name:  "test.poller",
						Time:  time.Now(),
						Kind:  m.Gauge,
						Value: 1,
					},
				})
			})

		wait := time.After(100 * 9 * time.Millisecond)
		metrics := []m.Metric{}
		reading := true

		for reading {
			select {
			case <-wait:
				reading = false
			default:
				m, err := r.ReadMetric()

				Expect(err).NotTo(HaveOccurred())

				metrics = append(metrics, m)
			}
		}

		Expect(len(metrics)).To(
			BeNumerically("==", 10, 1),
			"Expected to collect roughly 10 metrics over 1 second",
		)

		go func() {
			time.Sleep(10 * time.Millisecond)
			r.Close()
		}()

		_, err := r.ReadMetric()
		Expect(err).To(MatchError(m.EOS), "Expected EOS")
	})

	It("should propagate errors", func() {
		bang := errors.New("BANG!")

		poller := m.NewMetricPoller(
			1000*time.Millisecond,
			func(w m.MetricWriter) error {
				return bang
			},
		)

		defer poller.Close()

		_, err := poller.ReadMetric()
		Expect(err).To(MatchError(bang))
	})
})

var _ = Describe("CopyMetrics", func() {
	It("should copy metrics correctly", func() {
		inp := []m.Metric{
			{Name: "test.a"},
			{Name: "test.b"},
			{Name: "test.c"},
		}

		src := m.NewMetricBuffer(8)

		go func() {
			err := src.WriteMetrics(inp)
			Expect(err).NotTo(HaveOccurred())
			src.Close()
		}()

		dst := m.NewMetricBuffer(8)

		go func() {
			err := m.CopyMetrics(dst, src)
			Expect(err).NotTo(HaveOccurred())
		}()

		out := []m.Metric{}

		func() {
			for {
				metric, err := dst.ReadMetric()

				if err == m.EOS {
					return
				}

				Expect(err).NotTo(HaveOccurred())

				out = append(out, metric)
			}
		}()

		Expect(inp).To(Equal(out))
	})
})

var _ = Describe("MultiMetricReader", func() {
	It("should read multiple metrics correctly", func() {
		buffers := []*m.MetricBuffer{
			m.NewMetricBuffer(4),
			m.NewMetricBuffer(4),
			m.NewMetricBuffer(4),
		}

		readers := make([]m.MetricReader, len(buffers))
		for i := 0; i < len(readers); i++ {
			readers[i] = buffers[i]
		}

		multi := m.NewMultiMetricReader(readers...)

		expectedError := fmt.Errorf("BANG!")
		buffers[0].Events <- m.Event{
			Metric: m.Metric{Name: "should not be seen"},
			Err:    expectedError,
		}

		for i := 0; i < len(buffers); i++ {
			buffers[i].WriteMetrics([]m.Metric{
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

		Expect(errors).To(Equal([]error{expectedError}))
		Expect(len(metrics)).To(Equal(len(buffers)))

		for i := 0; i < len(buffers); i++ {
			name := fmt.Sprintf("test.multi.buf%d", i)
			Expect(metrics).To(HaveKey(name))
		}

		multi.Close()
		_, err := multi.ReadMetric()
		Expect(err).To(
			MatchError(m.EOS),
			"Expected EOS in read stream after closing",
		)

		for i := 0; i < len(buffers); i++ {
			_, err := buffers[i].ReadMetric()
			Expect(err).To(
				MatchError(m.EOS),
				"Expected EOS in buffer stream after closing",
			)
		}

	})
})
