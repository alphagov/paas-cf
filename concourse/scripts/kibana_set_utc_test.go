package scripts_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"

	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/ghttp"
)

type EmptyResponse struct{}
type ConfigResponse struct {
	Found  bool         `json:"found"`
	Source ConfigSource `json:"_source,omitempty"`
}
type ConfigSource struct {
	Timezone string `json:"dateFormat:tz,omitempty"`
}

var _ = Describe("KibanaSetUtc", func() {
	const (
		KibanaConfigPath = "/.kibana/config/4.4.0"
		KibanaIndexPath  = "/.kibana"
	)

	var (
		server  *ghttp.Server
		command *exec.Cmd
	)

	BeforeEach(func() {
		server = ghttp.NewServer()

		host, port, err := net.SplitHostPort(server.Addr())
		Expect(err).ToNot(HaveOccurred())

		command = exec.Command("./kibana_set_utc.rb")
		command.Env = os.Environ()
		command.Env = append(command.Env, fmt.Sprintf("ES_HOST=%s", host))
		command.Env = append(command.Env, fmt.Sprintf("ES_PORT=%s", port))
	})

	AfterEach(func() {
		server.Close()
	})

	Context("no index exists", func() {
		BeforeEach(func() {
			server.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("GET", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusNotFound, ConfigResponse{
						Found: false,
					}),
				),
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("PUT", KibanaIndexPath),
					ghttp.RespondWithJSONEncoded(http.StatusCreated, EmptyResponse{}),
				),
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("PUT", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusCreated, EmptyResponse{}),
				),
			)
		})

		It("creates index and adds utc config", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(BeEmpty())

			Expect(server.ReceivedRequests()).To(HaveLen(3))
		})
	})

	Context("index exists and wrong config is not present", func() {
		BeforeEach(func() {
			server.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("GET", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusOK, ConfigResponse{
						Found: true,
					}),
				),
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("PUT", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusCreated, EmptyResponse{}),
				),
			)
		})

		It("adds utc config", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(BeEmpty())

			Expect(server.ReceivedRequests()).To(HaveLen(2))
		})
	})

	Context("index exists and wrong config is present", func() {
		BeforeEach(func() {
			server.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("GET", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusOK, ConfigResponse{
						Found:  true,
						Source: ConfigSource{Timezone: "NOT_UTC"},
					}),
				),
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("PUT", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusOK, EmptyResponse{}),
				),
			)
		})

		It("adds utc config", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(BeEmpty())

			Expect(server.ReceivedRequests()).To(HaveLen(2))
		})
	})

	Context("elastic search is not available", func() {
		BeforeEach(func() {
			server.Close()
		})
		AfterEach(func() {
			server = ghttp.NewServer()
		})

		It("reports an error", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err).To(gbytes.Say("Connection refused"))
		})
	})

	Context("index exists and config is already UTC", func() {
		BeforeEach(func() {
			server.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("GET", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusOK, ConfigResponse{
						Found:  true,
						Source: ConfigSource{Timezone: "UTC"},
					}),
				),
			)
		})

		It("does nothing", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(BeEmpty())

			Expect(server.ReceivedRequests()).To(HaveLen(1))
		})
	})

	Context("elasticsearch responds with an unexpected status code", func() {
		BeforeEach(func() {
			server.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("GET", KibanaConfigPath),
					ghttp.RespondWithJSONEncoded(http.StatusInternalServerError, ConfigResponse{
						Found:  true,
						Source: ConfigSource{Timezone: "UTC"},
					}),
				),
			)
		})

		It("reports an error", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err).To(gbytes.Say("Unexpected response code: 500"))

			Expect(server.ReceivedRequests()).To(HaveLen(1))
		})
	})
})
