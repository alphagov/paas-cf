package run_from_vm_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

func TestRunFromVm(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "RunFromVm Suite")
}
