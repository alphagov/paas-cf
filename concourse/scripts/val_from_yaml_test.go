package scripts_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"io/ioutil"
	"os"
	"os/exec"

	"github.com/onsi/gomega/gexec"
)

var _ = Describe("ValFromYaml", func() {
	const inputContent = `---
foo:
  bar:
   val1: a
   val2: b
  array1:
  - name: item1
    val: array1_item1_value
  - name: item2
    val: array1_item2_value
  array2:
  - array2_value1
  - array2_value2
  - array2_value3
`

	var (
		cmdArg    string
		session   *gexec.Session
		inputFile *os.File
	)

	BeforeEach(func() {
		cmdArg = ""
		session = nil

		var err error
		inputFile, err = ioutil.TempFile("", "val_from_yaml")
		Expect(err).ToNot(HaveOccurred())

		_, err = inputFile.Write([]byte(inputContent))
		Expect(err).ToNot(HaveOccurred())
	})

	AfterEach(func() {
		os.Remove(inputFile.Name())
	})

	JustBeforeEach(func() {
		command := exec.Command("./val_from_yaml.rb", cmdArg, inputFile.Name())

		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("argument references a string value", func() {
		BeforeEach(func() {
			cmdArg = "foo.bar.val1"
		})

		It("returns a single string", func() {
			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(Equal([]byte("a\n")))
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})

	Context("argument references a hash value", func() {
		BeforeEach(func() {
			cmdArg = "foo.bar"
		})

		It("returns a YAML hash", func() {
			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(Equal([]byte(`---
val1: a
val2: b
`)))
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})

	Context("argument references a key that does not exist", func() {
		BeforeEach(func() {
			cmdArg = "x.y.z"
		})

		It("exits non-zero code and error message", func() {
			Eventually(session).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(Equal([]byte("Unable to find key: x.y.z\n")))
		})
	})

	Context("argument references a sub-key of a string value", func() {
		BeforeEach(func() {
			cmdArg = "foo.var.val1.nothing_to_see_here"
		})

		It("exits non-zero code and error message", func() {
			Eventually(session).Should(gexec.Exit(1))
			Expect(session.Out.Contents()).To(BeEmpty())
			Expect(session.Err.Contents()).To(Equal([]byte("Unable to find key: foo.var.val1.nothing_to_see_here\n")))
		})
	})

	Context("argument references a string value within an array indexed by name keys", func() {
		BeforeEach(func() {
			cmdArg = "foo.array1.item1.val"
		})

		It("returns a single string", func() {
			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(Equal([]byte("array1_item1_value\n")))
			Expect(session.Err.Contents()).To(BeEmpty())
		})
	})
})
