package scripts_test

import (
	"os/exec"
	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
)

var _ = Describe("ExtractTFVarsFromTFState", func() {

	var (
		cmdInput string
		session  *gexec.Session
	)

	JustBeforeEach(func() {
		command := exec.Command("./extract_tf_vars_from_terraform_state.rb")
		command.Stdin = strings.NewReader(cmdInput)

		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("with a version 4 tfstate file", func() {
		BeforeEach(func() {
			cmdInput = `
{
    "version": 4,
    "terraform_version": "0.12.29",
    "serial": 5,
    "lineage": "bfa4e77c-4e4e-462e-92a9-dba07be0f409",
	"outputs": {
		"foo_dns_name": {
			"sensitive": false,
			"type": "string",
			"value": "foo.example.com"
		},
		"foo_elastic_ip": {
			"sensitive": false,
			"type": "string",
			"value": "10.210.221.248"
		},
		"foo_security_group_id": {
			"sensitive": false,
			"type": "string",
			"value": "sg-12345678"
		}
	},
	"resources": {}
}
			`
		})

		It("returns a shell export statement for each output", func() {
			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out).To(gbytes.Say("export TF_VAR_foo_dns_name='foo.example.com'"))
			Expect(session.Out).To(gbytes.Say("export TF_VAR_foo_elastic_ip='10.210.221.248'"))
			Expect(session.Out).To(gbytes.Say("export TF_VAR_foo_security_group_id='sg-12345678'"))
		})
	})

	Context("with a version 3 tfstate file", func() {
		BeforeEach(func() {
			cmdInput = `
{
    "version": 3,
    "terraform_version": "0.7.3",
    "serial": 5,
    "lineage": "bfa4e77c-4e4e-462e-92a9-dba07be0f409",
    "modules": [
        {
            "path": [
                "root"
            ],
            "outputs": {
                "bar_dns_name": {
                    "sensitive": false,
                    "type": "string",
                    "value": "bar.example.com"
                },
                "bar_elastic_ip": {
                    "sensitive": false,
                    "type": "string",
                    "value": "10.210.220.248"
                },
                "bar_security_group_id": {
                    "sensitive": false,
                    "type": "string",
                    "value": "sg-123456789"
                }
            },
			"resources": {},
			"depends_on": []
		}
	]
}
			`
		})

		It("returns a shell export statement for each output", func() {
			Eventually(session).Should(gexec.Exit(0))
			Expect(session.Out).To(gbytes.Say("export TF_VAR_bar_dns_name='bar.example.com'"))
			Expect(session.Out).To(gbytes.Say("export TF_VAR_bar_elastic_ip='10.210.220.248'"))
			Expect(session.Out).To(gbytes.Say("export TF_VAR_bar_security_group_id='sg-123456789'"))
		})
	})
})
