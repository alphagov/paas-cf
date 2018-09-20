package cfclient

import (
	"net/http"
	"testing"
	"time"

	"github.com/onsi/gomega"
	. "github.com/smartystreets/goconvey/convey"
)

func TestDefaultConfig(t *testing.T) {
	Convey("Default config", t, func() {
		c := DefaultConfig()
		So(c.ApiAddress, ShouldEqual, "http://api.bosh-lite.com")
		So(c.Username, ShouldEqual, "admin")
		So(c.Password, ShouldEqual, "admin")
		So(c.SkipSslValidation, ShouldEqual, false)
		So(c.Token, ShouldEqual, "")
		So(c.UserAgent, ShouldEqual, "Go-CF-client/1.1")
	})
}

func TestRemovalofTrailingSlashOnAPIAddress(t *testing.T) {
	Convey("Test removal of trailing slash of the API Address", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL + "/",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)
		So(client.Config.ApiAddress, ShouldNotEndWith, "/")
	})
}

func TestMakeRequest(t *testing.T) {
	Convey("Test making request b", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress:        server.URL,
			Username:          "foo",
			Password:          "bar",
			SkipSslValidation: true,
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)
		req := client.NewRequest("GET", "/v2/organizations")
		resp, err := client.DoRequest(req)
		So(err, ShouldBeNil)
		So(resp, ShouldNotBeNil)
	})
}

func TestMakeRequestFailure(t *testing.T) {
	Convey("Test making request b", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress:        server.URL,
			Username:          "foo",
			Password:          "bar",
			SkipSslValidation: true,
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)
		req := client.NewRequest("GET", "/v2/organizations")
		req.url = "%gh&%ij"
		resp, err := client.DoRequest(req)
		So(resp, ShouldBeNil)
		So(err, ShouldNotBeNil)
	})
}

func TestMakeRequestWithTimeout(t *testing.T) {
	Convey("Test making request b", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress:        server.URL,
			Username:          "foo",
			Password:          "bar",
			SkipSslValidation: true,
			HttpClient:        &http.Client{Timeout: 10 * time.Nanosecond},
		}
		client, err := NewClient(c)
		So(err, ShouldNotBeNil)
		So(client, ShouldBeNil)
	})
}

func TestHTTPErrorHandling(t *testing.T) {
	Convey("Test making request b", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", "502 Bad Gateway", "", 502, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress:        server.URL,
			Username:          "foo",
			Password:          "bar",
			SkipSslValidation: true,
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)
		req := client.NewRequest("GET", "/v2/organizations")
		resp, err := client.DoRequest(req)
		So(err, ShouldNotBeNil)
		So(resp, ShouldNotBeNil)

		httpErr := err.(CloudFoundryHTTPError)
		So(httpErr.StatusCode, ShouldEqual, 502)
		So(httpErr.Status, ShouldEqual, "502 Bad Gateway")
		So(string(httpErr.Body), ShouldEqual, "502 Bad Gateway")
	})
}

func TestTokenRefresh(t *testing.T) {
	gomega.RegisterTestingT(t)
	Convey("Test making request", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
		fakeUAAServer = FakeUAAServer(1)
		c := &Config{
			ApiAddress: server.URL,
			Username:   "foo",
			Password:   "bar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		token, err := client.GetToken()
		So(err, ShouldBeNil)

		gomega.Consistently(token).Should(gomega.Equal("bearer foobar2"))
		gomega.Eventually(func() string { token, _ := client.GetToken(); return token }, "2s").Should(gomega.Equal("bearer foobar3"))
	})
}

func TestEndpointRefresh(t *testing.T) {
	gomega.RegisterTestingT(t)
	Convey("Test expiring endpoint", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
		fakeUAAServer = FakeUAAServer(0)

		c := &Config{
			ApiAddress: server.URL,
			Username:   "foo",
			Password:   "bar",
		}

		client, err := NewClient(c)
		So(err, ShouldBeNil)

		lastTokenSource := client.Config.TokenSource
		for i := 1; i < 5; i++ {
			_, err := client.GetToken()
			So(err, ShouldBeNil)
			So(client.Config.TokenSource, ShouldNotEqual, lastTokenSource)
			lastTokenSource = client.Config.TokenSource
		}
	})
}
