package shield_test

import (
	"testing"

	. "github.com/onsi/gomega"
)

func TestShield(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Shield Suite")
}
