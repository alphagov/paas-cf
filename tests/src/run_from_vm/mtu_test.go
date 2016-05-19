package run_from_vm_test

import (
	"os"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("MTU", func() {
	var (
		EndpointURL string
	)

	BeforeEach(func() {
		EndpointURL = os.Getenv("API_ENDPOINT")
		Expect(EndpointURL).ToNot(BeEmpty(), "API_ENDPOINT environment variable must be set")
	})
})
