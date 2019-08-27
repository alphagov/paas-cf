package main

import (
	"code.cloudfoundry.org/lager"
	"encoding/json"
	"github.com/onsi/gomega/gbytes"
	"strings"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/logit/logitfakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var elasticsearchSingleResponse = []byte(`{
	"hits": {
		"hits": [{
			"_source": {
				"@timestamp": "2019-01-01T00:00:00.000Z",
				"app": { "data": { "elapsed": 123456789, "deployment": "test" } }
			}
		}]
	}
}`)

var _ = Describe("Billing Performance Gauges", func() {
	logger := lager.NewLogger("billing-performance")
	logger.RegisterSink(lager.NewWriterSink(gbytes.NewBuffer(), lager.INFO))

	It("should have no gauges when no results are found in elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		metrics, err := BillingPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(BeEmpty())
	})

	It("should have a billable event components gauge when there are results from elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "create_billable_event_components.sql") {
				return json.Unmarshal(elasticsearchSingleResponse, response)
			}
			return nil
		}
		metrics, err := BillingPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(1))
		Expect(metrics[0].Kind).To(Equal(m.Gauge))
		Expect(metrics[0].Name).To(Equal("billing.performance.elapsed"))
		Expect(metrics[0].Value).To(Equal(0.123456789))
		Expect(metrics[0].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "test"},
			{Label: "sqlFile", Value: "create_billable_event_components.sql"},
			{Label: "message", Value: "paas-billing.store.finish-sql-file"},
		}))
	})

	It("should have a create events gauge when there are results from elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "create_events.sql") {
				return json.Unmarshal(elasticsearchSingleResponse, response)
			}
			return nil
		}
		metrics, err := BillingPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(1))
		Expect(metrics[0].Kind).To(Equal(m.Gauge))
		Expect(metrics[0].Name).To(Equal("billing.performance.elapsed"))
		Expect(metrics[0].Value).To(Equal(0.123456789))
		Expect(metrics[0].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "test"},
			{Label: "sqlFile", Value: "create_events.sql"},
			{Label: "message", Value: "paas-billing.store.finish-sql-file"},
		}))
	})

	It("should have a consolidation gauge when there are results from elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "paas-billing.store.consolidation-insert-query") {
				return json.Unmarshal(elasticsearchSingleResponse, response)
			}
			return nil
		}
		metrics, err := BillingPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(1))
		Expect(metrics[0].Kind).To(Equal(m.Gauge))
		Expect(metrics[0].Name).To(Equal("billing.performance.elapsed"))
		Expect(metrics[0].Value).To(Equal(0.123456789))
		Expect(metrics[0].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "test"},
			{Label: "sqlFile", Value: ""},
			{Label: "message", Value: "paas-billing.store.consolidation-insert-query"},
		}))
	})

	It("should calculate the average time elapsed grouped by deployment", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "paas-billing.store.consolidation-insert-query") {
				return json.Unmarshal([]byte(`{
					"hits": {
						"hits": [{
							"_source": {
								"@timestamp": "2019-01-01T00:00:00.000Z",
								"app": { "data": { "elapsed": 100000000, "deployment": "dep-1" } }
							}
						}, {
							"_source": {
								"@timestamp": "2019-01-01T00:00:00.000Z",
								"app": { "data": { "elapsed": 300000000, "deployment": "dep-1" } }
							}
						}, {
							"_source": {
								"@timestamp": "2019-01-01T00:00:00.000Z",
								"app": { "data": { "elapsed": 400000000, "deployment": "dep-2" } }
							}
						}]
					}
				}`), response)
			}
			return nil
		}
		metrics, err := BillingPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(2))
		dep1Index := 0
		dep2Index := 1
		if metrics[dep1Index].Tags[0].Value != "dep-1" {
			dep1Index = 1
			dep2Index = 0
		}
		Expect(metrics[dep1Index].Kind).To(Equal(m.Gauge))
		Expect(metrics[dep1Index].Name).To(Equal("billing.performance.elapsed"))
		Expect(metrics[dep1Index].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "dep-1"},
			{Label: "sqlFile", Value: ""},
			{Label: "message", Value: "paas-billing.store.consolidation-insert-query"},
		}))
		Expect(metrics[dep1Index].Value).To(Equal(0.2))
		Expect(metrics[dep2Index].Kind).To(Equal(m.Gauge))
		Expect(metrics[dep2Index].Name).To(Equal("billing.performance.elapsed"))
		Expect(metrics[dep2Index].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "dep-2"},
			{Label: "sqlFile", Value: ""},
			{Label: "message", Value: "paas-billing.store.consolidation-insert-query"},
		}))
		Expect(metrics[dep2Index].Value).To(Equal(0.4))
	})
})

var _ = Describe("Building elasticsearch queries", func () {
	It("should build a query with a sql file criterion", func () {
		query, err := BuildQuery(BillingElasticsearchQueryParams{
			SqlFile:       "some_sql_file",
			Message:       "some_message",
			QueryInterval: "100y",
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(query).To(ContainSubstring(`"_source":["app.data.elapsed","app.data.deployment","@timestamp"]`))
		Expect(query).To(ContainSubstring(`{"match_phrase":{"@message":"some_message"}}`))
		Expect(query).To(ContainSubstring(`{"match_phrase":{"app.data.sqlFile":"some_sql_file"}}`))
		Expect(query).To(ContainSubstring(`"gt":"now-100y"`))
	})

	It("should build a query without a sql file criterion", func () {
		query, err := BuildQuery(BillingElasticsearchQueryParams{
			SqlFile:       "",
			Message:       "some_message",
			QueryInterval: "100y",
		})
		Expect(err).NotTo(HaveOccurred())
		Expect(query).NotTo(ContainSubstring(`{"match_phrase":{"app.data.sqlFile"`))

		Expect(query).To(ContainSubstring(`{"match_phrase":{"@message":"some_message"}}`))
		Expect(query).To(ContainSubstring(`"_source":["app.data.elapsed","app.data.deployment","@timestamp"]`))
		Expect(query).To(ContainSubstring(`"gt":"now-100y"`))
	})
})

var _ = Describe("Calculating the arithmetic mean", func () {
	It("should not work if given the empty list", func () {
		_, ok := ArithmeticMean([]int64{})
		Expect(ok).To(BeFalse())
	})

	It("should return the average of multiple items", func () {
		avg, ok := ArithmeticMean([]int64{1,2,4,8})
		Expect(ok).To(BeTrue())
		Expect(avg).To(BeNumerically("~", (1+2+4+8)/4.0, 0.00001))
	})
})
