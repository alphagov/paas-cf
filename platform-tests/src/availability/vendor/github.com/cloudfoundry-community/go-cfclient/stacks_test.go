package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListStacks(t *testing.T) {
	Convey("List Stacks", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/stacks", listStacksPayloadPage1, "", 200, "", nil},
			{"GET", "/v2/stacks_page_2", listStacksPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		stacks, err := client.ListStacks()
		So(err, ShouldBeNil)

		So(len(stacks), ShouldEqual, 2)
		So(stacks[0].Guid, ShouldEqual, "67e019a3-322a-407a-96e0-178e95bd0e55")
		So(stacks[0].Name, ShouldEqual, "cflinuxfs2")
		So(stacks[0].Description, ShouldEqual, "Cloud Foundry Linux-based filesystem")
	})
}
