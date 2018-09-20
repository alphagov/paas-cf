package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestUpdateApp(t *testing.T) {
	Convey("Update app", t, func() {
		setup(MockRoute{"PUT", "/v2/apps/97f7e56b-addf-4d26-be82-998a06600011", AppUpdatePayload, "", 201, "", nil}, t)
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)
		aur := AppUpdateResource{Name: "NewName", DiskQuota: 1024, Instances: 1, Memory: 65}
		ret, err := client.UpdateApp("97f7e56b-addf-4d26-be82-998a06600011", aur)
		So(err, ShouldBeNil)
		So(ret.Entity.Memory, ShouldEqual, 65)
		So(ret.Entity.Instances, ShouldEqual, 1)
		So(ret.Entity.DiskQuota, ShouldEqual, 1024)
		So(ret.Entity.Name, ShouldEqual, "NewName")
	})
}
