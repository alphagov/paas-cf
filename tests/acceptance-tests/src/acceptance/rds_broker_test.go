package acceptance_test

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var (
	brokerName = "postgres"
)

var _ = Describe("RDS broker", func() {

	It("should be registered", func() {
		plans := cf.Cf("marketplace").Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(brokerName))
	})
})
