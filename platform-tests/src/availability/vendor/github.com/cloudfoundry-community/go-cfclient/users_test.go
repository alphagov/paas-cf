package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListUsers(t *testing.T) {
	Convey("List Users", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users", listUsersPayload, "", 200, "", nil},
			{"GET", "/v2/usersPage2", listUsersPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		users, err := client.ListUsers()
		So(err, ShouldBeNil)

		So(len(users), ShouldEqual, 4)
		So(users[0].Guid, ShouldEqual, "ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac")
		So(users[0].Username, ShouldEqual, "testUser1")
		So(users[1].Guid, ShouldEqual, "f97f5699-c920-4633-aa23-bd70f3db0808")
		So(users[1].Username, ShouldEqual, "testUser2")
		So(users[2].Guid, ShouldEqual, "cadd6389-fcf6-4928-84f0-6153556bf693")
		So(users[2].Username, ShouldEqual, "testUser3")
		So(users[3].Guid, ShouldEqual, "79c854b0-c12a-41b7-8d3c-fdd6e116e385")
		So(users[3].Username, ShouldEqual, "testUser4")
	})
}

func TestListUserSpaces(t *testing.T) {
	Convey("List User Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/spaces", listUserSpacesPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaces, err := client.ListUserSpaces("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(spaces), ShouldEqual, 1)
		So(spaces[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(spaces[0].Name, ShouldEqual, "dev")
		So(spaces[0].OrganizationGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func TestListUserManagedSpaces(t *testing.T) {
	Convey("List User Audited Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/managed_spaces", listUserSpacesPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaces, err := client.ListUserManagedSpaces("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(spaces), ShouldEqual, 1)
		So(spaces[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(spaces[0].Name, ShouldEqual, "dev")
		So(spaces[0].OrganizationGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func TestListUserAuditedSpaces(t *testing.T) {
	Convey("List User Managed Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/audited_spaces", listUserSpacesPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaces, err := client.ListUserAuditedSpaces("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(spaces), ShouldEqual, 1)
		So(spaces[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(spaces[0].Name, ShouldEqual, "dev")
		So(spaces[0].OrganizationGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func TestListUserOrgs(t *testing.T) {
	Convey("List User Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/organizations", listUserOrgsPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgs, err := client.ListUserOrgs("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(orgs), ShouldEqual, 1)
		So(orgs[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(orgs[0].Name, ShouldEqual, "dev")
		So(orgs[0].QuotaDefinitionGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func TestListUserManagedOrgs(t *testing.T) {
	Convey("List User Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/managed_organizations", listUserOrgsPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgs, err := client.ListUserManagedOrgs("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(orgs), ShouldEqual, 1)
		So(orgs[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(orgs[0].Name, ShouldEqual, "dev")
		So(orgs[0].QuotaDefinitionGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func ListUserAuditedOrgs(t *testing.T) {
	Convey("List User Audited Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/audited_organizations", listUserOrgsPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgs, err := client.ListUserAuditedOrgs("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(orgs), ShouldEqual, 1)
		So(orgs[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(orgs[0].Name, ShouldEqual, "dev")
		So(orgs[0].QuotaDefinitionGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func TestUserBillingManagedOrgs(t *testing.T) {
	Convey("List User Managed Spaces", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/billing_managed_organizations", listUserOrgsPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgs, err := client.ListUserBillingManagedOrgs("cadd6389-fcf6-4928-84f0-6153556bf693")
		So(err, ShouldBeNil)

		So(len(orgs), ShouldEqual, 1)
		So(orgs[0].Guid, ShouldEqual, "9881c79e-d269-4a53-9d77-cb21b745356e")
		So(orgs[0].Name, ShouldEqual, "dev")
		So(orgs[0].QuotaDefinitionGuid, ShouldEqual, "6a2a2d18-7620-43cf-a332-353824b431b2")
	})
}

func TestGetUserByUsername(t *testing.T) {
	Convey("Get User by Username", t, func() {
		user1 := User{Guid: "ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac", Username: "testUser1"}
		user2 := User{Guid: "f97f5699-c920-4633-aa23-bd70f3db0808", Username: "testUser2"}
		user3 := User{Guid: "cadd6389-fcf6-4928-84f0-6153556bf693", Username: "testUser3"}
		user4 := User{Guid: "79c854b0-c12a-41b7-8d3c-fdd6e116e385", Username: "testUser4"}
		users := Users{user1, user2, user3, user4}

		So(users.GetUserByUsername("testUser1"), ShouldResemble, user1)
		So(users.GetUserByUsername("testUser2"), ShouldResemble, user2)
		So(users.GetUserByUsername("testUser3"), ShouldResemble, user3)
		So(users.GetUserByUsername("testUser4"), ShouldResemble, user4)
	})
}

func TestCreateUser(t *testing.T) {
	Convey("Create user", t, func() {
		setup(MockRoute{"POST", "/v2/users", createUserPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		user, err := client.CreateUser(UserRequest{Guid: "guid-cb24b36d-4656-468e-a50d-b53113ac6177"})
		So(err, ShouldBeNil)
		So(user.Guid, ShouldEqual, "guid-cb24b36d-4656-468e-a50d-b53113ac6177")
	})
}

func TestDeleteUser(t *testing.T) {
	Convey("Delete user", t, func() {
		setup(MockRoute{"DELETE", "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteUser("guid-cb24b36d-4656-468e-a50d-b53113ac6177")
		So(err, ShouldBeNil)
	})
}
