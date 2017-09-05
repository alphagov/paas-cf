package scripts_test

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("set_pipeline_ordering", func() {
	const (
		flyrcTarget = `unit-test`
		bearerToken = `2d5ebf5efbac7997025e9364f0319304ce89480724077d5f7103c234460e8d0de928f884553686aa30afc9629278b9595059d0e0be41ff5ffc5cf3a04f67e57f`
	)

	var (
		concourse *ghttp.Server
		tmpHome   string
	)

	BeforeEach(func() {
		var err error
		concourse = ghttp.NewServer()
		tmpHome, err = ioutil.TempDir("", "tmphome")
		Expect(err).NotTo(HaveOccurred())
	})
	AfterEach(func() {
		concourse.Close()
		os.RemoveAll(tmpHome)
	})

	It("makes the request to concourse", func() {
		concourse.AppendHandlers(ghttp.CombineHandlers(
			ghttp.VerifyRequest("PUT", "/api/v1/teams/main/pipelines/ordering"),
			ghttp.VerifyHeaderKV("Authorization", "Bearer "+bearerToken),
			ghttp.VerifyJSON(`["pipeline-one","pipeline-two"]`),
			ghttp.RespondWith(200, ""),
		))

		populateFlyrc(tmpHome, flyrcTarget, concourse.URL(), bearerToken)

		cmd := exec.Command("./set_pipeline_ordering.rb", "pipeline-one,pipeline-two")
		cmd.Env = mergeEnvLists(
			[]string{"HOME=" + tmpHome, "FLY_TARGET=" + flyrcTarget},
			os.Environ(),
		)
		session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 1).Should(gexec.Exit(0))

		Expect(concourse.ReceivedRequests()).To(HaveLen(1))
	})

	It("errors if no pipelines given on cmdline", func() {
		cmd := exec.Command("./set_pipeline_ordering.rb")
		cmd.Env = mergeEnvLists(
			[]string{"HOME=" + tmpHome, "FLY_TARGET=" + flyrcTarget},
			os.Environ(),
		)
		session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 1).Should(gexec.Exit(1))
		Expect(session.Err).To(gbytes.Say("Usage:"))

		Expect(concourse.ReceivedRequests()).To(HaveLen(0))
	})

	It("errors if FLY_TARGET isn't set", func() {
		cmd := exec.Command("./set_pipeline_ordering.rb", "pipeline-one,pipeline-two")
		cmd.Env = mergeEnvLists(
			[]string{"HOME=" + tmpHome},
			os.Environ(),
		)
		session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 1).Should(gexec.Exit(1))

		Expect(concourse.ReceivedRequests()).To(HaveLen(0))

		cmd = exec.Command("./set_pipeline_ordering.rb", "pipeline-one,pipeline-two")
		cmd.Env = mergeEnvLists(
			[]string{"HOME=" + tmpHome, "FLY_TARGET="},
			os.Environ(),
		)
		session, err = gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 1).Should(gexec.Exit(1))

		Expect(concourse.ReceivedRequests()).To(HaveLen(0))
	})

	It("errors if FLY_TARGET doesn't exist in flyrc", func() {
		populateFlyrc(tmpHome, flyrcTarget, concourse.URL(), bearerToken)

		cmd := exec.Command("./set_pipeline_ordering.rb", "pipeline-one,pipeline-two")
		cmd.Env = mergeEnvLists(
			[]string{"HOME=" + tmpHome, "FLY_TARGET=different-target"},
			os.Environ(),
		)
		session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 1).Should(gexec.Exit(1))
		Expect(session.Err).To(gbytes.Say("Target 'different-target' not found in .flyrc"))

		Expect(concourse.ReceivedRequests()).To(HaveLen(0))
	})

	It("errors if concourse returns non-200 response", func() {
		concourse.AppendHandlers(ghttp.RespondWith(401, "unauthorized"))

		populateFlyrc(tmpHome, flyrcTarget, concourse.URL(), bearerToken)

		cmd := exec.Command("./set_pipeline_ordering.rb", "pipeline-one,pipeline-two")
		cmd.Env = mergeEnvLists(
			[]string{"HOME=" + tmpHome, "FLY_TARGET=" + flyrcTarget},
			os.Environ(),
		)
		session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 1).Should(gexec.Exit(1))
		Expect(session.Err).To(gbytes.Say("Non-200 response '401'"))

		Expect(concourse.ReceivedRequests()).To(HaveLen(1))
	})
})

// MergeEnvLists merges the two environment lists such that
// variables with the same name in "in" replace those in "out".
// This always returns a newly allocated slice.
//
// Lifted from src/cmd/go/internal/base/env.go in the go source tree.
//
// FIXME: When we upgrade to Go 1.9, this can be removed and replaced with a
// simple `cmd.Env := append(os.Environ(), "FOO=bar")` because Go 1.9 de-dups
// the list (https://golang.org/doc/go1.9#os/exec).
func mergeEnvLists(in, out []string) []string {
	out = append([]string(nil), out...)
NextVar:
	for _, inkv := range in {
		k := strings.SplitAfterN(inkv, "=", 2)[0]
		for i, outkv := range out {
			if strings.HasPrefix(outkv, k) {
				out[i] = inkv
				continue NextVar
			}
		}
		out = append(out, inkv)
	}
	return out
}

func populateFlyrc(homedir, target, url, token string) {
	filePath := homedir + "/.flyrc"
	file, err := os.OpenFile(filePath, os.O_RDWR|os.O_CREATE, 0755)
	ExpectWithOffset(1, err).NotTo(HaveOccurred())
	_, err = fmt.Fprintf(
		file,
		"targets:\n"+
			"  %s:\n"+
			"    api: %s\n"+
			"    team: main\n"+
			"    token:\n"+
			"      type: Bearer\n"+
			"      value: %s\n",
		target,
		url,
		token,
	)
	ExpectWithOffset(1, err).NotTo(HaveOccurred())
	err = file.Close()
	ExpectWithOffset(1, err).NotTo(HaveOccurred())
}
