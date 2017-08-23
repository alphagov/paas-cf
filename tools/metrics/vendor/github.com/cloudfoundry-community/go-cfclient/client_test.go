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

func TestTokenRefresh(t *testing.T) {
	gomega.RegisterTestingT(t)
	Convey("Test making request", t, func() {
		setup(MockRoute{"GET", "/v2/organizations", listOrgsPayload, "", 200, "", nil}, t)
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
		// gomega.Eventually(client.GetToken(), "3s").Should(gomega.Equal("bearer foobar3"))
	})
}
