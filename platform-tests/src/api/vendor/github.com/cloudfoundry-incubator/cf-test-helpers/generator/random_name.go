package generator

import (
	"strconv"

	uuid "github.com/nu7hatch/gouuid"
	"github.com/onsi/ginkgo/config"
)

func randomName() string {
	guid, err := uuid.NewV4()
	if err != nil {
		panic(err)
	}

	return guid.String()[0:20]
}

func PrefixedRandomName(prefixName, resourceName string) string {
	return prefixName + "-" + strconv.Itoa(config.GinkgoConfig.ParallelNode) + "-" + resourceName + "-" + randomName()
}
