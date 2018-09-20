package cfclient

import (
	"bytes"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListBuildpacks(t *testing.T) {
	Convey("List buildpack", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/buildpacks", listBuildpacksPayload, "", 200, "", nil},
			{"GET", "/v2/buildpacksPage2", listBuildpacksPayload2, "", 200, "", nil},
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
		So(buildpacks[0].CreatedAt, ShouldEqual, "2016-06-08T16:41:31Z")
		So(buildpacks[0].UpdatedAt, ShouldEqual, "2016-06-08T16:41:26Z")
		So(buildpacks[0].Name, ShouldEqual, "name_1")
	})
}

func TestGetBuildpackByGuid(t *testing.T) {
	Convey("A buildpack", t, func() {
		setup(MockRoute{"GET", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa", buildpackPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpack, err := client.GetBuildpackByGuid("c92b6f5f-d2a4-413a-b515-647d059723aa")
		So(err, ShouldBeNil)

		So(buildpack.Guid, ShouldEqual, "c92b6f5f-d2a4-413a-b515-647d059723aa")
		So(buildpack.CreatedAt, ShouldEqual, "2016-06-08T16:41:31Z")
		So(buildpack.UpdatedAt, ShouldEqual, "2016-06-08T16:41:26Z")
		So(buildpack.Name, ShouldEqual, "name_1")
	})
}

func TestUploadBuildpack(t *testing.T) {
	Convey("Uploading a buildpack succeeds", t, func() {
		expectedPayload := "this should really be zipped binary data"
		setup(MockRoute{"PUT-FILE", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa/bits", buildpackUploadPayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		bits := bytes.NewBufferString(expectedPayload)
		buildpack := Buildpack{Guid: "c92b6f5f-d2a4-413a-b515-647d059723aa", c: client}
		err = buildpack.Upload(bits, "test.zip")
		So(err, ShouldBeNil)
	})
	Convey("Uploading a buildpack throws an error in the event of failure", t, func() {
		expectedPayload := "this should really be zipped binary data"
		setup(MockRoute{"PUT-FILE", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa/bits", buildpackUploadPayload, "", 400, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		bits := bytes.NewBufferString(expectedPayload)
		buildpack := Buildpack{Guid: "c92b6f5f-d2a4-413a-b515-647d059723aa", c: client}
		err = buildpack.Upload(bits, "test.zip")
		So(err, ShouldNotBeNil)
	})
}

func TestUpdateBuildpack(t *testing.T) {
	Convey("Updating a buildpack succeeds", t, func() {
		expectedPayload := `{"name":"renamed-buildpack","enabled":true,"locked":true,"position":100}`
		setup(MockRoute{"PUT", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa", buildpackUpdatePayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpack := Buildpack{
			Guid: "c92b6f5f-d2a4-413a-b515-647d059723aa",
			c:    client,
		}
		buildpackRequest := &BuildpackRequest{}
		buildpackRequest.SetName("renamed-buildpack")
		buildpackRequest.Lock()
		buildpackRequest.Enable()
		buildpackRequest.SetPosition(100)

		err = buildpack.Update(buildpackRequest)
		So(err, ShouldBeNil)
	})
	Convey("Updating a buildpack doesn't accidentally unlock, rename, disable, or reorder the buildpack", t, func() {
		expectedPayload := `{}`
		setup(MockRoute{"PUT", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa", buildpackUpdatePayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpack := Buildpack{
			Guid: "c92b6f5f-d2a4-413a-b515-647d059723aa",
			c:    client,
		}
		buildpackRequest := &BuildpackRequest{}

		err = buildpack.Update(buildpackRequest)
		So(err, ShouldBeNil)
	})
	Convey("Unlocking, disabling, reordering to 0, and removing name from buildpacks is still possible", t, func() {
		expectedPayload := `{"name":"","enabled":false,"locked":false,"position":0}`
		setup(MockRoute{"PUT", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa", buildpackUpdatePayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpack := Buildpack{
			Guid: "c92b6f5f-d2a4-413a-b515-647d059723aa",
			c:    client,
		}
		buildpackRequest := &BuildpackRequest{}
		buildpackRequest.SetName("")
		buildpackRequest.Unlock()
		buildpackRequest.Disable()
		buildpackRequest.SetPosition(0)

		err = buildpack.Update(buildpackRequest)
		So(err, ShouldBeNil)
	})
	Convey("Updating a buildpack returns an error in the event of failure", t, func() {
		expectedPayload := `{}`
		setup(MockRoute{"PUT", "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa", buildpackUpdatePayload, "", 400, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpack := Buildpack{
			Guid: "c92b6f5f-d2a4-413a-b515-647d059723aa",
			c:    client,
		}

		buildpackRequest := &BuildpackRequest{}

		err = buildpack.Update(buildpackRequest)
		So(err, ShouldNotBeNil)
	})
}

func TestCreateBuildpack(t *testing.T) {
	Convey("Creating a buildpack succeeds", t, func() {
		expectedPayload := `{"name":"test-buildpack","enabled":true,"locked":true,"position":10}`
		setup(MockRoute{"POST", "/v2/buildpacks", buildpackCreatePayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpackRequest := &BuildpackRequest{}
		buildpackRequest.SetName("test-buildpack")
		buildpackRequest.Lock()
		buildpackRequest.Enable()
		buildpackRequest.SetPosition(10)

		bp, err := client.CreateBuildpack(buildpackRequest)
		So(err, ShouldBeNil)
		So(bp.Guid, ShouldEqual, "c92b6f5f-d2a4-413a-b515-647d059723aa")
		So(bp.Name, ShouldEqual, "test-buildpack")
		So(bp.Enabled, ShouldBeTrue)
		So(bp.Locked, ShouldBeFalse)
		So(bp.Position, ShouldEqual, 10)
	})
	Convey("Creating a buildpack doesn't accidentally unlock, rename, disable, or reorder the buildpack", t, func() {
		expectedPayload := `{"name":"test-buildpack"}`
		setup(MockRoute{"POST", "/v2/buildpacks", buildpackCreatePayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpackRequest := &BuildpackRequest{}
		buildpackRequest.SetName("test-buildpack")

		bp, err := client.CreateBuildpack(buildpackRequest)
		So(err, ShouldBeNil)
		So(bp, ShouldNotBeNil)
	})
	Convey("Creating a buildpack as unlocked/disabled/order 0 works", t, func() {
		expectedPayload := `{"name":"test-buildpack","enabled":false,"locked":false,"position":0}`
		setup(MockRoute{"POST", "/v2/buildpacks", buildpackCreatePayload, "", 200, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpackRequest := &BuildpackRequest{}
		buildpackRequest.SetName("test-buildpack")
		buildpackRequest.Unlock()
		buildpackRequest.Disable()
		buildpackRequest.SetPosition(0)

		bp, err := client.CreateBuildpack(buildpackRequest)
		So(err, ShouldBeNil)
		So(bp, ShouldNotBeNil)
	})
	Convey("Creating a buildpack returns an error in the event of failure", t, func() {
		expectedPayload := `{"name":"test-buildpack"}`
		setup(MockRoute{"POST", "/v2/buildpacks", buildpackCreatePayload, "", 400, "", &expectedPayload}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpackRequest := &BuildpackRequest{}
		buildpackRequest.SetName("test-buildpack")

		bp, err := client.CreateBuildpack(buildpackRequest)
		So(err, ShouldNotBeNil)
		So(bp, ShouldBeNil)
	})
	Convey("Creating a buildpack fails if the request has no name set", t, func() {
		setup(MockRoute{"POST", "/v2/buildpacks", buildpackCreatePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		buildpackRequest := &BuildpackRequest{}
		bp, err := client.CreateBuildpack(buildpackRequest)
		So(err, ShouldNotBeNil)
		So(bp, ShouldBeNil)
	})
}

func TestDeleteBuildpack(t *testing.T) {
	Convey("Delete buildpack synchronously", t, func() {
		setup(MockRoute{"DELETE", "/v2/buildpacks/b2a35f0c-d5ad-4a59-bea7-461711d96b0d", "", "", 204, "async=false", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteBuildpack("b2a35f0c-d5ad-4a59-bea7-461711d96b0d", false)
		So(err, ShouldBeNil)
	})

	Convey("Delete buildpack asynchronously", t, func() {
		setup(MockRoute{"DELETE", "/v2/buildpacks/b2a35f0c-d5ad-4a59-bea7-461711d96b0d", "", "", 202, "async=true", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteBuildpack("b2a35f0c-d5ad-4a59-bea7-461711d96b0d", true)
		So(err, ShouldBeNil)
	})
}
