package logit

import (
	"code.cloudfoundry.org/lager"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
)

func NewService(
	logger lager.Logger,
	elasticsearchEndpoint string,
	elasticsearchApiKey string,
) (*Client, error) {
	if elasticsearchEndpoint == "" {
		return nil, fmt.Errorf("elasticsearch endpoint was empty")
	}
	if elasticsearchApiKey == "" {
		return nil, fmt.Errorf("elasticsearch api key was empty")
	}
	_ = logger.Session("logit-client")
	endpoint, err := url.Parse(elasticsearchEndpoint)
	if err != nil {
		logger.Error("parse-elasticsearch-url", err)
		return nil, err
	}
	endpoint.Path = "/_search"
	query := endpoint.Query()
	query.Set("apikey", elasticsearchApiKey)
	endpoint.RawQuery = query.Encode()
	return &Client{
		logger:           logger,
		elasticsearchUrl: endpoint,
	}, nil
}

func (c *Client) Search(elasticsearchQuery string, result interface{}) error {
	x := strings.NewReader(elasticsearchQuery)
	request, err := http.NewRequest("GET", c.elasticsearchUrl.String(), x)
	if err != nil {
		c.logger.Error("build-elasticsearch-request", err)
		return err
	}
	request.Header["Content-Type"] = []string{"application/json;charset=UTF-8"}
	request.Header["Accept"] = []string{"application/json"}
	request.Header["Accept-Encoding"] = []string{"UTF-8"}
	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		c.logger.Error("send-elasticsearch-request", err)
		return err
	}
	defer response.Body.Close()
	if !(response.StatusCode >= 200 && response.StatusCode < 300) {
		err := fmt.Errorf("status code was %d", response.StatusCode)
		body, _ := ioutil.ReadAll(response.Body)
		c.logger.Info("non-success-elasticsearch-response", lager.Data{"body": body})
		c.logger.Error("non-success-elasticsearch-status", err)
		return err
	}
	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		c.logger.Error("read-elasticsearch-response", err)
		return err
	}
	err = json.Unmarshal(body, &result)
	if err != nil {
		c.logger.Info("parse-elasticsearch-response", lager.Data{"body": string(body)})
		c.logger.Error("parse-elasticsearch-response-err", err)
		return err
	}
	return nil
}
