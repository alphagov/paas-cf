package cfclient

import (
	"encoding/json"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type ServiceInstancesResponse struct {
	Count     int                       `json:"total_results"`
	Pages     int                       `json:"total_pages"`
	NextUrl   string                    `json:"next_url"`
	Resources []ServiceInstanceResource `json:"resources"`
}

type ServiceInstanceResource struct {
	Meta   Meta            `json:"metadata"`
	Entity ServiceInstance `json:"entity"`
}

type ServiceInstance struct {
	Name               string                 `json:"name"`
	Credentials        map[string]interface{} `json:"credentials"`
	ServicePlanGuid    string                 `json:"service_plan_guid"`
	SpaceGuid          string                 `json:"space_guid"`
	DashboardUrl       string                 `json:"dashboard_url"`
	Type               string                 `json:"type"`
	LastOperation      LastOperation          `json:"last_operation"`
	Tags               []string               `json:"tags"`
	ServiceGuid        string                 `json:"service_guid"`
	SpaceUrl           string                 `json:"space_url"`
	ServicePlanUrl     string                 `json:"service_plan_url"`
	ServiceBindingsUrl string                 `json:"service_bindings_url"`
	ServiceKeysUrl     string                 `json:"service_keys_url"`
	RoutesUrl          string                 `json:"routes_url"`
	ServiceUrl         string                 `json:"service_url"`
	Guid               string                 `json:"guid"`
	c                  *Client
}

type LastOperation struct {
	Type        string `json:"type"`
	State       string `json:"state"`
	Description string `json:"description"`
	UpdatedAt   string `json:"updated_at"`
	CreatedAt   string `json:"created_at"`
}

func (c *Client) ListServiceInstancesByQuery(query url.Values) ([]ServiceInstance, error) {
	var instances []ServiceInstance

	requestUrl := "/v2/service_instances?" + query.Encode()
	for {
		var sir ServiceInstancesResponse
		r := c.NewRequest("GET", requestUrl)
		resp, err := c.DoRequest(r)
		if err != nil {
			return nil, errors.Wrap(err, "Error requesting service instances")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading service instances request:")
		}

		err = json.Unmarshal(resBody, &sir)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling service instances")
		}
		for _, instance := range sir.Resources {
			instance.Entity.Guid = instance.Meta.Guid
			instance.Entity.c = c
			instances = append(instances, instance.Entity)
		}

		requestUrl = sir.NextUrl
		if requestUrl == "" {
			break
		}
	}
	return instances, nil
}

func (c *Client) ListServiceInstances() ([]ServiceInstance, error) {
	return c.ListServiceInstancesByQuery(nil)
}

func (c *Client) GetServiceInstanceByGuid(guid string) (ServiceInstance, error) {
	var sir ServiceInstanceResource
	req := c.NewRequest("GET", "/v2/service_instances/"+guid)
	res, err := c.DoRequest(req)
	if err != nil {
		return ServiceInstance{}, errors.Wrap(err, "Error requesting service instance")
	}

	data, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return ServiceInstance{}, errors.Wrap(err, "Error reading service instance response")
	}
	err = json.Unmarshal(data, &sir)
	if err != nil {
		return ServiceInstance{}, errors.Wrap(err, "Error JSON parsing service instance response")
	}
	sir.Entity.Guid = sir.Meta.Guid
	sir.Entity.c = c
	return sir.Entity, nil
}

func (c *Client) ServiceInstanceByGuid(guid string) (ServiceInstance, error) {
	return c.GetServiceInstanceByGuid(guid)
}
