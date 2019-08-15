package billing

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"code.cloudfoundry.org/lager"
)

func NewClient(
	endpoint string,
	logger lager.Logger,
) *Client {
	lsession := logger.Session("billing-client")

	return &Client{
		logger:             lsession,
		billingAPIEndpoint: endpoint,
	}
}

func (c *Client) getJSON(url string, target interface{}) error {
	lsession := c.logger.Session("get-json")
	lsession.Info("start")

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		lsession.Error("http-new-request", err)
		return err
	}

	req.Header.Set("Accept", "application/json")
	httpClient := http.DefaultClient

	resp, err := httpClient.Do(req)
	if err != nil {
		lsession.Error("http-do-req", err, lager.Data{"url": url})
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		err := fmt.Errorf(
			"Billing client received statuscode %d", resp.StatusCode,
		)
		lsession.Error("http-not-ok", err, lager.Data{
			"status-code": resp.StatusCode,
			"url":         url,
		})
		return err
	}

	bodyBuffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		lsession.Error("ioutil-readall", err)
		return err
	}

	err = json.Unmarshal(bodyBuffer, target)
	if err != nil {
		lsession.Error("json-unmarshal", err)
		return err
	}

	lsession.Info("finish")
	return nil
}

func (c *Client) GetCostsByPlan() ([]CostByPlan, error) {
	lsession := c.logger.Session("get-costs-by-plan")
	lsession.Info("start")

	url := fmt.Sprintf("%s/totals", c.billingAPIEndpoint)

	totalCosts := make([]CostByPlan, 0)
	err := c.getJSON(url, &totalCosts)
	if err != nil {
		lsession.Error("get-json", err)
		return nil, err
	}

	lsession.Info("finish")
	return totalCosts, nil
}

func (c *Client) GetPlans() ([]Plan, error) {
	lsession := c.logger.Session("get-plan-guids")
	lsession.Info("start")

	rangeStart := "2015-12-23"
	rangeStop := time.Now().Format("2006-01-02")
	url := fmt.Sprintf(
		"%s/pricing_plans?range_start=%s&range_stop=%s",
		c.billingAPIEndpoint, rangeStart, rangeStop,
	)

	plans := make([]Plan, 0)
	err := c.getJSON(url, &plans)
	if err != nil {
		lsession.Error("get-json", err)
		return nil, err
	}

	lsession.Info("finish")
	return plans, nil
}
