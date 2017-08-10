package cfclient

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"

	"github.com/pkg/errors"
)

type DomainsResponse struct {
	Count     int              `json:"total_results"`
	Pages     int              `json:"total_pages"`
	NextUrl   string           `json:"next_url"`
	Resources []DomainResource `json:"resources"`
}

type SharedDomainsResponse struct {
	Count     int                    `json:"total_results"`
	Pages     int                    `json:"total_pages"`
	NextUrl   string                 `json:"next_url"`
	Resources []SharedDomainResource `json:"resources"`
}

type DomainResource struct {
	Meta   Meta   `json:"metadata"`
	Entity Domain `json:"entity"`
}

type SharedDomainResource struct {
	Meta   Meta         `json:"metadata"`
	Entity SharedDomain `json:"entity"`
}

type Domain struct {
	Guid                   string `json:"guid"`
	Name                   string `json:"name"`
	OwningOrganizationGuid string `json:"owning_organization_guid"`
	OwningOrganizationUrl  string `json:"owning_organization_url"`
	SharedOrganizationsUrl string `json:"shared_organizations_url"`
	c                      *Client
}

type SharedDomain struct {
	Guid            string `json:"guid"`
	Name            string `json:"name"`
	RouterGroupGuid string `json:"router_group_guid"`
	RouterGroupType string `json:"router_group_type"`
	c               *Client
}

func (c *Client) ListDomainsByQuery(query url.Values) ([]Domain, error) {
	var domains []Domain
	requestUrl := "/v2/private_domains?" + query.Encode()
	for {
		var domainResp DomainsResponse
		r := c.NewRequest("GET", requestUrl)
		resp, err := c.DoRequest(r)
		if err != nil {
			return nil, errors.Wrap(err, "Error requesting domains")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading domains request")
		}

		err = json.Unmarshal(resBody, &domainResp)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling domains")
		}
		for _, domain := range domainResp.Resources {
			domain.Entity.Guid = domain.Meta.Guid
			domain.Entity.c = c
			domains = append(domains, domain.Entity)
		}
		requestUrl = domainResp.NextUrl
		if requestUrl == "" {
			break
		}
	}
	return domains, nil
}

func (c *Client) ListDomains() ([]Domain, error) {
	return c.ListDomainsByQuery(nil)
}

func (c *Client) ListSharedDomainsByQuery(query url.Values) ([]SharedDomain, error) {
	var domains []SharedDomain
	requestUrl := "/v2/shared_domains?" + query.Encode()
	for {
		var domainResp SharedDomainsResponse
		r := c.NewRequest("GET", requestUrl)
		resp, err := c.DoRequest(r)
		if err != nil {
			return nil, errors.Wrap(err, "Error requesting shared domains")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading shared domains request")
		}

		err = json.Unmarshal(resBody, &domainResp)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling shared domains")
		}
		for _, domain := range domainResp.Resources {
			domain.Entity.Guid = domain.Meta.Guid
			domain.Entity.c = c
			domains = append(domains, domain.Entity)
		}
		requestUrl = domainResp.NextUrl
		if requestUrl == "" {
			break
		}
	}
	return domains, nil
}

func (c *Client) ListSharedDomains() ([]SharedDomain, error) {
	return c.ListSharedDomainsByQuery(nil)
}

func (c *Client) GetDomainByName(name string) (Domain, error) {
	q := url.Values{}
	q.Set("q", "name:"+name)
	domains, err := c.ListDomainsByQuery(q)
	if err != nil {
		return Domain{}, errors.Wrapf(err, "Error during domain lookup %s", name)
	}
	if len(domains) == 0 {
		return Domain{}, errors.New(fmt.Sprintf("Unable to find domain %s", name))
	}
	return domains[0], nil
}

func (c *Client) GetSharedDomainByName(name string) (SharedDomain, error) {
	q := url.Values{}
	q.Set("q", "name:"+name)
	domains, err := c.ListSharedDomainsByQuery(q)
	if err != nil {
		return SharedDomain{}, errors.Wrapf(err, "Error during shared domain lookup %s", name)
	}
	if len(domains) == 0 {
		return SharedDomain{}, errors.New(fmt.Sprintf("Unable to find shared domain %s", name))
	}
	return domains[0], nil
}

func (c *Client) CreateDomain(name, orgGuid string) (*Domain, error) {
	req := c.NewRequest("POST", "/v2/private_domains")
	req.obj = map[string]interface{}{
		"name": name,
		"owning_organization_guid": orgGuid,
	}
	resp, err := c.DoRequest(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusCreated {
		return nil, errors.Wrapf(err, "Error creating domain %s, response code: %d", name, resp.StatusCode)
	}
	return respBodyToDomain(resp.Body, c)
}

func (c *Client) DeleteDomain(guid string) error {
	resp, err := c.DoRequest(c.NewRequest("DELETE", fmt.Sprintf("/v2/private_domains/%s", guid)))
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusNoContent {
		return errors.Wrapf(err, "Error deleting domain %s, response code: %d", guid, resp.StatusCode)
	}
	return nil
}

func respBodyToDomain(body io.ReadCloser, c *Client) (*Domain, error) {
	bodyRaw, err := ioutil.ReadAll(body)
	if err != nil {
		return nil, err
	}
	domainRes := DomainResource{}
	err = json.Unmarshal([]byte(bodyRaw), &domainRes)
	if err != nil {
		return nil, err
	}
	domain := domainRes.Entity
	domain.Guid = domainRes.Meta.Guid
	domain.c = c
	return &domain, nil
}
