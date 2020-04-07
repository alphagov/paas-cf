package stubs

import (
	"errors"
	"github.com/alphagov/paas-cf/tools/user_emails/emails/fakes"
	"github.com/cloudfoundry-community/go-cfclient"
	"net/url"
)

type StubCF struct {
}

func CreateFakeWithStubData() (StubCF, fakes.FakeClient) {
	fake := fakes.FakeClient{}
	stub := StubCF{}

	fake.ListSpaceManagersCalls(stub.ListSpaceManagers)
	fake.ListSpaceAuditorsCalls(stub.ListSpaceAuditors)
	fake.ListSpaceDevelopersCalls(stub.ListSpaceDevelopers)
	fake.ListSpacesByQueryCalls(stub.ListSpacesByQuery)
	fake.ListOrgsCalls(stub.ListOrgs)
	fake.ListOrgUsersCalls(stub.ListOrgUsers)
	fake.ListOrgManagersCalls(stub.ListOrgManagers)
	fake.ListOrgAuditorsCalls(stub.ListOrgAuditors)
	fake.ListOrgBillingManagersCalls(stub.ListOrgBillingManagers)

	return stub, fake
}

func (cf *StubCF) ListSpaceManagers(spaceGUID string) ([]cfclient.User, error) {
	spaceManagers := map[string][]cfclient.User{
		"org-1-space-1": {
			{Username: "org-1-space-1-manager-1@paas.gov"},
			{Username: "org-1-space-1-manager-2@paas.gov"},
		},
		"org-2-space-1": {
			{Username: "org-2-space-1-manager-1@paas.gov"},
		},
		"org-3-space-1": {
			{Username: "org-3-space-1-manager-1@paas.gov"},
		},
	}

	if value, ok := spaceManagers[spaceGUID]; ok {
		return value, nil
	}

	return nil, errors.New("unknown space guid")
}

func (cf *StubCF) ListSpaceAuditors(spaceGUID string) ([]cfclient.User, error) {
	spaceAuditors := map[string][]cfclient.User{
		"org-1-space-1": {
			{Username: "org-1-space-1-auditor-1@paas.gov"},
			{Username: "org-1-space-1-auditor-2@paas.gov"},
		},
		"org-2-space-1": {
			{Username: "org-2-space-1-auditor-1@paas.gov"},
		},
		"org-3-space-1": {
			{Username: "org-3-space-1-auditor-1@paas.gov"},
		},
	}

	if value, ok := spaceAuditors[spaceGUID]; ok {
		return value, nil
	}

	return nil, errors.New("unknown space guid")
}

func (cf *StubCF) ListSpaceDevelopers(spaceGUID string) ([]cfclient.User, error) {
	spaceDevs := map[string][]cfclient.User{
		"org-1-space-1": {
			{Username: "user-1@paas.gov"},
			{Username: "user-2@paas.gov"},
		},
		"org-2-space-1": {
			{Username: "user-1@paas.gov"},
			{Username: "test@homeoffice.x.gsi.gov.uk"},
		},
		"org-3-space-1": {
			{Username: "user-3@paas.gov"},
			{Username: "admin"},
		},
	}

	if value, ok := spaceDevs[spaceGUID]; ok {
		return value, nil
	}

	return nil, errors.New("unknown space guid")
}

func (cf *StubCF) ListSpacesByQuery(query url.Values) ([]cfclient.Space, error) {
	if query.Get("organization_guid") == "" {
		return nil, errors.New("unknown org")
	}

	spaces := map[string][]cfclient.Space{
		"org-1": {
			{Guid: "org-1-space-1"},
		},

		"org-2": {
			{Guid: "org-2-space-1"},
		},

		"org-3": {
			{Guid: "org-3-space-1"},
		},
	}

	organizationGuid := query.Get("organization_guid")

	if value, ok := spaces[organizationGuid]; ok {
		return value, nil
	}

	return nil, errors.New("unknown org id")
}

func (cf *StubCF) ListOrgs() ([]cfclient.Org, error) {
	return []cfclient.Org{
		{Guid: "org-1", Name: "Org 1"},
		{Guid: "org-2", Name: "Org 2"},
		{Guid: "org-3", Name: "Org 3"},
	}, nil
}

func (cf *StubCF) ListOrgUsers(orgGUID string) ([]cfclient.User, error) {
	panic("implement me")
}

func (cf *StubCF) ListOrgManagers(orgGUID string) ([]cfclient.User, error) {
	managers := map[string][]cfclient.User{
		"org-1": {
			{Username: "org-1-manager-1@paas.gov"},
			{Username: "org-1-manager-2@paas.gov"},
		},
		"org-2": {
			{Username: "org-2-manager-1@paas.gov"},
		},
		"org-3": {
			{Username: "org-3-manager-1@paas.gov"},
		},
	}

	if value, ok := managers[orgGUID]; ok {
		return value, nil
	}

	return nil, errors.New("unknown org guid")
}

func (cf *StubCF) ListOrgAuditors(orgGUID string) ([]cfclient.User, error) {
	auditors := map[string][]cfclient.User{
		"org-1": {
			{Username: "org-1-auditor-1@paas.gov"},
			{Username: "org-1-auditor-2@paas.gov"},
		},
		"org-2": {
			{Username: "org-2-auditor-1@paas.gov"},
		},
		"org-3": {
			{Username: "org-3-auditor-1@paas.gov"},
		},
	}

	if value, ok := auditors[orgGUID]; ok {
		return value, nil
	}

	return nil, errors.New("unknown org guid")
}

func (cf *StubCF) ListOrgBillingManagers(orgGUID string) ([]cfclient.User, error) {
	billingManagers := map[string][]cfclient.User{
		"org-1": {
			{Username: "org-1-billing-manager-1@paas.gov"},
			{Username: "org-1-billing-manager-2@paas.gov"},
		},
		"org-2": {
			{Username: "org-2-billing-manager-1@paas.gov"},
		},
		"org-3": {
			{Username: "org-3-billing-manager-1@paas.gov"},
		},
	}

	if value, ok := billingManagers[orgGUID]; ok {
		return value, nil
	}

	return nil, errors.New("unknown org guid")
}
