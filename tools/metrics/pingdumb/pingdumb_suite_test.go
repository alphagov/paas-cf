package pingdumb_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

func TestPingdumb(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Pingdumb Suite")
}
