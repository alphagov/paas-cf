package cfclient

import (
	"encoding/json"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type ServiceBindingsResponse struct {
	Count     int                      `json:"total_results"`
	Pages     int                      `json:"total_pages"`
	Resources []ServiceBindingResource `json:"resources"`
	NextUrl   string                   `json:"next_url"`
}

type ServiceBindingResource struct {
	Meta   Meta           `json:"metadata"`
	Entity ServiceBinding `json:"entity"`
}

type ServiceBinding struct {
	Guid                string      `json:"guid"`
	AppGuid             string      `json:"app_guid"`
	ServiceInstanceGuid string      `json:"service_instance_guid"`
	Credentials         interface{} `json:"credentials"`
	BindingOptions      interface{} `json:"binding_options"`
	GatewayData         interface{} `json:"gateway_data"`
	GatewayName         string      `json:"gateway_name"`
	SyslogDrainUrl      string      `json:"syslog_drain_url"`
	VolumeMounts        interface{} `json:"volume_mounts"`
	AppUrl              string      `json:"app_url"`
	ServiceInstanceUrl  string      `json:"service_instance_url"`
	c                   *Client
}

func (c *Client) ListServiceBindingsByQuery(query url.Values) ([]ServiceBinding, error) {
	var serviceBindings []ServiceBinding
	var serviceBindingsResp ServiceBindingsResponse
	pages := 0

	requestUrl := "/v2/service_bindings?" + query.Encode()
	for {
		r := c.NewRequest("GET", requestUrl)
		resp, err := c.DoRequest(r)
		if err != nil {
			return nil, errors.Wrap(err, "Error requesting service bindings")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading service bindings request:")
		}

		err = json.Unmarshal(resBody, &serviceBindingsResp)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling service bindings")
		}
		for _, serviceBinding := range serviceBindingsResp.Resources {
			serviceBinding.Entity.Guid = serviceBinding.Meta.Guid
			serviceBinding.Entity.c = c
			serviceBindings = append(serviceBindings, serviceBinding.Entity)
		}
		requestUrl = serviceBindingsResp.NextUrl
		if requestUrl == "" {
			break
		}
		pages += 1
		totalPages := serviceBindingsResp.Pages
		if totalPages > 0 && pages >= totalPages {
			break
		}
	}
	return serviceBindings, nil
}

func (c *Client) ListServiceBindings() ([]ServiceBinding, error) {
	return c.ListServiceBindingsByQuery(nil)
}

func (c *Client) GetServiceBindingByGuid(guid string) (ServiceBinding, error) {
	var serviceBinding ServiceBindingResource
	r := c.NewRequest("GET", "/v2/service_bindings/"+url.QueryEscape(guid))
	resp, err := c.DoRequest(r)
	if err != nil {
		return ServiceBinding{}, errors.Wrap(err, "Error requesting serving binding")
	}
	defer resp.Body.Close()
	resBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return ServiceBinding{}, errors.Wrap(err, "Error reading service binding response body")
	}
	err = json.Unmarshal(resBody, &serviceBinding)
	if err != nil {
		return ServiceBinding{}, errors.Wrap(err, "Error unmarshalling service binding")
	}
	serviceBinding.Entity.Guid = serviceBinding.Meta.Guid
	serviceBinding.Entity.c = c
	return serviceBinding.Entity, nil
}

func (c *Client) ServiceBindingByGuid(guid string) (ServiceBinding, error) {
	return c.GetServiceBindingByGuid(guid)
}
