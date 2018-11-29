package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

type AivenClient struct {
	BaseURL    *url.URL
	Project    string
	Token      string
	httpClient *http.Client
}

type AivenInvoice struct {
	Currency       string `json:"currency"`
	Invoice_number string `json:"invoice_number"`
	State          string `json:"state"`
	Cost           string `json:"total_vat_zero"`
}

type AivenInvoiceResponse struct {
	Invoices []AivenInvoice `json:"invoices"`
}

func NewAivenClient(project string, token string) (*AivenClient, error) {
	httpClient := http.DefaultClient
	baseurl, err := url.Parse("https://api.aiven.io/v1beta/")
	if err != nil {
		return nil, err
	}

	return &AivenClient{BaseURL: baseurl, Project: project, Token: token, httpClient: httpClient}, nil
}

func (c *AivenClient) GetInvoices() ([]AivenInvoice, error) {
	path := &url.URL{Path: fmt.Sprintf("project/%s/invoice", c.Project)}
	apiurl := c.BaseURL.ResolveReference(path)
	req, err := http.NewRequest("GET", apiurl.String(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("aivenv1 %s", c.Token))

	resp, err := c.httpClient.Do(req)

	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Returned statuscode from aiven %d", resp.StatusCode)
	}
	bodyBuffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var invoiceResponse AivenInvoiceResponse
	err = json.Unmarshal(bodyBuffer, &invoiceResponse)
	if err != nil {
		return nil, err
	}

	return invoiceResponse.Invoices, nil
}

func AivenCostGauge(client *AivenClient, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}
		invoices, err := client.GetInvoices()
		if err != nil {
			return err
		}

		for _, invoice := range invoices {
			if invoice.State == "estimate" {
				currentCost, err := strconv.ParseFloat(invoice.Cost, 64)
				if err != nil {
					return err
				}
				metrics = append(metrics, Metric{
					Kind:  Gauge,
					Time:  time.Now(),
					Name:  "aiven.estimated.cost",
					Value: currentCost,
					Unit:  "pounds",
				})
			}
		}

		return w.WriteMetrics(metrics)
	})
}
