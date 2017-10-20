package generator_test

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("RandomName", func() {
	It("generates a short name", func() {
		name := generator.PrefixedRandomName("", "")
		Expect(len(name)).To(BeNumerically("<=", 24))
	})

	It("generates a name starting with the prefix", func() {
		name := generator.PrefixedRandomName("PREFIX", "APP")
		Expect(name).To(HavePrefix("PREFIX"))
	})

	It("generates a name containing the resource", func() {
		name := generator.PrefixedRandomName("PREFIX", "APP")
		Expect(name).To(ContainSubstring("APP"))
	})

	It("generates a name ending in 16 hexadecimal digits", func() {
		name := generator.PrefixedRandomName("PREFIX", "APP")
		Expect(name).To(MatchRegexp(".*-[0-9a-f]{16}$"))
	})
})
