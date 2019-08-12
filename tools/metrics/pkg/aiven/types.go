package aiven

import (
	"net/http"
	"net/url"
)

type Client struct {
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
