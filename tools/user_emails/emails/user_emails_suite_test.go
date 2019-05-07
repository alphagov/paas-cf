package emails_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestUserEmails(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "UserEmails Suite")
}
