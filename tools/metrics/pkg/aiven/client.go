package aiven

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
)

func NewClient(project string, token string) (*Client, error) {
	httpClient := http.DefaultClient
	baseurl, err := url.Parse("https://api.aiven.io/v1beta/")
	if err != nil {
		return nil, err
	}

	return &Client{BaseURL: baseurl, Project: project, Token: token, httpClient: httpClient}, nil
}

func (c *Client) GetInvoices() ([]AivenInvoice, error) {
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
