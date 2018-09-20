package cfclient

import (
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListOrgs(t *testing.T) {
	Convey("List Orgs", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil},
			{"GET", "/v2/orgsPage2", listOrgsPayloadPage2, "", 200, "results-per-page=2", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgs, err := client.ListOrgs()
		So(err, ShouldBeNil)

		So(len(orgs), ShouldEqual, 4)
		So(orgs[0].Guid, ShouldEqual, "a537761f-9d93-4b30-af17-3d73dbca181b")
		So(orgs[0].Name, ShouldEqual, "demo")
	})
}

func TestListOrgsByQuery(t *testing.T) {
	Convey("List Orgs", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/organizations", listOrgsPayload, "", 200, "results-per-page=2", nil},
			{"GET", "/v2/orgsPage2", listOrgsPayloadPage2, "", 200, "results-per-page=2", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		var query = url.Values{
			"results-per-page": []string{
				"2",
			},
		}
		orgs, err := client.ListOrgsByQuery(query)
		So(err, ShouldBeNil)

		So(len(orgs), ShouldEqual, 4)
		So(orgs[0].Guid, ShouldEqual, "a537761f-9d93-4b30-af17-3d73dbca181b")
		So(orgs[0].Name, ShouldEqual, "demo")
	})
}

func TestGetOrgByGuid(t *testing.T) {
	Convey("Get org by GUID", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b", orgByGuidPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org, err := client.GetOrgByGuid("1c0e6074-777f-450e-9abc-c42f39d9b75b")
		So(err, ShouldBeNil)

		So(org.Guid, ShouldEqual, "1c0e6074-777f-450e-9abc-c42f39d9b75b")
		So(org.Name, ShouldEqual, "name-1716")
	})
}

func TestOrgSpaces(t *testing.T) {
	Convey("Get spaces by org", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/foo/spaces", orgSpacesPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaces, err := client.OrgSpaces("foo")
		So(err, ShouldBeNil)

		So(len(spaces), ShouldEqual, 1)
		So(spaces[0].Guid, ShouldEqual, "b8aff561-175d-45e8-b1e7-67e2aedb03b6")
		So(spaces[0].Name, ShouldEqual, "test")
	})
}

func TestListOrgUsers(t *testing.T) {
	Convey("Get Org Users for an org", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/foo/users", listOrgPeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		users, err := client.ListOrgUsers("foo")
		So(err, ShouldBeNil)
		So(len(users), ShouldEqual, 2)
		So(users[0].Username, ShouldEqual, "user1")
		So(users[1].Username, ShouldEqual, "user2")
	})
}

func TestListOrgManagers(t *testing.T) {
	Convey("Get Org Managers for an org", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/foo/managers", listOrgPeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		managers, err := client.ListOrgManagers("foo")
		So(err, ShouldBeNil)
		So(len(managers), ShouldEqual, 2)
		So(managers[0].Username, ShouldEqual, "user1")
		So(managers[1].Username, ShouldEqual, "user2")
	})
}

func TestListOrgAuditors(t *testing.T) {
	Convey("Get Org Auditors for an org", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/foo/auditors", listOrgPeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		users, err := client.ListOrgAuditors("foo")
		So(err, ShouldBeNil)
		So(len(users), ShouldEqual, 2)
		So(users[0].Username, ShouldEqual, "user1")
		So(users[1].Username, ShouldEqual, "user2")
	})
}
func TestListBillingManagers(t *testing.T) {
	Convey("Get Billing Manager for an org", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/foo/billing_managers", listOrgPeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		managers, err := client.ListOrgBillingManagers("foo")
		So(err, ShouldBeNil)
		So(len(managers), ShouldEqual, 2)
		So(managers[0].Username, ShouldEqual, "user1")
		So(managers[1].Username, ShouldEqual, "user2")
	})
}

func TestOrgSummary(t *testing.T) {
	Convey("Get org summary", t, func() {
		setup(MockRoute{"GET", "/v2/organizations/06dcedd4-1f24-49a6-adc1-cce9131a1b2c/summary", orgSummaryPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
			c:    client,
		}
		summary, err := org.Summary()
		So(err, ShouldBeNil)

		So(summary.Guid, ShouldEqual, "06dcedd4-1f24-49a6-adc1-cce9131a1b2c")
		So(summary.Name, ShouldEqual, "system")
		So(summary.Status, ShouldEqual, "active")

		spaces := summary.Spaces
		So(len(spaces), ShouldEqual, 1)
		So(spaces[0].Guid, ShouldEqual, "494d8b64-8181-4183-a6d3-6279db8fec6e")
		So(spaces[0].Name, ShouldEqual, "test")
		So(spaces[0].ServiceCount, ShouldEqual, 1)
		So(spaces[0].AppCount, ShouldEqual, 2)
		So(spaces[0].MemDevTotal, ShouldEqual, 32)
		So(spaces[0].MemProdTotal, ShouldEqual, 64)
	})
}

func TestOrgQuota(t *testing.T) {
	Convey("Get org quota", t, func() {
		setup(MockRoute{"GET", "/v2/quota_definitions/a537761f-9d93-4b30-af17-3d73dbca181b", orgQuotaPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			QuotaDefinitionGuid: "a537761f-9d93-4b30-af17-3d73dbca181b",
			c:                   client,
		}
		orgQuota, err := org.Quota()
		So(err, ShouldBeNil)

		So(orgQuota.Guid, ShouldEqual, "a537761f-9d93-4b30-af17-3d73dbca181b")
		So(orgQuota.Name, ShouldEqual, "test-2")
		So(orgQuota.NonBasicServicesAllowed, ShouldEqual, false)
		So(orgQuota.TotalServices, ShouldEqual, 10)
		So(orgQuota.TotalRoutes, ShouldEqual, 20)
		So(orgQuota.TotalPrivateDomains, ShouldEqual, 30)
		So(orgQuota.MemoryLimit, ShouldEqual, 40)
		So(orgQuota.TrialDBAllowed, ShouldEqual, true)
		So(orgQuota.InstanceMemoryLimit, ShouldEqual, 50)
		So(orgQuota.AppInstanceLimit, ShouldEqual, 60)
		So(orgQuota.AppTaskLimit, ShouldEqual, 70)
		So(orgQuota.TotalServiceKeys, ShouldEqual, 80)
		So(orgQuota.TotalReservedRoutePorts, ShouldEqual, 90)
	})
}

func TestCreateOrg(t *testing.T) {
	Convey("Create org", t, func() {
		setup(MockRoute{"POST", "/v2/organizations", createOrgPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org, err := client.CreateOrg(OrgRequest{Name: "my-org"})
		So(err, ShouldBeNil)
		So(org.Guid, ShouldEqual, "22b3b0a0-6511-47e5-8f7a-93bbd2ff446e")
	})
}

func TestUpdateOrg(t *testing.T) {
	Convey("Update org", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e", createOrgPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org, err := client.UpdateOrg("22b3b0a0-6511-47e5-8f7a-93bbd2ff446e", OrgRequest{Name: "my-org"})
		So(err, ShouldBeNil)
		So(org.Guid, ShouldEqual, "22b3b0a0-6511-47e5-8f7a-93bbd2ff446e")
	})
}

func TestDeleteOrg(t *testing.T) {
	Convey("Delete org", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b", "", "", 204, "recursive=false&async=false", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteOrg("a537761f-9d93-4b30-af17-3d73dbca181b", false, false)
		So(err, ShouldBeNil)
	})
}

func TestAssociateManager(t *testing.T) {
	Convey("Associate manager", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers/user-guid", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateManager("user-guid")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateAuditor(t *testing.T) {
	Convey("Associate auditor", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors/user-guid", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateAuditor("user-guid")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateBillingManager(t *testing.T) {
	Convey("Associate billing manager", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers/user-guid", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateBillingManager("user-guid")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateUser(t *testing.T) {
	Convey("Associate user", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users/user-guid", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateUser("user-guid")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateManagerByUsername(t *testing.T) {
	Convey("Associate manager by username", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateManagerByUsername("user-name")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateAuditorByUsername(t *testing.T) {
	Convey("Associate auditor by username", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateAuditorByUsername("user-name")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateBillingManagerByUsername(t *testing.T) {
	Convey("Associate billing manager by username", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateBillingManagerByUsername("user-name")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateUserByUsername(t *testing.T) {
	Convey("Associate user by username", t, func() {
		setup(MockRoute{"PUT", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users", associateOrgUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newOrg, err := org.AssociateUserByUsername("user-name")
		So(err, ShouldBeNil)
		So(newOrg.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestRemoveManager(t *testing.T) {
	Convey("Remove manager", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers/user-guid", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveManager("user-guid")
		So(err, ShouldBeNil)
	})
}

func TestRemoveAuditor(t *testing.T) {
	Convey("Remove auditor", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors/user-guid", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveAuditor("user-guid")
		So(err, ShouldBeNil)
	})
}

func TestRemoveBillingManager(t *testing.T) {
	Convey("Remove billing manager", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers/user-guid", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveBillingManager("user-guid")
		So(err, ShouldBeNil)
	})
}

func TestRemoveUser(t *testing.T) {
	Convey("Remove user", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users/user-guid", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveUser("user-guid")
		So(err, ShouldBeNil)
	})
}

func TestRemoveManagerByUsername(t *testing.T) {
	Convey("Remove manager by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveManagerByUsername("user-name")
		So(err, ShouldBeNil)
	})
}

func TestRemoveAuditorByUsername(t *testing.T) {
	Convey("Remove auditor by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveAuditorByUsername("user-name")
		So(err, ShouldBeNil)
	})
}

func TestRemoveBillingManagerByUsername(t *testing.T) {
	Convey("Remove billing manager by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveBillingManagerByUsername("user-name")
		So(err, ShouldBeNil)
	})
}

func TestRemoveUserByUsername(t *testing.T) {
	Convey("Remove user by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		org := &Org{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = org.RemoveUserByUsername("user-name")
		So(err, ShouldBeNil)
	})
}

func TestListOrgSpaceQuotas(t *testing.T) {
	Convey("List Org Space Quotas", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/organizations/06dcedd4-1f24-49a6-adc1-cce9131a1b2c/space_quota_definitions", listSpaceQuotasPayloadPage1, "", 200, "", nil},
			{"GET", "/v2/space_quota_definitions_page_2", listSpaceQuotasPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaceQuotas, err := client.ListOrgSpaceQuotas("06dcedd4-1f24-49a6-adc1-cce9131a1b2c")
		So(err, ShouldBeNil)

		So(len(spaceQuotas), ShouldEqual, 2)
		So(spaceQuotas[0].Guid, ShouldEqual, "889aa2ed-a883-4cc0-abe5-804b2503f15d")
		So(spaceQuotas[0].Name, ShouldEqual, "test-1")
		So(spaceQuotas[0].NonBasicServicesAllowed, ShouldEqual, true)
		So(spaceQuotas[0].TotalServices, ShouldEqual, -1)
		So(spaceQuotas[0].TotalRoutes, ShouldEqual, 100)
		So(spaceQuotas[0].MemoryLimit, ShouldEqual, 102400)
		So(spaceQuotas[0].InstanceMemoryLimit, ShouldEqual, -1)
		So(spaceQuotas[0].AppInstanceLimit, ShouldEqual, -1)
		So(spaceQuotas[0].AppTaskLimit, ShouldEqual, -1)
		So(spaceQuotas[0].TotalServiceKeys, ShouldEqual, -1)
		So(spaceQuotas[0].TotalReservedRoutePorts, ShouldEqual, -1)
	})
}

func TestListOrgPrivateDomains(t *testing.T) {
	Convey("List Org Space Quotas", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/organizations/06dcedd4-1f24-49a6-adc1-cce9131a1b2c/private_domains", listDomainsPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		privateDomains, err := client.ListOrgPrivateDomains("06dcedd4-1f24-49a6-adc1-cce9131a1b2c")
		So(err, ShouldBeNil)

		So(len(privateDomains), ShouldEqual, 4)

	})
}

func TestShareOrgPrivateDomain(t *testing.T) {
	Convey("Share Org Private Domain", t, func() {
		mocks := []MockRoute{
			{"PUT", "/v2/organizations/3b6f763f-aae1-4177-9b93-f2de6f2a48f2/private_domains/3b6f763f-aae1-4177-9b93-f2de6f2a48f2", sharePrivateDomainPayload, "", 201, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		domain, err := client.ShareOrgPrivateDomain("3b6f763f-aae1-4177-9b93-f2de6f2a48f2", "3b6f763f-aae1-4177-9b93-f2de6f2a48f2")
		So(err, ShouldBeNil)

		So(domain.Guid, ShouldEqual, "3b6f763f-aae1-4177-9b93-f2de6f2a48f2")

	})
}

func TestUnshareOrgPrivateDomain(t *testing.T) {
	Convey("Unshare Org Private Domain", t, func() {
		mocks := []MockRoute{
			{"DELETE", "/v2/organizations/3b6f763f-aae1-4177-9b93-f2de6f2a48f2/private_domains/3b6f763f-aae1-4177-9b93-f2de6f2a48f2", sharePrivateDomainPayload, "", 201, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.UnshareOrgPrivateDomain("3b6f763f-aae1-4177-9b93-f2de6f2a48f2", "3b6f763f-aae1-4177-9b93-f2de6f2a48f2")
		So(err, ShouldBeNil)

	})
}

func TestDefaultIsolationSegmentForOrg(t *testing.T) {
	Convey("set Default IsolationSegment", t, func() {
		defaultIsolationSegmentPayload := `{"data":{"guid":"3b6f763f-aae1-4177-9b93-f2de6f2a48f2"}}`
		mocks := []MockRoute{
			{"PATCH", "/v3/organizations/3b6f763f-aae1-4177-9b93-f2de6f2a48f2/relationships/default_isolation_segment", "", "", 200, "", &defaultIsolationSegmentPayload},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DefaultIsolationSegmentForOrg("3b6f763f-aae1-4177-9b93-f2de6f2a48f2", "3b6f763f-aae1-4177-9b93-f2de6f2a48f2")
		So(err, ShouldBeNil)

	})
}

func TestResetDefaultIsolationSegmentForOrg(t *testing.T) {
	Convey("Reset Default IsolationSegment", t, func() {
		resetIsolationSegmentPayload := `{"data":null}`
		mocks := []MockRoute{
			{"PATCH", "/v3/organizations/3b6f763f-aae1-4177-9b93-f2de6f2a48f2/relationships/default_isolation_segment", "", "", 200, "", &resetIsolationSegmentPayload},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.ResetDefaultIsolationSegmentForOrg("3b6f763f-aae1-4177-9b93-f2de6f2a48f2")
		So(err, ShouldBeNil)

	})
}
