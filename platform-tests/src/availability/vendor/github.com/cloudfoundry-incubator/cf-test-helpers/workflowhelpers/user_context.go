package workflowhelpers

import (
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/commandstarter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	workflowhelpersinternal "github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
	ginkgoconfig "github.com/onsi/ginkgo/config"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

type userValues interface {
	Username() string
	Password() string
}

type spaceValues interface {
	OrganizationName() string
	SpaceName() string
}

type UserContext struct {
	ApiUrl    string
	TestSpace spaceValues
	TestUser  userValues

	SkipSSLValidation bool
	CommandStarter    internal.Starter
	Timeout           time.Duration

	// the followings are left around for CATS to use
	Username string
	Password string
	Org      string
	Space    string
}

func NewUserContext(apiUrl string, testUser userValues, testSpace spaceValues, skipSSLValidation bool, timeout time.Duration) UserContext {
	var org, space string
	if testSpace != nil {
		org = testSpace.OrganizationName()
		space = testSpace.SpaceName()
	}

	return UserContext{
		ApiUrl:            apiUrl,
		Username:          testUser.Username(),
		Password:          testUser.Password(),
		TestSpace:         testSpace,
		TestUser:          testUser,
		Org:               org,
		Space:             space,
		SkipSSLValidation: skipSSLValidation,
		CommandStarter:    commandstarter.NewCommandStarter(),
		Timeout:           timeout,
	}
}

func (uc UserContext) Login() {
	args := []string{"api", uc.ApiUrl}
	if uc.SkipSSLValidation {
		args = append(args, "--skip-ssl-validation")
	}
	session := internal.Cf(uc.CommandStarter, args...)
	EventuallyWithOffset(1, session, uc.Timeout).Should(Exit(0))

	session = workflowhelpersinternal.CfAuth(uc.CommandStarter, uc.TestUser.Username(), uc.TestUser.Password())
	EventuallyWithOffset(1, session, uc.Timeout).Should(Exit(0))
}

func (uc UserContext) SetCfHomeDir() (string, string) {
	originalCfHomeDir := os.Getenv("CF_HOME")
	currentCfHomeDir, err := ioutil.TempDir("", fmt.Sprintf("cf_home_%d", ginkgoconfig.GinkgoConfig.ParallelNode))
	if err != nil {
		panic("Error: could not create temporary home directory: " + err.Error())
	}

	os.Setenv("CF_HOME", currentCfHomeDir)
	return originalCfHomeDir, currentCfHomeDir
}

func (uc UserContext) TargetSpace() {
	if uc.TestSpace != nil && uc.TestSpace.OrganizationName() != "" {
		var session *Session
		session = internal.Cf(uc.CommandStarter, "target", "-o", uc.TestSpace.OrganizationName(), "-s", uc.TestSpace.SpaceName())
		EventuallyWithOffset(1, session, uc.Timeout).Should(Exit(0))
	}
}

func (uc UserContext) AddUserToSpace() {
	username := uc.TestUser.Username()
	orgName := uc.TestSpace.OrganizationName()
	spaceName := uc.TestSpace.SpaceName()

	spaceManager := internal.Cf(uc.CommandStarter, "set-space-role", username, orgName, spaceName, "SpaceManager")
	EventuallyWithOffset(1, spaceManager, uc.Timeout).Should(Exit())
	if spaceManager.ExitCode() != 0 {
		ExpectWithOffset(1, spaceManager.Out).Should(gbytes.Say("not authorized"))
	}

	spaceDeveloper := internal.Cf(uc.CommandStarter, "set-space-role", username, orgName, spaceName, "SpaceDeveloper")
	EventuallyWithOffset(1, spaceDeveloper, uc.Timeout).Should(Exit())
	if spaceDeveloper.ExitCode() != 0 {
		ExpectWithOffset(1, spaceDeveloper.Out).Should(gbytes.Say("not authorized"))
	}

	spaceAuditor := internal.Cf(uc.CommandStarter, "set-space-role", username, orgName, spaceName, "SpaceAuditor")
	EventuallyWithOffset(1, spaceAuditor, uc.Timeout).Should(Exit())
	if spaceAuditor.ExitCode() != 0 {
		ExpectWithOffset(1, spaceAuditor.Out).Should(gbytes.Say("not authorized"))
	}
}

func (uc UserContext) Logout() {
	session := internal.Cf(uc.CommandStarter, "logout")
	EventuallyWithOffset(1, session, uc.Timeout).Should(Exit(0))
}

func (uc UserContext) UnsetCfHomeDir(originalCfHomeDir, currentCfHomeDir string) {
	os.Setenv("CF_HOME", originalCfHomeDir)
	os.RemoveAll(currentCfHomeDir)
}
