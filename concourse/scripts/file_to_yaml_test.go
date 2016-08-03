package scripts_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"io/ioutil"
	"os"
	"os/exec"

	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
)

var _ = Describe("FileToYaml", func() {
	var (
		inputFile *os.File
		command   *exec.Cmd
	)

	BeforeEach(func() {
		var err error
		inputFile, err = ioutil.TempFile("", "bosh_pre_destroy")
		Expect(err).ToNot(HaveOccurred())
	})

	AfterEach(func() {
		os.Remove(inputFile.Name())
	})

	Context("two keys and a text file", func() {
		BeforeEach(func() {
			_, err := inputFile.Write([]byte("Some content\n"))
			Expect(err).ToNot(HaveOccurred())

			command = exec.Command("./file_to_yaml.sh", "key_one", "key_two", inputFile.Name())
		})

		It("should generate a simple YAML structure", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(Equal([]byte(`---
key_one:
  key_two: |
    Some content
`)))
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})

	Context("wrong number of arguments", func() {
		BeforeEach(func() {
			_, err := inputFile.Write([]byte("Some content"))
			Expect(err).ToNot(HaveOccurred())

			command = exec.Command("./file_to_yaml.sh", "key_one", "key_two")
		})

		It("should return non-zero, no STDOUT, and STDERR message", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err).To(gbytes.Say("Missing arguments"))
		})
	})

	Context("file does not exist", func() {
		BeforeEach(func() {
			os.Remove(inputFile.Name())
			command = exec.Command("./file_to_yaml.sh", "key_one", "key_two", inputFile.Name())
		})

		It("should return non-zero, no STDOUT, and STDERR message", func() {
			session, err := gexec.Start(command, GinkgoWriter, GinkgoWriter)
			Expect(err).ToNot(HaveOccurred())

			Eventually(session).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err).To(gbytes.Say("No such file or directory"))
		})
	})
})
