package internal

import (
	"fmt"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/onsi/ginkgo"
	ginkgoconfig "github.com/onsi/ginkgo/config"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

type TestUser struct {
	username       string
	password       string
	cmdStarter     internal.Starter
	timeout        time.Duration
	shouldKeepUser bool
}

type userConfig interface {
	GetUseExistingUser() bool
	GetExistingUser() string
	GetExistingUserPassword() string
	GetConfigurableTestPassword() string
	GetScaledTimeout(time.Duration) time.Duration
	GetShouldKeepUser() bool
	GetNamePrefix() string
}

type adminuserConfig interface {
	GetAdminUser() string
	GetAdminPassword() string
}

func NewTestUser(config userConfig, cmdStarter internal.Starter) *TestUser {
	node := ginkgoconfig.GinkgoConfig.ParallelNode
	timeTag := time.Now().Format("2006_01_02-15h04m05.999s")

	var regUser, regUserPass string
	regUser = fmt.Sprintf("%s-USER-%d-%s", config.GetNamePrefix(), node, timeTag)
	regUserPass = "meow"

	if config.GetUseExistingUser() {
		regUser = config.GetExistingUser()
		regUserPass = config.GetExistingUserPassword()
	}

	if config.GetConfigurableTestPassword() != "" {
		regUserPass = config.GetConfigurableTestPassword()
	}

	return &TestUser{
		username:       regUser,
		password:       regUserPass,
		cmdStarter:     cmdStarter,
		timeout:        config.GetScaledTimeout(1 * time.Minute),
		shouldKeepUser: config.GetShouldKeepUser(),
	}
}

func NewAdminUser(config adminuserConfig, cmdStarter internal.Starter) *TestUser {
	return &TestUser{
		username:   config.GetAdminUser(),
		password:   config.GetAdminPassword(),
		cmdStarter: cmdStarter,
	}
}

func (user *TestUser) Create() {
	redactor := internal.NewRedactor(user.password)
	redactingReporter := internal.NewRedactingReporter(ginkgo.GinkgoWriter, redactor)

	session := internal.CfWithCustomReporter(user.cmdStarter, redactingReporter, "create-user", user.username, user.password)
	EventuallyWithOffset(1, session, user.timeout).Should(Exit())

	if session.ExitCode() != 0 {
		ExpectWithOffset(1, combineOutputAndRedact(session, redactor)).Should(Say("scim_resource_already_exists"))
	}
}

func (user *TestUser) Destroy() {
	session := internal.Cf(user.cmdStarter, "delete-user", "-f", user.username)
	EventuallyWithOffset(1, session, user.timeout).Should(Exit(0))
}

func (user *TestUser) Username() string {
	return user.username
}

func (user *TestUser) Password() string {
	return user.password
}

func (user *TestUser) ShouldRemain() bool {
	return user.shouldKeepUser
}

func combineOutputAndRedact(session *Session, redactor internal.Redactor) *Buffer {
	stdout := redactor.Redact(string(session.Out.Contents()))
	stderr := redactor.Redact(string(session.Err.Contents()))

	return BufferWithBytes(append([]byte(stdout), []byte(stderr)...))
}
