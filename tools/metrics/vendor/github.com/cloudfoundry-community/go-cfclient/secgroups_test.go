package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListSecGroups(t *testing.T) {
	Convey("List SecGroups", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/security_groups", listSecGroupsPayload, "", 200, "inline-relations-depth=1", nil},
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

		secGroups, err := client.ListSecGroups()
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

func TestSecGroupListSpaceResources(t *testing.T) {
	Convey("List Space Resources", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/security_groups/123/spaces", listSpacesPayload, "", 200, "", nil},
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

		secGroup := &SecGroup{
			Guid:      "123",
			Name:      "test-sec-group",
			SpacesURL: "/v2/security_groups/123/spaces",
			c:         client,
		}
		spaces, err := secGroup.ListSpaceResources()
		So(err, ShouldBeNil)

		So(len(spaces), ShouldEqual, 4)
		So(spaces[0].Entity.Guid, ShouldEqual, "8efd7c5c-d83c-4786-b399-b7bd548839e1")
		So(spaces[0].Entity.Name, ShouldEqual, "dev")
		So(spaces[1].Entity.Guid, ShouldEqual, "657b5923-7de0-486a-9928-b4d78ee24931")
		So(spaces[1].Entity.Name, ShouldEqual, "demo")
		So(spaces[2].Entity.Guid, ShouldEqual, "9ffd7c5c-d83c-4786-b399-b7bd54883977")
		So(spaces[2].Entity.Name, ShouldEqual, "test")
		So(spaces[3].Entity.Guid, ShouldEqual, "329b5923-7de0-486a-9928-b4d78ee24982")
		So(spaces[3].Entity.Name, ShouldEqual, "prod")
	})
}
