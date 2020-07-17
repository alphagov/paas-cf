package helpers

import (
	"os"

	. "github.com/onsi/gomega"
)

func MustGetenv(varName string) string {
	return mustGetenv(1, varName)
}

func mustGetenv(depth int, varName string) string {
	configValue := os.Getenv(varName)
	ExpectWithOffset(depth+1, configValue).NotTo(BeEmpty(), "Environment variable $%s is not set", varName)
	return configValue
}
