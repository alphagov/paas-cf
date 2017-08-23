package cfclient

import (
	"encoding/json"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type ServicePlansResponse struct {
	Count     int                   `json:"total_results"`
	Pages     int                   `json:"total_pages"`
	Resources []ServicePlanResource `json:"resources"`
}

type ServicePlanResource struct {
	Meta   Meta        `json:"metadata"`
	Entity ServicePlan `json:"entity"`
}

type ServicePlan struct {
	Name                string      `json:"name"`
	Guid                string      `json:"guid"`
	Free                bool        `json:"free"`
	Description         string      `json:"description"`
	ServiceGuid         string      `json:"service_guid"`
	Extra               interface{} `json:"extra"`
	UniqueId            string      `json:"unique_id"`
	Public              bool        `json:"public"`
	Active              bool        `json:"active"`
	Bindable            bool        `json:"bindable"`
	ServiceUrl          string      `json:"service_url"`
	ServiceInstancesUrl string      `json:"service_instances_url"`
	c                   *Client
}

func (c *Client) ListServicePlansByQuery(query url.Values) ([]ServicePlan, error) {
	var servicePlans []ServicePlan
	var servicePlansResp ServicePlansResponse
	r := c.NewRequest("GET", "/v2/service_plans?"+query.Encode())
	resp, err := c.DoRequest(r)
	if err != nil {
		return nil, errors.Wrap(err, "Error requesting service plans")
	}
	resBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, errors.Wrap(err, "Error reading service plans request:")
	}

	err = json.Unmarshal(resBody, &servicePlansResp)
	if err != nil {
		return nil, errors.Wrap(err, "Error unmarshaling service plans")
	}
	for _, servicePlan := range servicePlansResp.Resources {
		servicePlan.Entity.Guid = servicePlan.Meta.Guid
		servicePlan.Entity.c = c
		servicePlans = append(servicePlans, servicePlan.Entity)
	}
	return servicePlans, nil
}

func (c *Client) ListServicePlans() ([]ServicePlan, error) {
	return c.ListServicePlansByQuery(nil)
}
