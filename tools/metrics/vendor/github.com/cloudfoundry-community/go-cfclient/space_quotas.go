package cfclient

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type SpaceQuotasResponse struct {
	Count     int                   `json:"total_results"`
	Pages     int                   `json:"total_pages"`
	NextUrl   string                `json:"next_url"`
	Resources []SpaceQuotasResource `json:"resources"`
}

type SpaceQuotasResource struct {
	Meta   Meta       `json:"metadata"`
	Entity SpaceQuota `json:"entity"`
}

type SpaceQuota struct {
	Guid                    string `json:"guid"`
	Name                    string `json:"name"`
	OrganizationGuid        string `json:"organization_guid"`
	NonBasicServicesAllowed bool   `json:"non_basic_services_allowed"`
	TotalServices           int    `json:"total_services"`
	TotalRoutes             int    `json:"total_routes"`
	MemoryLimit             int    `json:"memory_limit"`
	InstanceMemoryLimit     int    `json:"instance_memory_limit"`
	AppInstanceLimit        int    `json:"app_instance_limit"`
	AppTaskLimit            int    `json:"app_task_limit"`
	TotalServiceKeys        int    `json:"total_service_keys"`
	TotalReservedRoutePorts int    `json:"total_reserved_route_ports"`
	c                       *Client
}

func (c *Client) ListSpaceQuotasByQuery(query url.Values) ([]SpaceQuota, error) {
	var spaceQuotas []SpaceQuota
	requestUrl := "/v2/space_quota_definitions?" + query.Encode()
	for {
		spaceQuotasResp, err := c.getSpaceQuotasResponse(requestUrl)
		if err != nil {
			return []SpaceQuota{}, err
		}
		for _, space := range spaceQuotasResp.Resources {
			space.Entity.Guid = space.Meta.Guid
			space.Entity.c = c
			spaceQuotas = append(spaceQuotas, space.Entity)
		}
		requestUrl = spaceQuotasResp.NextUrl
		if requestUrl == "" {
			break
		}
	}
	return spaceQuotas, nil
}

func (c *Client) ListSpaceQuotas() ([]SpaceQuota, error) {
	return c.ListSpaceQuotasByQuery(nil)
}

func (c *Client) GetSpaceQuotaByName(name string) (SpaceQuota, error) {
	q := url.Values{}
	q.Set("q", "name:"+name)
	spaceQuotas, err := c.ListSpaceQuotasByQuery(q)
	if err != nil {
		return SpaceQuota{}, err
	}
	if len(spaceQuotas) != 1 {
		return SpaceQuota{}, fmt.Errorf("Unable to find space quota " + name)
	}
	return spaceQuotas[0], nil
}

func (c *Client) getSpaceQuotasResponse(requestUrl string) (SpaceQuotasResponse, error) {
	var spaceQuotasResp SpaceQuotasResponse
	r := c.NewRequest("GET", requestUrl)
	resp, err := c.DoRequest(r)
	if err != nil {
		return SpaceQuotasResponse{}, errors.Wrap(err, "Error requesting space quotas")
	}
	resBody, err := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	if err != nil {
		return SpaceQuotasResponse{}, errors.Wrap(err, "Error reading space quotas body")
	}
	err = json.Unmarshal(resBody, &spaceQuotasResp)
	if err != nil {
		return SpaceQuotasResponse{}, errors.Wrap(err, "Error unmarshalling space quotas")
	}
	return spaceQuotasResp, nil
}
