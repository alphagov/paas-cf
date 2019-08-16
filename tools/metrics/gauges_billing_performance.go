package main

import (
	"code.cloudfoundry.org/lager"
	"encoding/json"
	"fmt"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/logit"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

func BillingPerformanceGauge(
	logger lager.Logger,
	interval time.Duration,
	client logit.LogitElasticsearchClient,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		metrics, err := BillingPerformanceMetricGauges(logger, client)
		if err != nil {
			logger.Error("billing-performance-metric-gauges", err)
			return err
		}
		err = w.WriteMetrics(metrics)
		if err != nil {
			logger.Error("billing-performance-gauge-write-metrics", err)
			return err
		}
		return nil
	})
}

type BillingElasticsearchQueryParams struct {
	Message       string
	SqlFile       string
	QueryInterval string
}

func BillingPerformanceMetricGauges(logger lager.Logger, client logit.LogitElasticsearchClient) ([]m.Metric, error) {
	queries := []BillingElasticsearchQueryParams{
		{
			Message:       "paas-billing.store.finish-sql-file",
			SqlFile:       "create_billable_event_components.sql",
			QueryInterval: "1h",
		},
		{
			Message:       "paas-billing.store.finish-sql-file",
			SqlFile:       "create_events.sql",
			QueryInterval: "1h",
		},
		{
			Message:       "paas-billing.store.consolidation-insert-query",
			SqlFile:       "",
			QueryInterval: "31d",
		},
	}
	var metrics []m.Metric
	for _, query := range queries {
		hitsByDeployment, err := GetElapsedTimesByDeployment(logger, client, query)
		if err != nil {
			return metrics, err
		}
		for deployment, hits := range hitsByDeployment {
			if average, ok := ArithmeticMean(hits); ok {
				metrics = append(metrics, m.Metric{
					Kind: m.Gauge,
					Name: "billing.performance.elapsed",
					Time: time.Now(),
					Tags: []m.MetricTag{
						{Label: "deployment", Value: deployment},
						{Label: "sqlFile", Value: query.SqlFile},
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

func GetElapsedTimesByDeployment(
	logger lager.Logger,
	client logit.LogitElasticsearchClient,
	queryParams BillingElasticsearchQueryParams,
) (map[string][]int64, error) {
	query, err := BuildQuery(queryParams)
	if err != nil {
		return nil, err
	}

	var response struct {
		Hits struct {
			Hits []struct {
				Source struct {
					Timestamp string `json:"@timestamp"`
					App       struct {
						Data struct {
							Elapsed    int64  `json:"elapsed"`
							Deployment string `json:"deployment"`
						} `json:"data"`
					} `json:"app"`
				} `json:"_source"`
			} `json:"hits"`
		} `json:"hits"`
	}
	err = client.Search(query, &response)
	if err != nil {
		logger.Error("get-sql-file-elapsed-times", err, lager.Data{
			"message": queryParams.Message,
			"sqlFile": queryParams.SqlFile,
		})
		return nil, err
	}

	result := map[string][]int64{}
	for _, hit := range response.Hits.Hits {
		deployment := hit.Source.App.Data.Deployment
		elapsed := hit.Source.App.Data.Elapsed
		result[deployment] = append(result[deployment], elapsed)
	}
	return result, nil
}

func BuildQuery(queryParams BillingElasticsearchQueryParams) (string, error) {
	type M map[string]interface{}
	criteria := []interface{}{M{"match_phrase": M{"@message": queryParams.Message}}}
	if queryParams.SqlFile != "" {
		criteria = append(criteria, M{"match_phrase": M{"app.data.sqlFile": queryParams.SqlFile}})
	}
	criteria = append(criteria, M{"range": M{
		"@timestamp": M{"time_zone": "UTC", "gt": fmt.Sprintf("now-%s", queryParams.QueryInterval)},
	}})

	bytes, err := json.Marshal(M{
		"query":   M{"bool": M{"must": criteria}},
		"from":    0,
		"size":    1000,
		"_source": []string{"app.data.elapsed", "app.data.deployment", "@timestamp"},
	})
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func ArithmeticMean(data []int64) (float64, bool) {
	count := len(data)
	if count <= 0 {
		return 0, false
	}
	sum := int64(0)
	for _, hit := range data {
		sum += hit
	}
	return float64(sum) / float64(count), true
}
