package cfclient

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"testing"

	_ "github.com/onsi/gomega"

	"github.com/go-martini/martini"
	"github.com/martini-contrib/render"
)

var (
	mux           *http.ServeMux
	server        *httptest.Server
	fakeUAAServer *httptest.Server
)

type MockRoute struct {
	Method      string
	Endpoint    string
	Output      string
	UserAgent   string
	Status      int
	QueryString string
	PostForm    *string
}

type MockRouteWithRedirect struct {
	MockRoute
	RedirectLocation string
}

func setup(mock MockRoute, t *testing.T) {
	setupMultiple([]MockRoute{mock}, t)
}

func setupWithRedirect(mock MockRouteWithRedirect, t *testing.T) {
	setupMultipleWithRedirect([]MockRouteWithRedirect{mock}, t)
}

func testQueryString(QueryString string, QueryStringExp string, t *testing.T) {
	value, _ := url.QueryUnescape(QueryString)

	if QueryStringExp != value {
		t.Fatalf("Error: Query string '%s' should be equal to '%s'", QueryStringExp, value)
	}
}

func testUserAgent(UserAgent string, UserAgentExp string, t *testing.T) {
	if len(UserAgentExp) < 1 {
		UserAgentExp = "Go-CF-client/1.1"
	}
	if UserAgent != UserAgentExp {
		t.Fatalf("Error: Agent %s should be equal to %s", UserAgent, UserAgentExp)
	}
}

func testReqBody(req *http.Request, postFormBody *string, t *testing.T) {
	if postFormBody != nil {
		if body, err := ioutil.ReadAll(req.Body); err != nil {
			t.Fatal("No request body but expected one")
		} else {
			defer req.Body.Close()
			if strings.TrimSpace(string(body)) != strings.TrimSpace(*postFormBody) {
				t.Fatalf("Expected request body (%s) does not equal request body (%s)", *postFormBody, body)
			}
		}
	}
}

func testBodyContains(req *http.Request, expected *string, t *testing.T) {
	if expected != nil {
		if body, err := ioutil.ReadAll(req.Body); err != nil {
			t.Fatal("No request body but expected one")
		} else {
			defer req.Body.Close()
			if !strings.Contains(string(body), *expected) {
				t.Fatalf("Expected request body (%s) was not found in actual request body (%s)", *expected, body)
			}
		}
	}
}

func setupMultiple(mockEndpoints []MockRoute, t *testing.T) {
	mockEndpointsWithRedirect := make([]MockRouteWithRedirect, len(mockEndpoints))
	for i, mock := range mockEndpoints {
		mockEndpointsWithRedirect[i] = MockRouteWithRedirect{
			MockRoute:        mock,
			RedirectLocation: "",
		}
	}
	setupMultipleWithRedirect(mockEndpointsWithRedirect, t)
}

func setupMultipleWithRedirect(mockEndpoints []MockRouteWithRedirect, t *testing.T) {
	mux = http.NewServeMux()
	server = httptest.NewServer(mux)
	fakeUAAServer = FakeUAAServer(3)
	m := martini.New()
	m.Use(render.Renderer())
	r := martini.NewRouter()
	for _, mock := range mockEndpoints {
		method := mock.Method
		endpoint := mock.Endpoint
		output := mock.Output
		userAgent := mock.UserAgent
		status := mock.Status
		queryString := mock.QueryString
		postFormBody := mock.PostForm
		redirectLocation := mock.RedirectLocation
		if method == "GET" {
			r.Get(endpoint, func(res http.ResponseWriter, req *http.Request) (int, string) {
				testUserAgent(req.Header.Get("User-Agent"), userAgent, t)
				testQueryString(req.URL.RawQuery, queryString, t)
				if redirectLocation != "" {
					res.Header().Add("Location", redirectLocation)
				}
				return status, output
			})
		} else if method == "POST" {
			r.Post(endpoint, func(req *http.Request) (int, string) {
				testUserAgent(req.Header.Get("User-Agent"), userAgent, t)
				testQueryString(req.URL.RawQuery, queryString, t)
				testReqBody(req, postFormBody, t)
				return status, output
			})
		} else if method == "DELETE" {
			r.Delete(endpoint, func(req *http.Request) (int, string) {
				testUserAgent(req.Header.Get("User-Agent"), userAgent, t)
				testQueryString(req.URL.RawQuery, queryString, t)
				return status, output
			})
		} else if method == "PUT" {
			r.Put(endpoint, func(req *http.Request) (int, string) {
				testUserAgent(req.Header.Get("User-Agent"), userAgent, t)
				testQueryString(req.URL.RawQuery, queryString, t)
				testReqBody(req, postFormBody, t)
				return status, output
			})
		} else if method == "PATCH" {
			r.Patch(endpoint, func(req *http.Request) (int, string) {
				testUserAgent(req.Header.Get("User-Agent"), userAgent, t)
				testQueryString(req.URL.RawQuery, queryString, t)
				testReqBody(req, postFormBody, t)
				return status, output
			})
		} else if method == "PUT-FILE" {
			r.Put(endpoint, func(req *http.Request) (int, string) {
				testUserAgent(req.Header.Get("User-Agent"), userAgent, t)
				testBodyContains(req, postFormBody, t)
				return status, output
			})
		}
	}
	r.Get("/v2/info", func(r render.Render) {
		r.JSON(200, map[string]interface{}{
			"authorization_endpoint":       fakeUAAServer.URL,
			"token_endpoint":               fakeUAAServer.URL,
			"logging_endpoint":             server.URL,
			"name":                         "",
			"build":                        "",
			"support":                      "https://support.example.net",
			"version":                      0,
			"description":                  "",
			"min_cli_version":              "6.23.0",
			"min_recommended_cli_version":  "6.23.0",
			"api_version":                  "2.103.0",
			"app_ssh_endpoint":             "ssh.example.net:2222",
			"app_ssh_host_key_fingerprint": "00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:01",
			"app_ssh_oauth_client":         "ssh-proxy",
			"doppler_logging_endpoint":     "wss://doppler.example.net:443",
			"routing_endpoint":             "https://api.example.net/routing",
		})

	})

	m.Action(r.Handle)
	mux.Handle("/", m)
}

func FakeUAAServer(expiresIn int) *httptest.Server {
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)
	m := martini.New()
	m.Use(render.Renderer())
	r := martini.NewRouter()
	count := 1
	r.Post("/oauth/token", func(r render.Render) {
		r.JSON(200, map[string]interface{}{
			"token_type":    "bearer",
			"access_token":  "foobar" + strconv.Itoa(count),
			"refresh_token": "barfoo",
			"expires_in":    expiresIn,
		})
		count = count + 1
	})
	r.NotFound(func() string { return "" })
	m.Action(r.Handle)
	mux.Handle("/", m)
	return server
}

func teardown() {
	server.Close()
	fakeUAAServer.Close()
}
