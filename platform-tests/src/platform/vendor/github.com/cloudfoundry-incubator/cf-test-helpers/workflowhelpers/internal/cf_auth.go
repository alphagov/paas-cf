package internal

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/onsi/gomega/gexec"
)

func CfAuth(cmdStarter internal.Starter, reporter internal.Reporter, user string, password string) *gexec.Session {
	auth, err := cmdStarter.Start(reporter, "cf", "auth", user, password)
	if err != nil {
		panic(err)
	}
	return auth
}
