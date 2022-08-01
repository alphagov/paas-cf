package acceptance_test

import (
	"fmt"
	"io"
	"os"
	"os/exec"

	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/generator"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("CF SSH", func() {
	It("should be enabled", func() {
		appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"-b", testConfig.GetStaticFileBuildpackName(),
			"-p", "../example-apps/static-app",
			"-i", "1",
			"-m", "64M",
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		cfSSH := cf.Cf("ssh", appName, "-c", "uptime").Wait(testConfig.DefaultTimeoutDuration())
		Expect(cfSSH).To(Exit(0))
		Expect(cfSSH).To(Say("load average:"))
	})

	It("allows uploading a large payload via standard ssh client", func() {
		const payloadSize = 10 * GIGABYTE
		timeout := 600
		appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"-b", testConfig.GetStaticFileBuildpackName(),
			"-p", "../example-apps/static-app",
			"-i", "1",
			"-m", "64M",
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

		cfSSHCommand := exec.Command("/usr/bin/cf", "ssh", appName, "-c", "cat > /dev/null")
		sshStdin, err := cfSSHCommand.StdinPipe()
		Expect(err).NotTo(HaveOccurred())

		file, err := os.Open("/dev/zero")
		Expect(err).NotTo(HaveOccurred())
		defer file.Close()

		session, err := Start(cfSSHCommand, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())

		copied, err := io.CopyN(sshStdin, file, payloadSize)
		Expect(err).NotTo(HaveOccurred())
		fmt.Fprintf(GinkgoWriter, "Successfully copied %d bytes", copied)
		sshStdin.Close()

		Expect(copied).To(Equal(payloadSize))
		session.Wait(timeout)
		Expect(session).To(Exit(0))
	})
})
