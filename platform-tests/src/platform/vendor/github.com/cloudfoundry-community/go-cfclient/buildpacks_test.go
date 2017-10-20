package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListBuildpacks(t *testing.T) {
	Convey("List buildpack", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/buildpacks", ListBuildpacksPayload, "", 200, "", nil},
			{"GET", "/v2/buildpacksPage2", ListBuildpacksPayload2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpacks, err := client.ListBuildpacks()
		So(err, ShouldBeNil)

		So(len(buildpacks), ShouldEqual, 6)
		So(buildpacks[0].Guid, ShouldEqual, "c92b6f5f-d2a4-413a-b515-647d059723aa")
		So(buildpacks[0].Name, ShouldEqual, "name_1")
	})
}
