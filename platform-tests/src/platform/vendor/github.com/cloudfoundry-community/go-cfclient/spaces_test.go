package cfclient

import (
	"fmt"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListSpaces(t *testing.T) {
	Convey("List Space", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/spaces", listSpacesPayload, "", 200, "", nil},
			{"GET", "/v2/spacesPage2", listSpacesPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaces, err := client.ListSpaces()
		So(err, ShouldBeNil)

		So(len(spaces), ShouldEqual, 4)
		So(spaces[0].Guid, ShouldEqual, "8efd7c5c-d83c-4786-b399-b7bd548839e1")
		So(spaces[0].CreatedAt, ShouldEqual, "2014-09-24T13:54:54+00:00")
		So(spaces[0].UpdatedAt, ShouldEqual, "2014-09-24T13:54:54+00:00")
		So(spaces[0].Name, ShouldEqual, "dev")
		So(spaces[0].OrganizationGuid, ShouldEqual, "a537761f-9d93-4b30-af17-3d73dbca181b")
		So(spaces[1].Guid, ShouldEqual, "657b5923-7de0-486a-9928-b4d78ee24931")
		So(spaces[1].CreatedAt, ShouldEqual, "2014-09-26T13:37:31+00:00")
		So(spaces[1].UpdatedAt, ShouldEqual, "2014-09-26T13:37:31+00:00")
		So(spaces[1].Name, ShouldEqual, "demo")
		So(spaces[1].OrganizationGuid, ShouldEqual, "da0dba14-6064-4f7a-b15a-ff9e677e49b2")
		So(spaces[2].Guid, ShouldEqual, "9ffd7c5c-d83c-4786-b399-b7bd54883977")
		So(spaces[2].CreatedAt, ShouldEqual, "2014-09-24T13:54:54+00:00")
		So(spaces[2].UpdatedAt, ShouldEqual, "2014-09-24T13:54:54+00:00")
		So(spaces[2].Name, ShouldEqual, "test")
		So(spaces[2].OrganizationGuid, ShouldEqual, "a537761f-9d93-4b30-af17-3d73dbca181b")
		So(spaces[3].Guid, ShouldEqual, "329b5923-7de0-486a-9928-b4d78ee24982")
		So(spaces[3].CreatedAt, ShouldEqual, "2014-09-26T13:37:31+00:00")
		So(spaces[3].UpdatedAt, ShouldEqual, "2014-09-26T13:37:31+00:00")
		So(spaces[3].Name, ShouldEqual, "prod")
		So(spaces[3].OrganizationGuid, ShouldEqual, "da0dba14-6064-4f7a-b15a-ff9e677e49b2")
	})
}
func TestListSpaceSecGroups(t *testing.T) {
	Convey("List Space SecGroups", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/security_groups", listSecGroupsPayload, "", 200, "inline-relations-depth=1", nil},
			{"GET", "/v2/security_groupsPage2", listSecGroupsPayloadPage2, "", 200, "", nil},
			{"GET", "/v2/security_groups/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/spaces", emptyResources, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		secGroups, err := client.ListSpaceSecGroups("8efd7c5c-d83c-4786-b399-b7bd548839e1")
		So(err, ShouldBeNil)

		So(len(secGroups), ShouldEqual, 2)
		So(secGroups[0].Guid, ShouldEqual, "af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c")
		So(secGroups[0].Name, ShouldEqual, "secgroup-test")
		So(secGroups[0].Running, ShouldEqual, true)
		So(secGroups[0].Staging, ShouldEqual, true)
		So(secGroups[0].Rules[0].Protocol, ShouldEqual, "tcp")
		So(secGroups[0].Rules[0].Ports, ShouldEqual, "443,4443")
		So(secGroups[0].Rules[0].Destination, ShouldEqual, "1.1.1.1")
		So(secGroups[0].Rules[1].Protocol, ShouldEqual, "udp")
		So(secGroups[0].Rules[1].Ports, ShouldEqual, "1111")
		So(secGroups[0].Rules[1].Destination, ShouldEqual, "1.2.3.4")
		So(secGroups[0].SpacesURL, ShouldEqual, "/v2/security_groups/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/spaces")
		So(secGroups[0].SpacesData, ShouldBeEmpty)
		So(secGroups[1].Guid, ShouldEqual, "f9ad202b-76dd-44ec-b7c2-fd2417a561e8")
		So(secGroups[1].Name, ShouldEqual, "secgroup-test2")
		So(secGroups[1].Running, ShouldEqual, false)
		So(secGroups[1].Staging, ShouldEqual, false)
		So(secGroups[1].Rules[0].Protocol, ShouldEqual, "udp")
		So(secGroups[1].Rules[0].Ports, ShouldEqual, "2222")
		So(secGroups[1].Rules[0].Destination, ShouldEqual, "2.2.2.2")
		So(secGroups[1].Rules[1].Protocol, ShouldEqual, "tcp")
		So(secGroups[1].Rules[1].Ports, ShouldEqual, "443,4443")
		So(secGroups[1].Rules[1].Destination, ShouldEqual, "4.3.2.1")
		So(secGroups[1].SpacesData[0].Entity.Guid, ShouldEqual, "e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4")
		So(secGroups[1].SpacesData[0].Entity.Name, ShouldEqual, "space-test")
		So(secGroups[1].SpacesData[1].Entity.Guid, ShouldEqual, "a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333")
		So(secGroups[1].SpacesData[1].Entity.Name, ShouldEqual, "space-test2")
		So(secGroups[1].SpacesData[2].Entity.Guid, ShouldEqual, "c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1")
		So(secGroups[1].SpacesData[2].Entity.Name, ShouldEqual, "space-test3")
	})
}
func TestListSpaceManagers(t *testing.T) {
	Convey("ListSpaceManagers()", t, func() {
		setup(MockRoute{"GET", "/v2/spaces/foo/managers", listSpacePeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		users, err := client.ListSpaceManagers("foo")
		So(err, ShouldBeNil)
		So(len(users), ShouldEqual, 2)
		So(users[0].Username, ShouldEqual, "user1")
		So(users[1].Username, ShouldEqual, "user2")
	})
}
func TestListSpaceAuditors(t *testing.T) {
	Convey("ListSpaceAuditors()", t, func() {
		setup(MockRoute{"GET", "/v2/spaces/foo/auditors", listSpacePeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		users, err := client.ListSpaceAuditors("foo")
		So(err, ShouldBeNil)
		So(len(users), ShouldEqual, 2)
		So(users[0].Username, ShouldEqual, "user1")
		So(users[1].Username, ShouldEqual, "user2")
	})
}
func TestListSpaceDevelopers(t *testing.T) {
	Convey("ListSpaceDevelopers()", t, func() {
		setup(MockRoute{"GET", "/v2/spaces/foo/developers", listSpacePeoplePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		users, err := client.ListSpaceDevelopers("foo")
		So(err, ShouldBeNil)
		So(len(users), ShouldEqual, 2)
		So(users[0].Username, ShouldEqual, "user1")
		So(users[1].Username, ShouldEqual, "user2")
	})
}

func TestCreateSpace(t *testing.T) {
	Convey("Create Space", t, func() {
		setup(MockRoute{"POST", "/v2/spaces", spacePayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaceRequest := SpaceRequest{Name: "test-space", OrganizationGuid: "da0dba14-6064-4f7a-b15a-ff9e677e49b2", AllowSSH: false}

		space, err := client.CreateSpace(spaceRequest)
		So(err, ShouldBeNil)

		So(space.Name, ShouldEqual, "test-space")
		So(space.OrganizationGuid, ShouldEqual, "da0dba14-6064-4f7a-b15a-ff9e677e49b2")
		So(space.AllowSSH, ShouldEqual, false)
	})
}

func TestUpdateSpace(t *testing.T) {
	Convey("Update Space", t, func() {
		setup(MockRoute{"PUT", "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73", spacePayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		updateSpaceRequest := SpaceRequest{
			Name:     "test-space",
			AllowSSH: false,
		}

		space, err := client.UpdateSpace("a72fa1e8-c694-47b3-85f2-55f61fd00d73", updateSpaceRequest)
		So(err, ShouldBeNil)

		So(space.Guid, ShouldEqual, "a72fa1e8-c694-47b3-85f2-55f61fd00d73")
		So(space.Name, ShouldEqual, "test-space")
		So(space.OrganizationGuid, ShouldEqual, "da0dba14-6064-4f7a-b15a-ff9e677e49b2")
		So(space.AllowSSH, ShouldEqual, false)
	})
}

func TestDeleteSpace(t *testing.T) {
	Convey("Delete space", t, func() {
		setup(MockRoute{"DELETE", "/v2/spaces/a537761f-9d93-4b30-af17-3d73dbca181b", "", "", 204, "recursive=false&async=false", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteSpace("a537761f-9d93-4b30-af17-3d73dbca181b", false, false)
		So(err, ShouldBeNil)
	})
}
func TestSpaceOrg(t *testing.T) {
	Convey("Find space org", t, func() {
		setup(MockRoute{"GET", "/v2/org/foobar", orgPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid:   "123",
			Name:   "test space",
			OrgURL: "/v2/org/foobar",
			c:      client,
		}
		org, err := space.Org()
		So(err, ShouldBeNil)

		So(org.Name, ShouldEqual, "test-org")
		So(org.Guid, ShouldEqual, "da0dba14-6064-4f7a-b15a-ff9e677e49b2")
	})
}

func TestSpaceQuota(t *testing.T) {
	Convey("Get space quota", t, func() {
		setup(MockRoute{"GET", "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977", spaceQuotaPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			QuotaDefinitionGuid: "9ffd7c5c-d83c-4786-b399-b7bd54883977",
			c:                   client,
		}

		spaceQuota, err := space.Quota()
		So(err, ShouldBeNil)

		So(spaceQuota.Guid, ShouldEqual, "9ffd7c5c-d83c-4786-b399-b7bd54883977")
		So(spaceQuota.Name, ShouldEqual, "test-2")
		So(spaceQuota.NonBasicServicesAllowed, ShouldEqual, false)
		So(spaceQuota.TotalServices, ShouldEqual, 10)
		So(spaceQuota.TotalRoutes, ShouldEqual, 20)
		So(spaceQuota.MemoryLimit, ShouldEqual, 30)
		So(spaceQuota.InstanceMemoryLimit, ShouldEqual, 40)
		So(spaceQuota.AppInstanceLimit, ShouldEqual, 50)
		So(spaceQuota.AppTaskLimit, ShouldEqual, 60)
		So(spaceQuota.TotalServiceKeys, ShouldEqual, 70)
		So(spaceQuota.TotalReservedRoutePorts, ShouldEqual, 80)
	})
}

func TestSpaceSummary(t *testing.T) {
	Convey("Get space summary", t, func() {
		setup(MockRoute{"GET", "/v2/spaces/494d8b64-8181-4183-a6d3-6279db8fec6e/summary", spaceSummaryPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "494d8b64-8181-4183-a6d3-6279db8fec6e",
			c:    client,
		}

		summary, err := space.Summary()
		So(err, ShouldBeNil)

		So(summary.Guid, ShouldEqual, "494d8b64-8181-4183-a6d3-6279db8fec6e")
		So(summary.Name, ShouldEqual, "test")

		So(len(summary.Apps), ShouldEqual, 1)
		So(summary.Apps[0].Guid, ShouldEqual, "b5f0d1bd-a3a9-40a4-af1a-312ad26e5379")
		So(summary.Apps[0].Name, ShouldEqual, "test-app")
		So(summary.Apps[0].ServiceCount, ShouldEqual, 1)
		So(summary.Apps[0].RunningInstances, ShouldEqual, 1)
		So(summary.Apps[0].SpaceGuid, ShouldEqual, "494d8b64-8181-4183-a6d3-6279db8fec6e")
		So(summary.Apps[0].StackGuid, ShouldEqual, "67e019a3-322a-407a-96e0-178e95bd0e55")
		So(summary.Apps[0].Buildpack, ShouldEqual, "ruby_buildpack")
		So(summary.Apps[0].DetectedBuildpack, ShouldEqual, "")
		So(summary.Apps[0].Memory, ShouldEqual, 256)
		So(summary.Apps[0].Instances, ShouldEqual, 1)
		So(summary.Apps[0].DiskQuota, ShouldEqual, 512)
		So(summary.Apps[0].State, ShouldEqual, "STARTED")
		So(summary.Apps[0].Command, ShouldEqual, "")
		So(summary.Apps[0].PackageState, ShouldEqual, "STAGED")
		So(summary.Apps[0].HealthCheckType, ShouldEqual, "port")
		So(summary.Apps[0].HealthCheckTimeout, ShouldEqual, 0)
		So(summary.Apps[0].StagingFailedReason, ShouldEqual, "")
		So(summary.Apps[0].StagingFailedDescription, ShouldEqual, "")
		So(summary.Apps[0].Diego, ShouldEqual, true)
		So(summary.Apps[0].DockerImage, ShouldEqual, "")
		So(summary.Apps[0].DetectedStartCommand, ShouldEqual, "rackup -p $PORT")
		So(summary.Apps[0].EnableSSH, ShouldEqual, true)
		So(summary.Apps[0].DockerCredentials["redacted_message"], ShouldEqual, "[PRIVATE DATA HIDDEN]")

		So(len(summary.Services), ShouldEqual, 1)
		So(summary.Services[0].Guid, ShouldEqual, "3c5c758c-6b76-46f6-89d5-677909bfc975")
		So(summary.Services[0].Name, ShouldEqual, "test-service")
		So(summary.Services[0].BoundAppCount, ShouldEqual, 1)
	})
}

func TestSpaceRoles(t *testing.T) {
	Convey("Get space roles", t, func() {
		setup(MockRoute{"GET", "/v2/spaces/494d8b64-8181-4183-a6d3-6279db8fec6e/user_roles", spaceRolesPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "494d8b64-8181-4183-a6d3-6279db8fec6e",
			c:    client,
		}

		roles, err := space.Roles()
		So(err, ShouldBeNil)

		So(len(roles), ShouldEqual, 1)
		So(roles[0].Guid, ShouldEqual, "uaa-id-363")
		So(roles[0].Admin, ShouldEqual, false)
		So(roles[0].Active, ShouldEqual, false)
		So(roles[0].DefaultSpaceGuid, ShouldEqual, "")
		So(roles[0].Username, ShouldEqual, "everything@example.com")
		So(roles[0].SpaceRoles, ShouldResemble, []string{"space_developer", "space_manager", "space_auditor"})
		So(roles[0].SpacesUrl, ShouldEqual, "/v2/users/uaa-id-363/spaces")
		So(roles[0].OrganizationsUrl, ShouldEqual, "/v2/users/uaa-id-363/organizations")
		So(roles[0].ManagedOrganizationsUrl, ShouldEqual, "/v2/users/uaa-id-363/managed_organizations")
		So(roles[0].BillingManagedOrganizationsUrl, ShouldEqual, "/v2/users/uaa-id-363/billing_managed_organizations")
		So(roles[0].AuditedOrganizationsUrl, ShouldEqual, "/v2/users/uaa-id-363/audited_organizations")
		So(roles[0].ManagedSpacesUrl, ShouldEqual, "/v2/users/uaa-id-363/managed_spaces")
		So(roles[0].AuditedSpacesUrl, ShouldEqual, "/v2/users/uaa-id-363/audited_spaces")
	})
}

func TestAssociateSpaceAuditorByUsername(t *testing.T) {
	Convey("Associate auditor by username", t, func() {
		setup(MockRoute{"PUT", "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors", associateSpaceUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newSpace, err := space.AssociateAuditorByUsername("user-name")
		So(err, ShouldBeNil)
		So(newSpace.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateSpaceDeveloperByUsername(t *testing.T) {
	Convey("Associate developer by username", t, func() {
		setup(MockRoute{"PUT", "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56/developers", associateSpaceUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newSpace, err := space.AssociateDeveloperByUsername("user-name")
		So(err, ShouldBeNil)
		So(newSpace.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestAssociateSpaceManagerByUsername(t *testing.T) {
	Convey("Associate manager by username", t, func() {
		setup(MockRoute{"PUT", "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers", associateSpaceUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		newSpace, err := space.AssociateManagerByUsername("user-name")
		So(err, ShouldBeNil)
		So(newSpace.Guid, ShouldEqual, "bc7b4caf-f4b8-4d85-b126-0729b9351e56")
	})
}

func TestRemoveSpaceDeveloperByUsername(t *testing.T) {
	Convey("Remove developer by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56/developers", "", "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = space.RemoveDeveloperByUsername("user-name")
		So(err, ShouldBeNil)
	})
}
func TestRemoveSpaceAuditorByUsername(t *testing.T) {
	Convey("Remove auditor by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors", "", "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = space.RemoveAuditorByUsername("user-name")
		So(err, ShouldBeNil)
	})
}

func TestRemoveSpaceManagerByUsername(t *testing.T) {
	Convey("Remove manager by username", t, func() {
		setup(MockRoute{"DELETE", "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers", "", "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
			c:    client,
		}

		err = space.RemoveManagerByUsername("user-name")
		So(err, ShouldBeNil)
	})
}

func TestGetSpaceByGuid(t *testing.T) {
	Convey("List Space", t, func() {
		setup(MockRoute{"GET", "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1", spaceByGuidPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space, err := client.GetSpaceByGuid("8efd7c5c-d83c-4786-b399-b7bd548839e1")
		So(err, ShouldBeNil)

		So(space.Guid, ShouldEqual, "8efd7c5c-d83c-4786-b399-b7bd548839e1")
		So(space.Name, ShouldEqual, "dev")
	})
}

func TestGetSpaceServiceOfferings(t *testing.T) {
	guid := `8efd7c5c-d83c-4786-b399-b7bd548839e1`
	Convey("Get service offerings for space", t, func() {
		setup(MockRoute{
			Method:      "GET",
			Endpoint:    fmt.Sprintf("/v2/spaces/%s/services", guid),
			Output:      spaceServiceOfferingsPayload,
			UserAgent:   "",
			Status:      200,
			QueryString: "",
			PostForm:    nil,
		}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		space := &Space{
			Guid: guid,
			c:    client,
		}

		offerings, err := space.GetServiceOfferings()
		So(offerings, ShouldNotBeEmpty)
		So(err, ShouldBeNil)
	})
}

func TestIsolationSegmentForSpace(t *testing.T) {
	Convey("set Default IsolationSegment", t, func() {
		defaultIsolationSegmentPayload := `{"data":{"guid":"3b6f763f-aae1-4177-9b93-f2de6f2a48f2"}}`
		mocks := []MockRoute{
			{"PATCH", "/v3/spaces/3b6f763f-aae1-4177-9b93-f2de6f2a48f2/relationships/isolation_segment", "", "", 200, "", &defaultIsolationSegmentPayload},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.IsolationSegmentForSpace("3b6f763f-aae1-4177-9b93-f2de6f2a48f2", "3b6f763f-aae1-4177-9b93-f2de6f2a48f2")
		So(err, ShouldBeNil)

	})
}

func TestResetIsolationSegmentForSpace(t *testing.T) {
	Convey("Reset IsolationSegment", t, func() {
		resetIsolationSegmentPayload := `{"data":null}`
		mocks := []MockRoute{
			{"PATCH", "/v3/spaces/3b6f763f-aae1-4177-9b93-f2de6f2a48f2/relationships/isolation_segment", "", "", 200, "", &resetIsolationSegmentPayload},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.ResetIsolationSegmentForSpace("3b6f763f-aae1-4177-9b93-f2de6f2a48f2")
		So(err, ShouldBeNil)

	})
}
