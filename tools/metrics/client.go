package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"

	"code.cloudfoundry.org/lager"
	cfclient "github.com/cloudfoundry-community/go-cfclient"
	"github.com/pkg/errors"
)

type ClientConfig struct {
	ApiAddress        string
	ClientID          string
	ClientSecret      string
	SkipSslValidation bool
	Logger            lager.Logger
}

type Client struct {
	cf     *cfclient.Client
	logger lager.Logger
}

func (c *Client) get(path string, target interface{}) error {
	c.logger.Debug("fetching", lager.Data{
		"path": path,
	})
	req := c.cf.NewRequest("GET", path)
	resp, err := c.cf.DoRequest(req)
	if err != nil {
		return errors.Wrapf(err, "error fetching %s", path)
	}
	defer resp.Body.Close()
	resBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return errors.Wrapf(err, "error reading %s body", path)
	}
	err = json.Unmarshal(resBody, target)
	if err != nil {
		return errors.Wrapf(err, "error unmarshalling %s", path)
	}
	return nil
}

func (c *Client) count(path string) (int, error) {
	var response struct {
		TotalResults int `json:"total_results"`
	}
	if err := c.get(path, &response); err != nil {
		return 0, err
	}
	return response.TotalResults, nil
}

func (c *Client) CountServiceInstances() (int, error) {
	return c.count("/v2/service_instances")
}

type User struct {
	Guid string
	Name string
}

func (c *Client) OrgUsers(guid string) ([]User, error) {
	users := []User{}
	path := fmt.Sprintf("/v2/organizations/%s/users", guid)
	for {
		var response struct {
			NextUrl   string `json:"next_url"`
			Resources []struct {
				MetaData struct {
					Guid string `json:"guid"`
				}
				Entity struct {
					Name string `json:"name"`
				}
			}
		}
		if err := c.get(path, &response); err != nil {
			return nil, err
		}
		for _, res := range response.Resources {
			users = append(users, User{
				Guid: res.MetaData.Guid,
				Name: res.Entity.Name,
			})
		}
		path = response.NextUrl
		if path == "" {
			break
		}
	}
	return users, nil
}

func NewClient(cfg ClientConfig) (*Client, error) {
	if cfg.Logger == nil {
		cfg.Logger = lager.NewLogger("client")
	}
	cf, err := NewCFClient(cfg)
	if err != nil {
		return nil, err
	}
	return &Client{cf: cf, logger: cfg.Logger}, nil
}

func NewCFClient(cfg ClientConfig) (*cfclient.Client, error) {
	return cfclient.NewClient(&cfclient.Config{
		ApiAddress:        cfg.ApiAddress,
		ClientID:          cfg.ClientID,
		ClientSecret:      cfg.ClientSecret,
		SkipSslValidation: cfg.SkipSslValidation,
	})
}
