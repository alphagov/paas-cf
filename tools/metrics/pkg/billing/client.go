package billing

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

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

func (c *Client) GetCostsByPlan() ([]CostByPlan, error) {
	lsession := c.logger.Session("get-costs-by-plan")
	lsession.Info("start")

	req, err := http.NewRequest("GET", c.billingAPIEndpoint, nil)
	if err != nil {
		lsession.Error("http-new-request", err)
		return nil, err
	}

	req.Header.Set("Accept", "application/json")
	httpClient := http.DefaultClient

	resp, err := httpClient.Do(req)
	if err != nil {
		lsession.Error("http-do-req", err)
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		err := fmt.Errorf(
			"Returned statuscode from costs endpoint %d", resp.StatusCode,
		)
		lsession.Error("http-not-ok", err, lager.Data{
			"status-code": resp.StatusCode,
		})
		return nil, err
	}

	bodyBuffer, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		lsession.Error("ioutil-readall", err)
		return nil, err
	}

	totalCosts := make([]CostByPlan, 0)
	err = json.Unmarshal(bodyBuffer, &totalCosts)
	if err != nil {
		lsession.Error("json-unmarshal", err)
		return nil, err
	}

	lsession.Info("finish")
	return totalCosts, nil
}
