package test

import (
	"fmt"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfoundry/fakes"
	cf "github.com/cloudfoundry-community/go-cfclient"
	"net/url"
)

// Provides a pre-configured stub of the
// CloudFoundry API client for use in tests.
//
// It doesn't cover every part of the API, just
// those bits needed by tests.
type CloudFoundryAPIStub struct {
	APIFake *fakes.FakeCloudFoundryClient

	// Each of these types maps the content of the
	// API query's "q" parameter to a slice of
	// the relevant type.
	Services         map[string][]cf.Service
	ServicePlans     map[string][]cf.ServicePlan
	ServiceInstances map[string][]cf.ServiceInstance

	// Each of these types maps a GUID to an instance of the type
	Orgs   map[string]cf.Org
	Spaces map[string]cf.Space
}

func (s *CloudFoundryAPIStub) listServiceByQueryStub(values url.Values) ([]cf.Service, error) {
	if services, ok := s.Services[values.Get("q")]; ok {
		return services, nil
	}

	return []cf.Service{}, nil
}

func (s *CloudFoundryAPIStub) listServicePlansByQueryStub(values url.Values) ([]cf.ServicePlan, error) {
	if servicePlans, ok := s.ServicePlans[values.Get("q")]; ok {
		return servicePlans, nil
	}

	return []cf.ServicePlan{}, nil
}

func (s *CloudFoundryAPIStub) listServiceInstancesByQueryStub(values url.Values) ([]cf.ServiceInstance, error) {
	if serviceInstances, ok := s.ServiceInstances[values.Get("q")]; ok {
		return serviceInstances, nil
	}

	return []cf.ServiceInstance{}, nil
}

func (s *CloudFoundryAPIStub) getSpaceByGuidStub(guid string) (cf.Space, error) {
	if space, ok := s.Spaces[guid]; ok {
		return space, nil
	}

	return cf.Space{}, fmt.Errorf("cannot find space with guid '%s'", guid)
}

func (s *CloudFoundryAPIStub) getOrgByGuidStub(guid string) (cf.Org, error) {
	if org, ok := s.Orgs[guid]; ok {
		return org, nil
	}

	return cf.Org{}, fmt.Errorf("cannot find org with guid '%s'", guid)
}

func NewCloudFoundryAPIStub() *CloudFoundryAPIStub {
	stub := &CloudFoundryAPIStub{}

	stub.APIFake = &fakes.FakeCloudFoundryClient{
		ListServicesByQueryStub:         stub.listServiceByQueryStub,
		ListServicePlansByQueryStub:     stub.listServicePlansByQueryStub,
		ListServiceInstancesByQueryStub: stub.listServiceInstancesByQueryStub,
		GetSpaceByGuidStub:              stub.getSpaceByGuidStub,
		GetOrgByGuidStub:                stub.getOrgByGuidStub,
	}

	return stub
}
