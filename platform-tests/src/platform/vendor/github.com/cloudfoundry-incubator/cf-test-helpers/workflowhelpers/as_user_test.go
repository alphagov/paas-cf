package workflowhelpers_test

import (
	"os"
	"os/exec"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gexec"
)

type fakeUserContext struct {
	NumLoginCalls          int
	NumSetCfHomeDirCalls   int
	NumLogoutCalls         int
	NumUnsetCfHomeDirCalls int
	NumTargetSpaceCalls    int
}

func (f *fakeUserContext) SetCfHomeDir() (string, string) {
	f.NumSetCfHomeDirCalls += 1
	return "", ""
}

func (f *fakeUserContext) Login() {
	f.NumLoginCalls += 1
}

func (f *fakeUserContext) Logout() {
	f.NumLogoutCalls += 1
}

func (f *fakeUserContext) UnsetCfHomeDir(string, string) {
	f.NumUnsetCfHomeDirCalls += 1
}

func (f *fakeUserContext) TargetSpace() {
	f.NumTargetSpaceCalls += 1
}

var _ = Describe("AsUser", func() {
	var (
		timeout               = 1 * time.Second
		FakeThingsToRunAsUser = func() {}
		FakeCfCalls           = [][]string{}
	)

	var FakeCf = func(args ...string) *gexec.Session {
		FakeCfCalls = append(FakeCfCalls, args)
		var session, _ = gexec.Start(exec.Command("echo", "nothing"), nil, nil)
		return session
	}

	var user *fakeUserContext

	BeforeEach(func() {
		FakeCfCalls = [][]string{}
		cf.Cf = FakeCf

		user = new(fakeUserContext)
	})

	It("logs the user in", func() {
		workflowhelpers.AsUser(user, timeout, FakeThingsToRunAsUser)
		Expect(user.NumLoginCalls).To(Equal(1))
	})

	It("sets the cf home dir", func() {
		workflowhelpers.AsUser(user, timeout, FakeThingsToRunAsUser)
		Expect(user.NumSetCfHomeDirCalls).To(Equal(1))
	})

	It("targets the correct space and org", func() {
		workflowhelpers.AsUser(user, timeout, FakeThingsToRunAsUser)
		Expect(user.NumTargetSpaceCalls).To(Equal(1))
	})

	It("calls cf logout", func() {
		workflowhelpers.AsUser(user, timeout, FakeThingsToRunAsUser)
		Expect(user.NumLogoutCalls).To(Equal(1))
	})

	It("logs out even if actions contain a failing expectation", func() {
		RegisterFailHandler(func(message string, callerSkip ...int) {})
		workflowhelpers.AsUser(user, timeout, func() { Expect(1).To(Equal(2)) })
		RegisterFailHandler(Fail)
		Expect(user.NumLogoutCalls).To(Equal(1))
	})

	It("calls the passed function", func() {
		called := false
		workflowhelpers.AsUser(user, timeout, func() { called = true })

		Expect(called).To(BeTrue())
	})

	It("returns CF_HOME to its original value", func() {
		os.Setenv("CF_HOME", "some-crazy-value")
		workflowhelpers.AsUser(user, timeout, func() {})
		Expect(os.Getenv("CF_HOME")).To(Equal("some-crazy-value"))
	})
})
