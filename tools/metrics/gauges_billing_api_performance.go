package main

import (
	"code.cloudfoundry.org/lager"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/logit"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

type BillingApiHitLabels struct {
	Deployment             string
	CommaSeparatedOrgGUIDs string
	RangeStart             string
	RangeStop              string
}
type BillingApiElasticsearchHit struct {
	Source struct {
		Timestamp string `json:"@timestamp"`
		App       struct {
			Data struct {
				Elapsed    int64  `json:"elapsed"`
				Deployment string `json:"deployment"`
				Filter     struct {
					OrgGUIDs   []string `json:"OrgGUIDs"`
					RangeStart string   `json:"RangeStart"`
					RangeStop  string   `json:"RangeStop"`
				} `json:"filter"`
			} `json:"data"`
		} `json:"app"`
	} `json:"_source"`
}

func BillingApiPerformanceGauge(
	logger lager.Logger,
	interval time.Duration,
	client logit.LogitElasticsearchClient,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		metrics, err := BillingApiPerformanceMetricGauges(logger, client)
		if err != nil {
			logger.Error("billing-api-performance-metric-gauges", err)
			return err
		}
		err = w.WriteMetrics(metrics)
		if err != nil {
			logger.Error("billing-api-performance-gauge-write-metrics", err)
			return err
		}
		return nil
	})
}

type BillingApiElasticsearchQueryParams struct {
	Message       string
	QueryInterval string
}

func BillingApiPerformanceMetricGauges(logger lager.Logger, client logit.LogitElasticsearchClient) ([]m.Metric, error) {
	queries := []BillingApiElasticsearchQueryParams{
		{
			Message:       "paas-billing.store.get-consolidated-billable-event-rows-query",
			QueryInterval: "15m",
		},
		{
			Message:       "paas-billing.store.get-billable-event-rows-query",
			QueryInterval: "15m",
		},
	}
	var metrics []m.Metric
	for _, query := range queries {
		hits, err := GetElapsedTimesByTags(logger, client, query)
		if err != nil {
			return metrics, err
		}
		for tags, hits := range hits {
			var elapsedTimes []int64
			for _, hit := range hits {
				elapsedTimes = append(elapsedTimes, hit.Source.App.Data.Elapsed)
			}
			if average, ok := ArithmeticMean(elapsedTimes); ok {
				metrics = append(metrics, m.Metric{
					Kind: m.Gauge,
					Name: "billing.api.performance.elapsed",
					Time: time.Now(),
					Tags: []m.MetricTag{
						{Label: "deployment", Value: tags.Deployment},
						{Label: "orgGUIDs", Value: tags.CommaSeparatedOrgGUIDs},
						{Label: "rangeStart", Value: tags.RangeStart},
						{Label: "rangeStop", Value: tags.RangeStop},
						{Label: "message", Value: query.Message},
					},
					Unit:  "seconds",
					Value: average / 1e9,
				})
			}
		}
	}
	return metrics, nil
}

func GetElapsedTimesByTags(
	logger lager.Logger,
	client logit.LogitElasticsearchClient,
	queryParams BillingApiElasticsearchQueryParams,
) (map[BillingApiHitLabels][]BillingApiElasticsearchHit, error) {
	query, err := BuildBillingApiElasticsearchQuery(queryParams)
	if err != nil {
		return nil, err
	}

	var response struct {
		Hits struct {
			Hits []BillingApiElasticsearchHit `json:"hits"`
		} `json:"hits"`
	}
	err = client.Search(query, &response)
	if err != nil {
		logger.Error("get-billing-api-elapsed-times", err, lager.Data{
			"message": queryParams.Message,
		})
		return nil, err
	}
	result := map[BillingApiHitLabels][]BillingApiElasticsearchHit{}
	for _, hit := range response.Hits.Hits {
		orgGUIDs := hit.Source.App.Data.Filter.OrgGUIDs
		sort.Strings(orgGUIDs)
		commaSeparatedOrgGUIDs := strings.Join(orgGUIDs, ",")
		labels := BillingApiHitLabels{
			Deployment:             hit.Source.App.Data.Deployment,
			CommaSeparatedOrgGUIDs: commaSeparatedOrgGUIDs,
			RangeStart:             hit.Source.App.Data.Filter.RangeStart,
			RangeStop:              hit.Source.App.Data.Filter.RangeStop,
		}
		result[labels] = append(result[labels], hit)
	}
	return result, nil
}

func BuildBillingApiElasticsearchQuery(queryParams BillingApiElasticsearchQueryParams) (string, error) {
	type M map[string]interface{}
	criteria := []interface{}{
		M{"match_phrase": M{"@message": queryParams.Message}},
		M{"range": M{
			"@timestamp": M{"time_zone": "UTC", "gt": fmt.Sprintf("now-%s", queryParams.QueryInterval)},
		}},
	}
	bytes, err := json.Marshal(M{
		"query": M{"bool": M{"must": criteria}},
		"from":  0,
		"size":  1000,
		"_source": []string{
			"app.data.elapsed",
			"app.data.deployment",
			"app.data.filter.OrgGUIDs",
			"app.data.filter.RangeStart",
			"app.data.filter.RangeStop",
			"@timestamp",
		},
	})
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}
