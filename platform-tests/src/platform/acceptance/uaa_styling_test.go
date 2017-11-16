package acceptance_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/PuerkitoBio/goquery"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
)

var _ = FDescribe("UAA Styling", func() {
	var uaaURL *url.URL
	var uaaLoginURL url.URL
	var uaaStylesheetURL url.URL
	var customStylesheetURL url.URL

	BeforeEach(func() {
		infoCommand := cf.Cf("curl", "/v2/info")
		Expect(infoCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

		var infoResp struct {
			TokenEndpoint string `json:"token_endpoint"`
		}
		err := json.Unmarshal(infoCommand.Buffer().Contents(), &infoResp)
		Expect(err).NotTo(HaveOccurred())

		uaaURL, err = url.Parse(infoResp.TokenEndpoint)
		Expect(err).NotTo(HaveOccurred())

		uaaLoginURL = *uaaURL
		uaaLoginURL.Path = "/login"

		uaaStylesheetURL = *uaaURL
		uaaStylesheetURL.Path = "/resources/oss/stylesheets/application.css"

		customStylesheetURL = url.URL{
			Scheme: "https",
			Host:   "paas-uaa-assets." + testConfig.AppsDomain,
			Path:   "/stylesheets/application.css",
		}
	})

	It("should be using the custom stylesheet", func() {
		response, err := httpClient.Get(uaaLoginURL.String())
		Expect(err).NotTo(HaveOccurred())
		uaaLoginDoc, err := goquery.NewDocumentFromResponse(response)
		Expect(err).NotTo(HaveOccurred())

		stylesheetHrefs := uaaLoginDoc.Find("link[rel=stylesheet]").Map(func(_ int, linkTag *goquery.Selection) string {
			href, _ := linkTag.Attr("href")
			return href
		})
		Expect(stylesheetHrefs).To(HaveLen(2))
		Expect(stylesheetHrefs[0]).To(Equal("/vendor/font-awesome/css/font-awesome.min.css"))
		Expect(stylesheetHrefs[1]).To(Equal(customStylesheetURL.String()))
	})

	It("should have the expected default stylesheet", func() {
		response, err := httpClient.Get(uaaStylesheetURL.String())
		Expect(err).NotTo(HaveOccurred())
		returnedBody, err := ioutil.ReadAll(response.Body)
		Expect(err).NotTo(HaveOccurred())

		expectedBody, err := ioutil.ReadFile("expected_uaa_stylesheet.css")
		Expect(err).NotTo(HaveOccurred())
		Expect(string(returnedBody)).To(Equal(string(expectedBody)))
	})

	It("should have the expected HTML on the login page", func() {
		response, err := httpClient.Get(uaaLoginURL.String())
		Expect(err).NotTo(HaveOccurred())

		uaaLoginDoc, err := goquery.NewDocumentFromResponse(response)
		Expect(err).NotTo(HaveOccurred())
		Expect(uaaLoginDoc.Find("link").SetAttr("href", "dummy://href").Length()).To(Equal(3))
		Expect(uaaLoginDoc.Find("meta[name=copyright]").SetAttr("content", "DUMMY COPYRIGHT").Length()).To(Equal(1))
		Expect(uaaLoginDoc.Find("input[name=X-Uaa-Csrf]").SetAttr("value", "DUMMY CSRF TOKEN").Length()).To(Equal(1))
		Expect(uaaLoginDoc.Find(".copyright").SetAttr("title", "DUMMY COPYRIGHT TITLE").SetText("DUMMY COPYRIGHT TEXT").Length()).To(Equal(1))
		canonicalReturnedBody, err := uaaLoginDoc.Html()
		Expect(err).NotTo(HaveOccurred())

		expectedBody, err := ioutil.ReadFile("expected_login_page.html")
		Expect(err).NotTo(HaveOccurred())
		Expect(string(canonicalReturnedBody)).To(Equal(string(expectedBody)))
	})

	It("should have the expected HTML on the accept invitation page", func() {
		oauthTokenCommand := cf.Cf("oauth-token")
		Expect(oauthTokenCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
		oauthToken := strings.TrimSpace(string(oauthTokenCommand.Buffer().Contents()))
		Expect(oauthToken).To(MatchRegexp(`bearer [0-9a-zA-Z]+`))

		uaaUsersURL := *uaaURL
		uaaUsersURL.Path = "/Users"
		req := &http.Request{
			Method: "POST",
			URL:    &uaaUsersURL,
			Header: map[string][]string{
				"Accept":        []string{"application/json"},
				"Content-Type":  []string{"application/json"},
				"Authorization": []string{oauthToken},
			},
			Body: ioutil.NopCloser(bytes.NewBufferString(`{
			  "userName" : "example@gov.uk",
			  "name" : {
			    "formatted" : "GOV.UK",
			    "familyName" : "Gov",
			    "givenName" : "UK"
			  },
			  "emails" : [ {
			    "value" : "example@gov.uk",
			    "primary" : true
			  } ],
			  "active" : true,
			  "verified" : true,
			  "password" : "secret",
			}`)),
		}
		response, err := httpClient.Do(req)
		Expect(err).NotTo(HaveOccurred())
		returnedBody, err := ioutil.ReadAll(response.Body)
		Expect(err).NotTo(HaveOccurred())

		var createUserResp struct {
			ID string `json:"id"`
		}
		err = json.Unmarshal(returnedBody, &createUserResp)
		Expect(err).NotTo(HaveOccurred())

		defer func(userID string) {
			uaaDeleteUserURL := *uaaURL
			uaaDeleteUserURL.Path = fmt.Sprintf("/Users/%s", userID)
			req := &http.Request{
				Method: "DELETE",
				URL:    &uaaDeleteUserURL,
				Header: map[string][]string{
					"Accept":        []string{"application/json"},
					"Content-Type":  []string{"application/json"},
					"Authorization": []string{oauthToken},
				},
			}
			_, err := httpClient.Do(req)
			Expect(err).NotTo(HaveOccurred())
		}(createUserResp.ID)

		uaaInviteUsersURL := *uaaURL
		uaaInviteUsersURL.Path = "/invite_users?redirect_uri="
		req = &http.Request{
			Method: "POST",
			URL:    &uaaInviteUsersURL,
			Header: map[string][]string{
				"Accept":        []string{"application/json"},
				"Content-Type":  []string{"application/json"},
				"Authorization": []string{oauthToken},
			},
			Body: ioutil.NopCloser(bytes.NewBufferString(`{
				"emails": ["example@gov.uk"]
			}`)),
		}
		response, err = httpClient.Do(req)
		Expect(err).NotTo(HaveOccurred())
		returnedBody, err = ioutil.ReadAll(response.Body)
		Expect(err).NotTo(HaveOccurred())

		var inviteUsersResp struct {
			NewInvites []struct {
				UserID     string `json:"userId"`
				InviteLink string `json:"inviteLink"`
			} `json:"new_invites"`
		}
		err = json.Unmarshal(returnedBody, &inviteUsersResp)
		Expect(err).NotTo(HaveOccurred())
		Expect(inviteUsersResp.NewInvites).To(HaveLen(1))

		uaaAcceptURL, err := url.Parse(inviteUsersResp.NewInvites[0].InviteLink)
		Expect(err).NotTo(HaveOccurred())

		response, err = httpClient.Get(uaaAcceptURL.String())
		Expect(err).NotTo(HaveOccurred())

		uaaAcceptDoc, err := goquery.NewDocumentFromResponse(response)
		Expect(err).NotTo(HaveOccurred())
		Expect(uaaAcceptDoc.Find("link").SetAttr("href", "dummy://href").Length()).To(Equal(3))
		Expect(uaaAcceptDoc.Find("meta[name=copyright]").SetAttr("content", "DUMMY COPYRIGHT").Length()).To(Equal(1))
		Expect(uaaAcceptDoc.Find("input[name=X-Uaa-Csrf]").SetAttr("value", "DUMMY CSRF TOKEN").Length()).To(Equal(1))
		Expect(uaaAcceptDoc.Find(".copyright").SetAttr("title", "DUMMY COPYRIGHT TITLE").SetText("DUMMY COPYRIGHT TEXT").Length()).To(Equal(1))
		canonicalReturnedBody, err := uaaAcceptDoc.Html()
		Expect(err).NotTo(HaveOccurred())

		expectedBody, err := ioutil.ReadFile("expected_accept_page.html")
		Expect(err).NotTo(HaveOccurred())
		Expect(string(canonicalReturnedBody)).To(Equal(string(expectedBody)))
	})
})
