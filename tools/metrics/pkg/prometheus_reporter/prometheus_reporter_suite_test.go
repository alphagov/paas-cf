package prometheusreporter

import (
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func TestPrometheusReporter(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PrometheusReporter Suite")
}
