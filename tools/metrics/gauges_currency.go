package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"code.cloudfoundry.org/lager"
)

const ConfiguredUSDExchangeRate = 0.8

type ECBCurrencyRatesResponse struct {
	Rates map[string]float64 `json:"rates"` // Map of symbol (eg GBP) to rate
}

func ecbCurrencyEndpoint(base string, target string) string {
	return fmt.Sprintf(
		"https://api.exchangeratesapi.io/latest?base=%s&symbols=%s",
		base, target,
	)
}

func getCurrencyFromECB(base string, target string) (float64, error) {
	url := ecbCurrencyEndpoint(base, target)
	resp, err := http.Get(url)

	if err != nil {
		return 0, fmt.Errorf(
			"Could not get currency from ECB base=%s target=%s err=%s",
			base, target, err,
		)
	}

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf(
			"Did not receive HTTP 200 OK from ECB base=%s target=%s code=%d",
			base, target, resp.StatusCode,
		)
	}

	responseBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return 0, fmt.Errorf(
			"Could not read response body from ECB base=%s target=%s err=%s",
			base, target, err,
		)
	}

	var parsedResponse ECBCurrencyRatesResponse
	err = json.Unmarshal(responseBody, &parsedResponse)
	if err != nil {
		return 0, fmt.Errorf(
			"Could not unmarshal response from ECB base=%s target=%s err=%s",
			base, target, err,
		)
	}

	rates := parsedResponse.Rates
	rate, ok := rates[target]
	if !ok {
		return 0, fmt.Errorf(
			"Could not find target in rates from ECB base=%s target=%s err=%s",
			base, target, err,
		)
	}

	return rate, nil
}

func ActualUSDExchangeRateGauge() (Metric, error) {
	usdExchangeRate, err := getCurrencyFromECB("USD", "GBP")
	if err != nil {
		return Metric{}, err
	}

	return Metric{
		Kind: Gauge,
		Time: time.Now(),
		Name: "currency.real",
		Tags: MetricTags{
			{Label: "currency", Value: "USD"},
		},
		Unit:  "ratio",
		Value: float64(usdExchangeRate),
	}, nil
}

func ConfiguredUSDExchangeRateGauge() Metric {
	return Metric{
		Kind: Gauge,
		Time: time.Now(),
		Name: "currency.configured",
		Tags: MetricTags{
			{Label: "currency", Value: "USD"},
		},
		Unit:  "ratio",
		Value: float64(ConfiguredUSDExchangeRate),
	}
}

func CurrencyMetricGauges(logger lager.Logger) ([]Metric, error) {
	metrics := make([]Metric, 0)

	metrics = append(metrics, ConfiguredUSDExchangeRateGauge())

	logger.Info("Getting ECB currency information for USD")
	actualUSDExchangeRateGauge, err := ActualUSDExchangeRateGauge()
	if err != nil {
		logger.Error("Error getting ECB currency information for USD", err)
		return metrics, err
	}
	logger.Info("Got ECB currency information for USD")
	metrics = append(metrics, actualUSDExchangeRateGauge)

	return metrics, nil
}

func CurrencyGauges(
	logger lager.Logger, interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics, err := CurrencyMetricGauges(logger)

		if err != nil {
			return err
		}

		return w.WriteMetrics(metrics)
	})
}
