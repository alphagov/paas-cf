package workflowhelpers_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

func TestWorkflowhelpers(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Workflowhelpers Suite")
}
