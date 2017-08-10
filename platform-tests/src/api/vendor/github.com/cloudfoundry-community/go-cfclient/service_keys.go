package cfclient

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type ServiceKeysResponse struct {
	Count     int                  `json:"total_results"`
	Pages     int                  `json:"total_pages"`
	Resources []ServiceKeyResource `json:"resources"`
}

type ServiceKeyResource struct {
	Meta   Meta       `json:"metadata"`
	Entity ServiceKey `json:"entity"`
}

type ServiceKey struct {
	Name                string      `json:"name"`
	Guid                string      `json:"guid"`
	ServiceInstanceGuid string      `json:"service_instance_guid"`
	Credentials         interface{} `json:"credentials"`
	ServiceInstanceUrl  string      `json:"service_instance_url"`
	c                   *Client
}

func (c *Client) ListServiceKeysByQuery(query url.Values) ([]ServiceKey, error) {
	var serviceKeys []ServiceKey
	var serviceKeysResp ServiceKeysResponse
	r := c.NewRequest("GET", "/v2/service_keys?"+query.Encode())
	resp, err := c.DoRequest(r)
	if err != nil {
		return nil, errors.Wrap(err, "Error requesting service keys")
	}
	resBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, errors.Wrap(err, "Error reading service keys request:")
	}

	err = json.Unmarshal(resBody, &serviceKeysResp)
	if err != nil {
		return nil, errors.Wrap(err, "Error unmarshaling service keys")
	}
	for _, serviceKey := range serviceKeysResp.Resources {
		serviceKey.Entity.Guid = serviceKey.Meta.Guid
		serviceKey.Entity.c = c
		serviceKeys = append(serviceKeys, serviceKey.Entity)
	}
	return serviceKeys, nil
}

func (c *Client) ListServiceKeys() ([]ServiceKey, error) {
	return c.ListServiceKeysByQuery(nil)
}

func (c *Client) GetServiceKeyByName(name string) (ServiceKey, error) {
	var serviceKey ServiceKey
	q := url.Values{}
	q.Set("q", "name:"+name)
	serviceKeys, err := c.ListServiceKeysByQuery(q)
	if err != nil {
		return serviceKey, err
	}
	if len(serviceKeys) == 0 {
		return serviceKey, fmt.Errorf("Unable to find service key %s", name)
	}
	return serviceKeys[0], nil
}

func (c *Client) GetServiceKeyByInstanceGuid(guid string) (ServiceKey, error) {
	var serviceKey ServiceKey
	q := url.Values{}
	q.Set("q", "service_instance_guid:"+guid)
	serviceKeys, err := c.ListServiceKeysByQuery(q)
	if err != nil {
		return serviceKey, err
	}
	if len(serviceKeys) == 0 {
		return serviceKey, fmt.Errorf("Unable to find service key for guid %s", guid)
	}
	return serviceKeys[0], nil
}
