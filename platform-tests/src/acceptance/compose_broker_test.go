package acceptance_test

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("ComposeBroker", func() {

	const (
		serviceName = "mongodb"
	)

	It("is registered in the marketplace", func() {
		marketplace := cf.Cf("marketplace").Wait(DEFAULT_TIMEOUT)
		Expect(marketplace).To(Exit(0))
		Expect(marketplace).To(Say(serviceName))
	})
})
