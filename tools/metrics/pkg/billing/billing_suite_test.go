package billing_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestBilling(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Billing Suite")
}
