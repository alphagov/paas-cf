package cfclient

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"

	"github.com/pkg/errors"
)

type ServicePlanVisibilitiesResponse struct {
	Count     int                             `json:"total_results"`
	Pages     int                             `json:"total_pages"`
	NextUrl   string                          `json:"next_url"`
	Resources []ServicePlanVisibilityResource `json:"resources"`
}

type ServicePlanVisibilityResource struct {
	Meta   Meta                  `json:"metadata"`
	Entity ServicePlanVisibility `json:"entity"`
}

type ServicePlanVisibility struct {
	Guid             string `json:"guid"`
	ServicePlanGuid  string `json:"service_plan_guid"`
	OrganizationGuid string `json:"organization_guid"`
	ServicePlanUrl   string `json:"service_plan_url"`
	OrganizationUrl  string `json:"organization_url"`
	c                *Client
}

func (c *Client) ListServicePlanVisibilitiesByQuery(query url.Values) ([]ServicePlanVisibility, error) {
	var servicePlanVisibilities []ServicePlanVisibility
	requestUrl := "/v2/service_plan_visibilities?" + query.Encode()
	for {
		var servicePlanVisibilitiesResp ServicePlanVisibilitiesResponse
		r := c.NewRequest("GET", requestUrl)
		resp, err := c.DoRequest(r)
		if err != nil {
			return nil, errors.Wrap(err, "Error requesting service plan visibilities")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading service plan visibilities request:")
		}

		err = json.Unmarshal(resBody, &servicePlanVisibilitiesResp)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling service plan visibilities")
		}
		for _, servicePlanVisibility := range servicePlanVisibilitiesResp.Resources {
			servicePlanVisibility.Entity.Guid = servicePlanVisibility.Meta.Guid
			servicePlanVisibility.Entity.c = c
			servicePlanVisibilities = append(servicePlanVisibilities, servicePlanVisibility.Entity)
		}
		requestUrl = servicePlanVisibilitiesResp.NextUrl
		if requestUrl == "" {
			break
		}
	}
	return servicePlanVisibilities, nil
}

func (c *Client) ListServicePlanVisibilities() ([]ServicePlanVisibility, error) {
	return c.ListServicePlanVisibilitiesByQuery(nil)
}

func (c *Client) CreateServicePlanVisibility(servicePlanGuid string, organizationGuid string) (ServicePlanVisibility, error) {
	req := c.NewRequest("POST", "/v2/service_plan_visibilities")
	req.obj = map[string]interface{}{
		"service_plan_guid": servicePlanGuid,
		"organization_guid": organizationGuid,
	}
	resp, err := c.DoRequest(req)
	if err != nil {
		return ServicePlanVisibility{}, err
	}
	if resp.StatusCode != http.StatusCreated {
		return ServicePlanVisibility{}, errors.Wrapf(err, "Error creating service plan visibility, response code: %d", resp.StatusCode)
	}
	return respBodyToServicePlanVisibility(resp.Body, c)
}

func respBodyToServicePlanVisibility(body io.ReadCloser, c *Client) (ServicePlanVisibility, error) {
	bodyRaw, err := ioutil.ReadAll(body)
	if err != nil {
		return ServicePlanVisibility{}, err
	}
	servicePlanVisibilityRes := ServicePlanVisibilityResource{}
	err = json.Unmarshal([]byte(bodyRaw), &servicePlanVisibilityRes)
	if err != nil {
		return ServicePlanVisibility{}, err
	}
	servicePlanVisibility := servicePlanVisibilityRes.Entity
	servicePlanVisibility.Guid = servicePlanVisibilityRes.Meta.Guid
	servicePlanVisibility.c = c
	return servicePlanVisibility, nil
}
