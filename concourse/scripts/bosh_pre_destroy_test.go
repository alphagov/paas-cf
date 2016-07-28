package scripts_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"time"

	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/ghttp"
)

type InfoResponse struct{}
type DeploymentResponse []struct {
	Name string `json:"name"`
}

var _ = Describe("BoshPreDestroy", func() {
	const (
		ExecutionTimeout = 3 * time.Second
	)

	var (
		config      *os.File
		server      *ghttp.Server
		command     *exec.Cmd
		deployments DeploymentResponse
	)

	BeforeEach(func() {
		server = ghttp.NewServer()
		statusCode := http.StatusOK
		server.AppendHandlers(
			ghttp.CombineHandlers(
				ghttp.VerifyRequest("GET", "/info"),
				ghttp.RespondWithJSONEncoded(statusCode, InfoResponse{}),
			),
			ghttp.CombineHandlers(
				ghttp.VerifyRequest("GET", "/deployments"),
				ghttp.RespondWithJSONEncodedPtr(&statusCode, &deployments),
			),
		)

		var err error
		config, err = ioutil.TempFile("", "bosh_pre_destroy")
		Expect(err).ToNot(HaveOccurred())

		configContents := fmt.Sprintf("---\ntarget: %s\n", server.URL())
		_, err = config.Write([]byte(configContents))
		Expect(err).ToNot(HaveOccurred())

		command = exec.Command("bundle", "exec", "./bosh_pre_destroy.rb")
		command.Env = append(os.Environ(), fmt.Sprintf("BOSH_CONFIG=%s", config.Name()))
	})

	AfterEach(func() {
		os.Remove(config.Name())
		server.Close()
	})

	Context("no deployments", func() {
		BeforeEach(func() {
			deployments = DeploymentResponse{}
		})

		It("should return a zero exit code and no output", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session, ExecutionTimeout).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})

	Context("two deployments", func() {
		BeforeEach(func() {
			deployments = DeploymentResponse{{"one"}, {"two"}}
		})

		It("should return a non-zero exit code and list of deployments", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session, ExecutionTimeout).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(Equal([]byte(
				"The following deployments must be deleted before destroying BOSH:\n" +
					"- one\n" +
					"- two\n",
			)))
		})
	})
})
