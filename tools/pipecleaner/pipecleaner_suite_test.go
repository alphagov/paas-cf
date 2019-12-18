package main_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestPipecleaner(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Pipecleaner Suite")
}
