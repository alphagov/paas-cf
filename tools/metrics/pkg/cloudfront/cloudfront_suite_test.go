package cloudfront_test

import (
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func TestCloudfront(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Cloudfront Suite")
}
