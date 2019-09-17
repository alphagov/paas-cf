package main

import (
	"code.cloudfoundry.org/lager"
	"encoding/json"
	"fmt"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/logit/logitfakes"
	"github.com/onsi/gomega/gbytes"
	"strings"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Billing API Performance Gauges", func() {
	var elasticsearchSingleResponse = []byte(`{
		"hits": {
			"hits": [{
				"_source": {
					"@timestamp": "2019-01-01T00:00:00.000Z",
					"app": {
						"data": {
							"elapsed": 123456789,
							"filter": {
								"OrgGUIDs": ["some-org-guid"],
								"RangeStart": "1970-01-01",
								"RangeStop": "1970-02-01"
							},
							"deployment": "test"
						}
					}
				}
			}]
		}
	}`)

	logger := lager.NewLogger("billing-performance")
	logger.RegisterSink(lager.NewWriterSink(gbytes.NewBuffer(), lager.INFO))

	It("should have no gauges when no results are found in elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		metrics, err := BillingApiPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(BeEmpty())
	})

	It("should have a billable event rows gauge when there are results from elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "paas-billing.store.get-billable-event-rows-query") {
				return json.Unmarshal(elasticsearchSingleResponse, response)
			}
			return nil
		}
		metrics, err := BillingApiPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(1))
		Expect(metrics[0].Kind).To(Equal(m.Gauge))
		Expect(metrics[0].Name).To(Equal("billing.api.performance.elapsed"))
		Expect(metrics[0].Value).To(Equal(0.123456789))
		Expect(metrics[0].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "test"},
			{Label: "orgGUIDs", Value: "some-org-guid"},
			{Label: "rangeStart", Value: "1970-01-01"},
			{Label: "rangeStop", Value: "1970-02-01"},
			{Label: "message", Value: "paas-billing.store.get-billable-event-rows-query"},
		}))
	})

	It("should have a consolidated billable event rows gauge when there are results from elasticsearch", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "paas-billing.store.get-consolidated-billable-event-rows-query") {
				return json.Unmarshal(elasticsearchSingleResponse, response)
			}
			return nil
		}
		metrics, err := BillingApiPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(1))
		Expect(metrics[0].Kind).To(Equal(m.Gauge))
		Expect(metrics[0].Name).To(Equal("billing.api.performance.elapsed"))
		Expect(metrics[0].Value).To(Equal(0.123456789))
		Expect(metrics[0].Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "test"},
			{Label: "orgGUIDs", Value: "some-org-guid"},
			{Label: "rangeStart", Value: "1970-01-01"},
			{Label: "rangeStop", Value: "1970-02-01"},
			{Label: "message", Value: "paas-billing.store.get-consolidated-billable-event-rows-query"},
		}))
	})

	It("should calculate the average time elapsed grouped by tags", func() {
		fakeLogitElasticsearchClient := logitfakes.FakeLogitElasticsearchClient{}
		fakeLogitElasticsearchClient.SearchStub = func(query string, response interface{}) error {
			if strings.Contains(query, "paas-billing.store.get-billable-event-rows-query") {
				return json.Unmarshal([]byte(`{
					"hits": {
						"hits": [{
							"_source": {
								"@timestamp": "2019-01-01T00:00:00.000Z",
								"app": {
									"data": {
										"elapsed": 1000000000,
										"filter": {
											"OrgGUIDs": ["org-guid-with-one-result"],
											"RangeStart": "1970-01-01",
											"RangeStop": "1970-02-01"
										},
										"deployment": "some-deployment"
									}
								}
							}
						}, {
							"_source": {
								"@timestamp": "2019-01-01T00:00:00.000Z",
								"app": {
									"data": {
										"elapsed": 2000000000,
										"filter": {
											"OrgGUIDs": ["org-guid-with-two-results"],
											"RangeStart": "1970-01-01",
											"RangeStop": "1970-02-01"
										},
										"deployment": "some-deployment"
									}
								}
							}
						}, {
							"_source": {
								"@timestamp": "2019-01-01T00:00:00.000Z",
								"app": {
									"data": {
										"elapsed": 4000000000,
										"filter": {
											"OrgGUIDs": ["org-guid-with-two-results"],
											"RangeStart": "1970-01-01",
											"RangeStop": "1970-02-01"
										},
										"deployment": "some-deployment"
									}
								}
							}
						}]
					}
				}`), response)
			}
			return nil
		}
		metrics, err := BillingApiPerformanceMetricGauges(logger, &fakeLogitElasticsearchClient)
		Expect(err).NotTo(HaveOccurred())
		Expect(metrics).To(HaveLen(2))

		var orgWithOneResultMetric m.Metric
		var orgWithTwoResultsMetric m.Metric
		for _, metric := range metrics {
			for _, tag := range metric.Tags {
				if tag.Label == "orgGUIDs" {
					if tag.Value == "org-guid-with-one-result" {
						orgWithOneResultMetric = metric
					} else if tag.Value == "org-guid-with-two-results" {
						orgWithTwoResultsMetric = metric
					} else {
						Fail(fmt.Sprintf("Unexpected metric with orgGUID %s", tag.Value))
					}
				}
			}
		}
		Expect(orgWithOneResultMetric).NotTo(Equal(m.Metric{}))
		Expect(orgWithTwoResultsMetric).NotTo(Equal(m.Metric{}))

		Expect(orgWithOneResultMetric.Kind).To(Equal(m.Gauge))
		Expect(orgWithOneResultMetric.Name).To(Equal("billing.api.performance.elapsed"))
		Expect(orgWithOneResultMetric.Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "some-deployment"},
			{Label: "orgGUIDs", Value: "org-guid-with-one-result"},
			{Label: "rangeStart", Value: "1970-01-01"},
			{Label: "rangeStop", Value: "1970-02-01"},
			{Label: "message", Value: "paas-billing.store.get-billable-event-rows-query"},
		}))
		Expect(orgWithOneResultMetric.Value).To(Equal(1.0))

		Expect(orgWithTwoResultsMetric.Kind).To(Equal(m.Gauge))
		Expect(orgWithTwoResultsMetric.Name).To(Equal("billing.api.performance.elapsed"))
		Expect(orgWithTwoResultsMetric.Tags).To(Equal(m.MetricTags{
			{Label: "deployment", Value: "some-deployment"},
			{Label: "orgGUIDs", Value: "org-guid-with-two-results"},
			{Label: "rangeStart", Value: "1970-01-01"},
			{Label: "rangeStop", Value: "1970-02-01"},
			{Label: "message", Value: "paas-billing.store.get-billable-event-rows-query"},
		}))
		Expect(orgWithTwoResultsMetric.Value).To(Equal((2.0 + 4.0) / 2))
	})

})
