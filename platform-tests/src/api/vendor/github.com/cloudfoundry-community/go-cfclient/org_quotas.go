package cfclient

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/url"

	"github.com/pkg/errors"
)

type OrgQuotasResponse struct {
	Count     int                 `json:"total_results"`
	Pages     int                 `json:"total_pages"`
	NextUrl   string              `json:"next_url"`
	Resources []OrgQuotasResource `json:"resources"`
}

type OrgQuotasResource struct {
	Meta   Meta     `json:"metadata"`
	Entity OrgQuota `json:"entity"`
}

type OrgQuota struct {
	Guid                    string `json:"guid"`
	Name                    string `json:"name"`
	NonBasicServicesAllowed bool   `json:"non_basic_services_allowed"`
	TotalServices           int    `json:"total_services"`
	TotalRoutes             int    `json:"total_routes"`
	TotalPrivateDomains     int    `json:"total_private_domains"`
	MemoryLimit             int    `json:"memory_limit"`
	TrialDBAllowed          bool   `json:"trial_db_allowed"`
	InstanceMemoryLimit     int    `json:"instance_memory_limit"`
	AppInstanceLimit        int    `json:"app_instance_limit"`
	AppTaskLimit            int    `json:"app_task_limit"`
	TotalServiceKeys        int    `json:"total_service_keys"`
	TotalReservedRoutePorts int    `json:"total_reserved_route_ports"`
	c                       *Client
}

func (c *Client) ListOrgQuotasByQuery(query url.Values) ([]OrgQuota, error) {
	var orgQuotas []OrgQuota
	requestUrl := "/v2/quota_definitions?" + query.Encode()
	for {
		orgQuotasResp, err := c.getOrgQuotasResponse(requestUrl)
		if err != nil {
			return []OrgQuota{}, err
		}
		for _, org := range orgQuotasResp.Resources {
			org.Entity.Guid = org.Meta.Guid
			org.Entity.c = c
			orgQuotas = append(orgQuotas, org.Entity)
		}
		requestUrl = orgQuotasResp.NextUrl
		if requestUrl == "" {
			break
		}
	}
	return orgQuotas, nil
}

func (c *Client) ListOrgQuotas() ([]OrgQuota, error) {
	return c.ListOrgQuotasByQuery(nil)
}

func (c *Client) GetOrgQuotaByName(name string) (OrgQuota, error) {
	q := url.Values{}
	q.Set("q", "name:"+name)
	orgQuotas, err := c.ListOrgQuotasByQuery(q)
	if err != nil {
		return OrgQuota{}, err
	}
	if len(orgQuotas) != 1 {
		return OrgQuota{}, fmt.Errorf("Unable to find org quota " + name)
	}
	return orgQuotas[0], nil
}

func (c *Client) getOrgQuotasResponse(requestUrl string) (OrgQuotasResponse, error) {
	var orgQuotasResp OrgQuotasResponse
	r := c.NewRequest("GET", requestUrl)
	resp, err := c.DoRequest(r)
	if err != nil {
		return OrgQuotasResponse{}, errors.Wrap(err, "Error requesting org quotas")
	}
	resBody, err := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	if err != nil {
		return OrgQuotasResponse{}, errors.Wrap(err, "Error reading org quotas body")
	}
	err = json.Unmarshal(resBody, &orgQuotasResp)
	if err != nil {
		return OrgQuotasResponse{}, errors.Wrap(err, "Error unmarshalling org quotas")
	}
	return orgQuotasResp, nil
}
