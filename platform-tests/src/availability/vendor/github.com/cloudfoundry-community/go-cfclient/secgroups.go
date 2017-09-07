package cfclient

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"reflect"
	"strings"

	"github.com/pkg/errors"
)

type SecGroupResponse struct {
	Count     int                `json:"total_results"`
	Pages     int                `json:"total_pages"`
	NextUrl   string             `json:"next_url"`
	Resources []SecGroupResource `json:"resources"`
}

type SecGroupCreateResponse struct {
	Code        int    `json:"code"`
	ErrorCode   string `json:"error_code"`
	Description string `json:"description"`
}

type SecGroupResource struct {
	Meta   Meta     `json:"metadata"`
	Entity SecGroup `json:"entity"`
}

type SecGroup struct {
	Guid       string          `json:"guid"`
	Name       string          `json:"name"`
	Rules      []SecGroupRule  `json:"rules"`
	Running    bool            `json:"running_default"`
	Staging    bool            `json:"staging_default"`
	SpacesURL  string          `json:"spaces_url"`
	SpacesData []SpaceResource `json:"spaces"`
	c          *Client
}

type SecGroupRule struct {
	Protocol    string `json:"protocol"`
	Ports       string `json:"ports,omitempty"`       //e.g. "4000-5000,9142"
	Destination string `json:"destination"`           //CIDR Format
	Description string `json:"description,omitempty"` //Optional description
	Code        int    `json:"code"`                  // ICMP code
	Type        int    `json:"type"`                  //ICMP type. Only valid if Protocol=="icmp"
	Log         bool   `json:"log,omitempty"`         //If true, log this rule
}

func (c *Client) ListSecGroups() (secGroups []SecGroup, err error) {
	requestURL := "/v2/security_groups?inline-relations-depth=1"
	for requestURL != "" {
		var secGroupResp SecGroupResponse
		r := c.NewRequest("GET", requestURL)
		resp, err := c.DoRequest(r)

		if err != nil {
			return nil, errors.Wrap(err, "Error requesting sec groups")
		}
		resBody, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.Wrap(err, "Error reading sec group response body")
		}

		err = json.Unmarshal(resBody, &secGroupResp)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling sec group")
		}

		for _, secGroup := range secGroupResp.Resources {
			secGroup.Entity.Guid = secGroup.Meta.Guid
			secGroup.Entity.c = c
			for i, space := range secGroup.Entity.SpacesData {
				space.Entity.Guid = space.Meta.Guid
				secGroup.Entity.SpacesData[i] = space
			}
			if len(secGroup.Entity.SpacesData) == 0 {
				spaces, err := secGroup.Entity.ListSpaceResources()
				if err != nil {
					return nil, err
				}
				for _, space := range spaces {
					secGroup.Entity.SpacesData = append(secGroup.Entity.SpacesData, space)
				}
			}
			secGroups = append(secGroups, secGroup.Entity)
		}

		requestURL = secGroupResp.NextUrl
		resp.Body.Close()
	}
	return secGroups, nil
}

func (c *Client) GetSecGroupByName(name string) (secGroup SecGroup, err error) {
	requestURL := "/v2/security_groups?q=name:" + name
	var secGroupResp SecGroupResponse
	r := c.NewRequest("GET", requestURL)
	resp, err := c.DoRequest(r)

	if err != nil {
		return secGroup, errors.Wrap(err, "Error requesting sec groups")
	}
	resBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return secGroup, errors.Wrap(err, "Error reading sec group response body")
	}

	err = json.Unmarshal(resBody, &secGroupResp)
	if err != nil {
		return secGroup, errors.Wrap(err, "Error unmarshaling sec group")
	}
	if len(secGroupResp.Resources) == 0 {
		return secGroup, fmt.Errorf("No security group with name %v found", name)
	}
	secGroup = secGroupResp.Resources[0].Entity
	secGroup.Guid = secGroupResp.Resources[0].Meta.Guid
	secGroup.c = c

	resp.Body.Close()
	return secGroup, nil
}

func (secGroup *SecGroup) ListSpaceResources() ([]SpaceResource, error) {
	var spaceResources []SpaceResource
	requestURL := secGroup.SpacesURL
	for requestURL != "" {
		spaceResp, err := secGroup.c.getSpaceResponse(requestURL)
		if err != nil {
			return []SpaceResource{}, err
		}
		for i, spaceRes := range spaceResp.Resources {
			spaceRes.Entity.Guid = spaceRes.Meta.Guid
			spaceResp.Resources[i] = spaceRes
		}
		spaceResources = append(spaceResources, spaceResp.Resources...)
		requestURL = spaceResp.NextUrl
	}
	return spaceResources, nil
}

/*
CreateSecGroup contacts the CF endpoint for creating a new security group.
name: the name to give to the created security group
rules: A slice of rule objects that describe the rules that this security group enforces.
	This can technically be nil or an empty slice - we won't judge you
spaceGuids: The security group will be associated with the spaces specified by the contents of this slice.
	If nil, the security group will not be associated with any spaces initially.
*/
func (c *Client) CreateSecGroup(name string, rules []SecGroupRule, spaceGuids []string) (*SecGroup, error) {
	return c.secGroupCreateHelper("/v2/security_groups", "POST", name, rules, spaceGuids)
}

/*
UpdateSecGroup contacts the CF endpoint to update an existing security group.
guid: identifies the security group that you would like to update.
name: the new name to give to the security group
rules: A slice of rule objects that describe the rules that this security group enforces.
	If this is left nil, the rules will not be changed.
spaceGuids: The security group will be associated with the spaces specified by the contents of this slice.
	If nil, the space associations will not be changed.
*/
func (c *Client) UpdateSecGroup(guid, name string, rules []SecGroupRule, spaceGuids []string) (*SecGroup, error) {
	return c.secGroupCreateHelper("/v2/security_groups/"+guid, "PUT", name, rules, spaceGuids)
}

/*
DeleteSecGroup contacts the CF endpoint to delete an existing security group.
guid: Indentifies the security group to be deleted.
*/
func (c *Client) DeleteSecGroup(guid string) error {
	//Perform the DELETE and check for errors
	resp, err := c.DoRequest(c.NewRequest("DELETE", fmt.Sprintf("/v2/security_groups/%s", guid)))
	if err != nil {
		return err
	}
	if resp.StatusCode != 204 { //204 No Content
		return fmt.Errorf("CF API returned with status code %d", resp.StatusCode)
	}
	return nil
}

/*
GetSecGroup contacts the CF endpoint for fetching the info for a particular security group.
guid: Identifies the security group to fetch information from
*/
func (c *Client) GetSecGroup(guid string) (*SecGroup, error) {
	//Perform the GET and check for errors
	resp, err := c.DoRequest(c.NewRequest("GET", "/v2/security_groups/"+guid))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("CF API returned with status code %d", resp.StatusCode)
	}
	//get the json out of the response body
	return respBodyToSecGroup(resp.Body, c)
}

/*
BindSecGroup contacts the CF endpoint to associate a space with a security group
secGUID: identifies the security group to add a space to
spaceGUID: identifies the space to associate
*/
func (c *Client) BindSecGroup(secGUID, spaceGUID string) error {
	//Perform the PUT and check for errors
	resp, err := c.DoRequest(c.NewRequest("PUT", fmt.Sprintf("/v2/security_groups/%s/spaces/%s", secGUID, spaceGUID)))
	if err != nil {
		return err
	}
	if resp.StatusCode != 201 { //201 Created
		return fmt.Errorf("CF API returned with status code %d", resp.StatusCode)
	}
	return nil
}

/*
BindRunningSecGroup contacts the CF endpoint to associate  a security group
secGUID: identifies the security group to add a space to
*/
func (c *Client) BindRunningSecGroup(secGUID string) error {
	//Perform the PUT and check for errors
	resp, err := c.DoRequest(c.NewRequest("PUT", fmt.Sprintf("/v2/config/running_security_groups/%s", secGUID)))
	if err != nil {
		return err
	}
	if resp.StatusCode != 200 { //200
		return fmt.Errorf("CF API returned with status code %d", resp.StatusCode)
	}
	return nil
}

/*
BindStagingSecGroup contacts the CF endpoint to associate a space with a security group
secGUID: identifies the security group to add a space to
*/
func (c *Client) BindStagingSecGroup(secGUID string) error {
	//Perform the PUT and check for errors
	resp, err := c.DoRequest(c.NewRequest("PUT", fmt.Sprintf("/v2/config/staging_security_groups/%s", secGUID)))
	if err != nil {
		return err
	}
	if resp.StatusCode != 200 { //200
		return fmt.Errorf("CF API returned with status code %d", resp.StatusCode)
	}
	return nil
}

/*
UnbindSecGroup contacts the CF endpoint to dissociate a space from a security group
secGUID: identifies the security group to remove a space from
spaceGUID: identifies the space to dissociate from the security group
*/
func (c *Client) UnbindSecGroup(secGUID, spaceGUID string) error {
	//Perform the DELETE and check for errors
	resp, err := c.DoRequest(c.NewRequest("DELETE", fmt.Sprintf("/v2/security_groups/%s/spaces/%s", secGUID, spaceGUID)))
	if err != nil {
		return err
	}
	if resp.StatusCode != 204 { //204 No Content
		return fmt.Errorf("CF API returned with status code %d", resp.StatusCode)
	}
	return nil
}

//Reads most security group response bodies into a SecGroup object
func respBodyToSecGroup(body io.ReadCloser, c *Client) (*SecGroup, error) {
	//get the json from the response body
	bodyRaw, err := ioutil.ReadAll(body)
	if err != nil {
		return nil, errors.Wrap(err, "Could not read response body")
	}
	jStruct := SecGroupResource{}
	//make it a SecGroup
	err = json.Unmarshal([]byte(bodyRaw), &jStruct)
	if err != nil {
		return nil, errors.Wrap(err, "Could not unmarshal response body as json")
	}
	//pull a few extra fields from other places
	ret := jStruct.Entity
	ret.Guid = jStruct.Meta.Guid
	ret.c = c
	return &ret, nil
}

func ConvertStructToMap(st interface{}) map[string]interface{} {

	reqRules := make(map[string]interface{})

	v := reflect.ValueOf(st)
	t := reflect.TypeOf(st)

	for i := 0; i < v.NumField(); i++ {
		key := strings.ToLower(t.Field(i).Name)
		typ := v.FieldByName(t.Field(i).Name).Kind().String()
		structTag := t.Field(i).Tag.Get("json")
		jsonName := strings.TrimSpace(strings.Split(structTag, ",")[0])
		value := v.FieldByName(t.Field(i).Name)

		// if jsonName is not empty use it for the key
		if jsonName != "" {
			key = jsonName
		}

		if typ == "string" {
			if !(value.String() == "" && strings.Contains(structTag, "omitempty")) {
				reqRules[key] = value.String()
			}
		} else if typ == "int" {
			reqRules[key] = value.Int()
		} else {
			reqRules[key] = value.Interface()
		}

	}

	return reqRules
}

//Create and Update secGroup pretty much do the same thing, so this function abstracts those out.
func (c *Client) secGroupCreateHelper(url, method, name string, rules []SecGroupRule, spaceGuids []string) (*SecGroup, error) {
	reqRules := make([]map[string]interface{}, len(rules))

	for i, rule := range rules {
		reqRules[i] = ConvertStructToMap(rule)
		protocol := strings.ToLower(reqRules[i]["protocol"].(string))

		// if not icmp protocol need to remove the Code/Type fields
		if protocol != "icmp" {
			delete(reqRules[i], "code")
			delete(reqRules[i], "type")
		}
	}

	req := c.NewRequest(method, url)
	//set up request body
	req.obj = map[string]interface{}{
		"name":        name,
		"rules":       reqRules,
		"space_guids": spaceGuids,
	}
	//fire off the request and check for problems
	resp, err := c.DoRequest(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != 201 { // Both create and update should give 201 CREATED
		var response SecGroupCreateResponse

		bodyRaw, _ := ioutil.ReadAll(resp.Body)

		err = json.Unmarshal(bodyRaw, &response)
		if err != nil {
			return nil, errors.Wrap(err, "Error unmarshaling response")
		}

		return nil, fmt.Errorf(`Request failed CF API returned with status code %d
-------------------------------
Error Code  %s
Code        %d
Description %s`,
			resp.StatusCode, response.ErrorCode, response.Code, response.Description)
	}
	//get the json from the response body
	return respBodyToSecGroup(resp.Body, c)
}
