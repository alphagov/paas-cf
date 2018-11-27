package main

import (
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/prometheus/client_golang/prometheus"
)

type testRegistry struct {
	collectors []prometheus.Collector
}

func (t *testRegistry) Register(collector prometheus.Collector) error {
	t.MustRegister(collector)
	return nil
}

func (t *testRegistry) MustRegister(collectors ...prometheus.Collector) {
	t.collectors = append(t.collectors, collectors...)
}
func (t *testRegistry) Unregister(collector prometheus.Collector) bool {
	return false
}

var _ = Describe("PrometheusReporter", func() {

	var registry *testRegistry
	var reporter *PrometheusReporter
	var events []Metric
	var err error
	var metricsChan chan prometheus.Metric
	var metrics []prometheus.Metric

	BeforeEach(func() {
		registry = &testRegistry{}
		reporter = NewPrometheusReporter(registry)
		metricsChan = make(chan prometheus.Metric, 16)
		metrics = []prometheus.Metric{}

		go func() {
			for metric := range metricsChan {
				metrics = append(metrics, metric)
			}
		}()
	})

	AfterEach(func() {
		close(metricsChan)
	})

	JustBeforeEach(func() {
		err = reporter.WriteMetrics(events)
		for _, collector := range registry.collectors {
			collector.Collect(metricsChan)
		}
	})

	Context("when there are no events", func() {
		It("should return no error", func() {
			Expect(err).ToNot(HaveOccurred())
		})
	})

	Context("when there is a counter event", func() {
		BeforeEach(func() {
			events = []Metric{
				Metric{
					Kind:  Counter,
					Name:  "test.metric",
					Value: 12.34,
					Time:  time.Now(),
					Unit:  "count",
					Tags:  []string{"foo:bar", "bar:baz"},
				},
			}
		})
		It("should process it", func() {
			Expect(err).ToNot(HaveOccurred())
			Eventually(func() int { return len(metrics) }).Should(Equal(1))

			vec := prometheus.NewCounterVec(prometheus.CounterOpts{
				Name:      "test_metric_count",
				Namespace: "paas",
			}, []string{"foo", "bar"})
			expected := vec.With(prometheus.Labels{
				"foo": "bar",
				"bar": "baz",
			})
			expected.Add(12.34)

			Expect(metrics[0]).To(Equal(expected))
		})

	})

	Context("when there is a gauge event", func() {
		BeforeEach(func() {
			events = []Metric{
				Metric{
					Kind:  Gauge,
					Name:  "test.metric",
					Value: 12.34,
					Time:  time.Now(),
					Unit:  "count",
					Tags:  []string{"foo:bar", "bar:baz"},
				},
			}
		})
		It("should process it", func() {
			Expect(err).ToNot(HaveOccurred())
			Eventually(func() int { return len(metrics) }).Should(Equal(1))

			vec := prometheus.NewGaugeVec(prometheus.GaugeOpts{
				Name:      "test_metric_count",
				Namespace: "paas",
			}, []string{"foo", "bar"})
			expected := vec.With(prometheus.Labels{
				"foo": "bar",
				"bar": "baz",
			})
			expected.Set(12.34)

			Expect(metrics[0]).To(Equal(expected))
		})

	})

})
