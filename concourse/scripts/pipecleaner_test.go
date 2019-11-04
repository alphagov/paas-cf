package scripts_test

import (
	"os/exec"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
)

var _ = Describe("PipeCleaner", func() {
	const runTimeout = 5 * time.Second

	var (
		command *exec.Cmd
		session *gexec.Session
	)

	JustBeforeEach(func() {
		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
		session.Wait(runTimeout)
	})

	Context("when run with no arguments, get usage", func() {
		BeforeEach(func() {
			command = exec.Command("./pipecleaner.py")
		})

		It("should return non-zero, with Usage on STDOUT, nothing on STDERR", func() {
			Expect(session).To(gexec.Exit(2))
			Expect(session.Out).To(gbytes.Say("pipecleaner.py [--ignore-types=unused_fetch,unused_resource]"))
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})

	Context("shellcheck", func() {
		Context("disabled", func() {
			BeforeEach(func() {
				command = exec.Command("./pipecleaner.py", "--ignore-types", "shellcheck", "spec/fixtures/pipecleaner_shellcheck.yml")
			})

			It("should not report anything", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session.Err.Contents()).To(BeEmpty())
				Expect(session.Out.Contents()).To(BeEmpty())
			})
		})

		Context("normal", func() {
			BeforeEach(func() {
				command = exec.Command("./pipecleaner.py", "spec/fixtures/pipecleaner_shellcheck.yml")
			})

			It("should fatal with non-portable compare", func() {
				Expect(session).To(gexec.Exit(10))
				Expect(session.Out).To(gbytes.Say("ERROR.*?job='shellcheck', task='bad-compare'"))
				Expect(session.Err.Contents()).To(BeEmpty())
			})
		})

		Context("when params are supplied", func() {
			BeforeEach(func() {
				command = exec.Command("./pipecleaner.py", "spec/fixtures/pipecleaner_shellcheck_params.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session.Out.Contents()).To(BeEmpty())
				Expect(session.Err.Contents()).To(BeEmpty())
			})
		})
	})

	Context("secret-interpolation", func() {
		Context("when there's a param that looks like a secret but is not interpolated", func () {
			BeforeEach(func () {
				command = exec.Command("./pipecleaner.py", "spec/fixtures/pipecleaner_secrets_interpolation.yml")
			})

			It("should report a warning", func () {
				Expect(session).To(gexec.Exit(0))
				Expect(session.Out).To(gbytes.Say("WARNING.*?job='secrets-interpolate', task='bad-secrets-interpolate'"))
				Expect(session.Err.Contents()).To(BeEmpty())
			})
		})
	})
})
