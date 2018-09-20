package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestEnvionmentVariableGroups(t *testing.T) {
	Convey("List Running Environment Variable Group", t, func() {
		setup(MockRoute{"GET", "/v2/config/environment_variable_groups/running", getEVGPayload, "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		evg, err := client.GetRunningEnvironmentVariableGroup()
		So(err, ShouldBeNil)
		So(evg["foo"], ShouldEqual, "bar")
		So(evg["val"], ShouldEqual, 3)
	})

	Convey("List Staging Environment Variable Group", t, func() {
		setup(MockRoute{"GET", "/v2/config/environment_variable_groups/staging", getEVGPayload, "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		evg, err := client.GetStagingEnvironmentVariableGroup()
		So(err, ShouldBeNil)
		So(evg["foo"], ShouldEqual, "bar")
		So(evg["val"], ShouldEqual, 3)
	})

	Convey("Set Running Environment Variable Group", t, func() {
		setup(MockRoute{"PUT", "/v2/config/environment_variable_groups/running", getEVGPayload, "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		body := EnvironmentVariableGroup{
			"foo": "bar",
			"val": 3,
		}

		err = client.SetRunningEnvironmentVariableGroup(body)
		So(err, ShouldBeNil)
	})

	Convey("Set Staging Environment Variable Group", t, func() {
		setup(MockRoute{"PUT", "/v2/config/environment_variable_groups/staging", getEVGPayload, "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		body := EnvironmentVariableGroup{
			"foo": "bar",
			"val": 3,
		}

		err = client.SetStagingEnvironmentVariableGroup(body)
		So(err, ShouldBeNil)
	})
}
