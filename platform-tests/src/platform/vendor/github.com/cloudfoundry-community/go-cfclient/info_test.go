package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetInfo(t *testing.T) {
	Convey("Get info", t, func() {
		setupMultiple(nil, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		info, err := client.GetInfo()
		So(err, ShouldBeNil)

		So(info.MinCLIVersion, ShouldEqual, "6.23.0")
	})
}
