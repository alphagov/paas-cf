package scripts_test

import (
	"net/http"
	"os"
	"os/exec"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/ghttp"
)

type Response struct {
	Resources    []UserResource `json:"resources"`
	StartIndex   int            `json:"startIndex"`
	ItemsPerPage int            `json:"itemsPerPage"`
	TotalResults int            `json:"totalResults"`
	Schemas      []string       `json:"schemas"`
}

type UserResource struct {
	ID       string `json:"id"`
	Username string `json:"userName"`
	Active   bool   `json:"active"`
}

var _ = Describe("uaa_lock_user.rb", func() {
	var (
		args       []string
		session    *gexec.Session
		server     *ghttp.Server
		response   *Response
		statusCode int
	)

	BeforeEach(func() {
		args = []string{"jane.smith@gov.uk"}

		statusCode = http.StatusOK
		response = &Response{
			Resources: []UserResource{{
				ID:       "17742243-4250-4266-ba8b-5d76dc97d52e",
				Username: "jane.smith@gov.uk",
			}},
			StartIndex:   1,
			ItemsPerPage: 100,
			TotalResults: 1,
			Schemas:      []string{"urn:scim:schemas:core:1.0"},
		}

		server = ghttp.NewServer()
		server.RouteToHandler("GET", "/Users", ghttp.RespondWithJSONEncodedPtr(&statusCode, &response))
	})

	AfterEach(func() {
		server.Close()
	})

	JustBeforeEach(func() {
		os.Setenv("TARGET", server.URL())
		os.Setenv("TOKEN", "faketoken")

		args = append([]string{"exec", "./uaa_lock_user.rb"}, args...)
		command := exec.Command("bundle", args...)

		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("user doesn't exist", func() {
		BeforeEach(func() {
			args = []string{"john.smith@gov.uk"}

			response.Resources = []UserResource{}
			response.TotalResults = 0
		})

		It("returns an error", func() {
			Eventually(session, "5s").Should(gexec.Exit(1))
			Expect(session.Err).To(gbytes.Say("Username not found"))
		})
	})

	Context("more than one user", func() {
		BeforeEach(func() {
			response.Resources = append(response.Resources, response.Resources[0])
			response.TotalResults = 2
		})

		It("returns an error", func() {
			Eventually(session, "5s").Should(gexec.Exit(1))
			Expect(session.Err).To(gbytes.Say("Username is not unique"))
		})
	})

	Context("lock existing user", func() {
		Context("user is not locked", func() {
			BeforeEach(func() {
				response.Resources[0].Active = true

				server.RouteToHandler("PATCH", "/Users/17742243-4250-4266-ba8b-5d76dc97d52e", ghttp.RespondWith(statusCode, ""))
			})

			It("prints success message", func() {
				Eventually(session, "5s").Should(gexec.Exit(0))
				Expect(session.Out).To(gbytes.Say("locked jane.smith@gov.uk"))
			})
		})

		Context("user is locked", func() {
			BeforeEach(func() {
				response.Resources[0].Active = false
			})

			It("prints success message", func() {
				Eventually(session, "5s").Should(gexec.Exit(0))
				Expect(session.Out).To(gbytes.Say("locked jane.smith@gov.uk"))
			})
		})
	})

	Context("unlock existing user", func() {
		BeforeEach(func() {
			args = append(args, "-u")
		})

		Context("user is not locked", func() {
			BeforeEach(func() {
				response.Resources[0].Active = true
			})

			It("prints success message", func() {
				Eventually(session, "5s").Should(gexec.Exit(0))
				Expect(session.Out).To(gbytes.Say("unlocked jane.smith@gov.uk"))
			})
		})

		Context("user is locked", func() {
			BeforeEach(func() {
				response.Resources[0].Active = false

				server.RouteToHandler("PATCH", "/Users/17742243-4250-4266-ba8b-5d76dc97d52e", ghttp.RespondWith(statusCode, ""))
			})

			It("prints success message", func() {
				Eventually(session, "5s").Should(gexec.Exit(0))
				Expect(session.Out).To(gbytes.Say("unlocked jane.smith@gov.uk"))
			})
		})
	})
})
