package cfclient

import (
	"encoding/json"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type UserProvidedServiceInstancesResponse struct {
	Count     int                                   `json:"total_results"`
	Pages     int                                   `json:"total_pages"`
	NextUrl   string                                `json:"next_url"`
	Resources []UserProvidedServiceInstanceResource `json:"resources"`
}

type UserProvidedServiceInstanceResource struct {
	Meta   Meta                        `json:"metadata"`
	Entity UserProvidedServiceInstance `json:"entity"`
}

type UserProvidedServiceInstance struct {
	Name               string                 `json:"name"`
	Credentials        map[string]interface{} `json:"credentials"`
	SpaceGuid          string                 `json:"space_guid"`
	Type               string                 `json:"type"`
	Tags               []string               `json:"tags"`
	SpaceUrl           string                 `json:"space_url"`
	ServiceBindingsUrl string                 `json:"service_bindings_url"`
	RoutesUrl          string                 `json:"routes_url"`
	RouteServiceUrl    string                 `json:"route_service_url"`
	SyslogDrainUrl     string                 `json:"syslog_drain_url"`
	Guid               string                 `json:"guid"`
	c                  *Client
}

func (c *Client) ListUserProvidedServiceInstancesByQuery(query url.Values) ([]UserProvidedServiceInstance, error) {
	var instances []UserProvidedServiceInstance

	requestUrl := "/v2/user_provided_service_instances?" + query.Encode()
	for {
		var sir UserProvidedServiceInstancesResponse
		r := c.NewRequest("GET", requestUrl)
		resp, err := c.DoRequest(r)
		if err != nil {
			return nil, errors.Wrap(err, "Error requesting user provided service instances")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading user provided service instances request:")
		}

		err = json.Unmarshal(resBody, &sir)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling user provided service instances")
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

func (c *Client) ListUserProvidedServiceInstances() ([]UserProvidedServiceInstance, error) {
	return c.ListUserProvidedServiceInstancesByQuery(nil)
}

func (c *Client) GetUserProvidedServiceInstanceByGuid(guid string) (UserProvidedServiceInstance, error) {
	var sir UserProvidedServiceInstanceResource
	req := c.NewRequest("GET", "/v2/user_provided_service_instances/"+guid)
	res, err := c.DoRequest(req)
	if err != nil {
		return UserProvidedServiceInstance{}, errors.Wrap(err, "Error requesting user provided service instance")
	}

	data, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return UserProvidedServiceInstance{}, errors.Wrap(err, "Error reading user provided service instance response")
	}
	err = json.Unmarshal(data, &sir)
	if err != nil {
		return UserProvidedServiceInstance{}, errors.Wrap(err, "Error JSON parsing user provided service instance response")
	}
	sir.Entity.Guid = sir.Meta.Guid
	sir.Entity.c = c
	return sir.Entity, nil
}

func (c *Client) UserProvidedServiceInstanceByGuid(guid string) (UserProvidedServiceInstance, error) {
	return c.GetUserProvidedServiceInstanceByGuid(guid)
}
