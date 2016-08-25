package scripts_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"os/exec"

	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
)

var _ = Describe("PipeCleaner", func() {
	var (
		command *exec.Cmd
		session *gexec.Session
	)

	JustBeforeEach(func() {
		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("when run with no arguments, get usage", func() {
		BeforeEach(func() {
			command = exec.Command("./pipecleaner.py")
		})

		It("should return non-zero, with Usage on STDOUT, nothing on STDERR", func() {
			Eventually(session).Should(gexec.Exit(2))
			Expect(session.Out).To(gbytes.Say("pipecleaner.py pipeline.yml"))
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})

	Context("shellcheck", func() {
		Context("disabled", func() {
			BeforeEach(func() {
				command = exec.Command("./pipecleaner.py", "--ignore-types", "shellcheck", "spec/fixtures/pipecleaner_shellcheck.yml")
			})

			It("should not report anything", func() {
				Eventually(session).Should(gexec.Exit(0))
				Expect(session.Err.Contents()).To(BeEmpty())
				Expect(session.Out.Contents()).To(BeEmpty())
			})
		})

		Context("normal", func() {
			BeforeEach(func() {
				command = exec.Command("./pipecleaner.py", "spec/fixtures/pipecleaner_shellcheck.yml")
			})

			It("should warn about the non-portable compare", func() {
				Eventually(session).Should(gexec.Exit(0))
				Expect(session.Out).To(gbytes.Say("WARNING.*?job='shellcheck', task='bad-compare'"))
				Expect(session.Err.Contents()).To(BeEmpty())
			})
		})

		Context("with --fatal-warnings", func() {
			BeforeEach(func() {
				command = exec.Command("./pipecleaner.py", "--fatal-warnings", "spec/fixtures/pipecleaner_shellcheck.yml")
			})

			It("should warn about the non-portable compare, and exit as though fatal", func() {
				Eventually(session).Should(gexec.Exit(20))
				Expect(session.Out).To(gbytes.Say("WARNING.*?job='shellcheck', task='bad-compare'"))
				Expect(session.Err.Contents()).To(BeEmpty())
			})
		})
	})
})
