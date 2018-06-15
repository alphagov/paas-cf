package scripts_test

import (
	"fmt"
	"path/filepath"
	"strings"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"io/ioutil"
	"os"
	"os/exec"

	"github.com/onsi/gomega/gexec"
)

const (
	ExecutionTimeout = 30 * time.Second
)

var _ = Describe("TagRelease", func() {

	var (
		workingDirectory string
		originRepoPath   string
		baseCmd          *exec.Cmd
	)

	BeforeEach(func() {
		gitVersionCommand := exec.Command("git", "--version")

		session, err := gexec.Start(gitVersionCommand, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
		Eventually(session, ExecutionTimeout).Should(gexec.Exit(0))
		Expect(string(session.Out.Contents())).To(MatchRegexp(".* [2-9]\\.[0-9]+\\.[0-9]+.*"), "Expected git version 2.0.0 or bigger")
		Expect(string(session.Err.Contents())).To(BeEmpty())
	})

	BeforeEach(func() {
		workingDirectory, baseCmd = prepareWorkingDirectory(
			"./tag_release.sh",
		)

		prepareSshKeys(baseCmd)
		configGitEmailAndName(baseCmd)

		originRepoPath = setupClonedRepository(baseCmd)
		baseCmd.Env = append(baseCmd.Env, fmt.Sprintf("GIT_REPO_URL=%s", originRepoPath))
	})

	AfterEach(func() {
		cleanUpWorkingDirectory(workingDirectory)
	})

	Describe("when creating a new tag (tag_filter not set)", func() {
		BeforeEach(func() {
			runBashScript(baseCmd, `
				cd origin_repo

				git commit --allow-empty -m "First commit"
				git tag next-0.0.1
				git commit --allow-empty -m "Second commit"
			`)

			runBashScript(baseCmd, `
				mkdir release-version
				printf '0.0.42' > release-version/number
			`)
		})

		It("creates a tag using the given tag_prefix and version, and pushes it", func() {
			cloneRepository(baseCmd, "paas-cf")
			runBashScript(baseCmd, `
				./tag_release.sh next- test_aws_account test_env ""
			`)

			session := runBashScript(baseCmd, `
				cd paas-cf
				git tag -l "next-*"
			`)
			Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.42"))

			cloneRepository(baseCmd, "paas-cf-new")
			session = runBashScript(baseCmd, `
				cd paas-cf-new
				git tag -l "next-*"
			`)
			Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.42"))
		})

		It("skips tagging when HEAD is already tagged using the given tag_prefix", func() {
			runBashScript(baseCmd, `
				cd origin_repo
				git tag next-0.0.40
			`)
			cloneRepository(baseCmd, "paas-cf")
			runBashScript(baseCmd, `
				./tag_release.sh next- test_aws_account test_env ""
			`)

			session := runBashScript(baseCmd, `
				cd paas-cf
				git tag -l "next-*"
			`)
			Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.42"))
		})

		It("tags the HEAD revision of the checked out repo", func() {
			cloneRepository(baseCmd, "paas-cf")
			session := runBashScript(baseCmd, `
				cd paas-cf
				git commit --quiet --allow-empty -m "Third commit"
				git checkout --quiet HEAD^
				git rev-parse HEAD
			`)
			expectedCommitHash := strings.TrimSpace(string(session.Out.Contents()))
			runBashScript(baseCmd, `
				./tag_release.sh next- test_aws_account test_env ""
			`)

			session = runBashScript(baseCmd, `
				cd paas-cf
				git rev-list -n 1 next-0.0.42
			`)
			actualCommitHash := strings.TrimSpace(string(session.Out.Contents()))
			Expect(actualCommitHash).To(Equal(expectedCommitHash))
		})

		Context("if the remote copy of the origin repo already has the new tag, but the local copy not", func() {
			BeforeEach(func() {
				cloneRepository(baseCmd, "paas-cf")
				runBashScript(baseCmd, `
					cd origin_repo
					git tag next-0.0.42
				`)
			})

			It("should skip but not fail while promoting tag to 'next-*'", func() {
				session := runBashScript(baseCmd, `
					./tag_release.sh next- test_aws_account test_env "previous-*"
				`)

				Expect(string(session.Out.Contents())).To(
					ContainSubstring("WARNING: already tagged to current commit for environment"),
				)

				session = runBashScript(baseCmd, `
					cd paas-cf
					git tag -l "next-*"
				`)
				Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.42"))
			})
		})
	})

	Describe("when promoting previous tags (tag_filter is set)", func() {
		BeforeEach(func() {
			runBashScript(baseCmd, `
				cd origin_repo

				git commit --allow-empty -m "First commit"
				git tag previous-0.0.1

				git commit --allow-empty -m "Second commit"
				git tag previous-0.0.2
			`)
		})

		It("promotes the tag matching the tag_filter", func() {
			cloneRepository(baseCmd, "paas-cf")

			runBashScript(baseCmd, `
				./tag_release.sh next- test_aws_account test_env "previous-*"
			`)

			session := runBashScript(baseCmd, `
				cd paas-cf
				git tag -l "next-*"
			`)
			Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.2"))
			Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.1"))
		})

		It("promotes the tag pointing at the HEAD commit", func() {
			cloneRepository(baseCmd, "paas-cf")
			runBashScript(baseCmd, `
				cd paas-cf
				git checkout previous-0.0.1
			`)

			runBashScript(baseCmd, `
				./tag_release.sh next- test_aws_account test_env "previous-*"
			`)

			session := runBashScript(baseCmd, `
				cd paas-cf
				git tag -l "next-*"
			`)
			Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.1"))
			Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.2"))
		})

		It("creates the new tag pointing at the correct revision", func() {
			cloneRepository(baseCmd, "paas-cf")
			session := runBashScript(baseCmd, `
				cd paas-cf
				git checkout --quiet previous-0.0.1
				git rev-parse HEAD
			`)
			expectedCommitHash := strings.TrimSpace(string(session.Out.Contents()))

			runBashScript(baseCmd, `
				./tag_release.sh next- test_aws_account test_env "previous-*"
			`)

			session = runBashScript(baseCmd, `
				cd paas-cf
				git rev-list -n 1 next-0.0.1
			`)
			actualCommitHash := strings.TrimSpace(string(session.Out.Contents()))
			Expect(actualCommitHash).To(Equal(expectedCommitHash))
		})

		Context("when there are multiple 'previous-*' tags pointing at the same commit", func() {
			BeforeEach(func() {
				runBashScript(baseCmd, `
					cd origin_repo
					git commit --allow-empty -m "Third commit"
					git tag previous-0.0.3
					git tag previous-0.0.4
				`)
			})

			It("promotes the highest versioned tag pointing at HEAD", func() {
				cloneRepository(baseCmd, "paas-cf")

				runBashScript(baseCmd, `
					./tag_release.sh next- test_aws_account test_env "previous-*"
				`)

				session := runBashScript(baseCmd, `
					cd paas-cf
					git tag -l "next-*"
				`)
				Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.4"))
				Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.3"))
				Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.1"))
				Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.2"))
			})

			It("uses semver ordering to pick the highest tag", func() {
				runBashScript(baseCmd, `
					cd origin_repo
					git tag previous-0.0.11
				`)
				cloneRepository(baseCmd, "paas-cf")

				runBashScript(baseCmd, `
					./tag_release.sh next- test_aws_account test_env "previous-*"
				`)

				session := runBashScript(baseCmd, `
					cd paas-cf
					git tag -l "next-*"
				`)
				Expect(string(session.Out.Contents())).To(ContainSubstring("next-0.0.11"))
				Expect(string(session.Out.Contents())).NotTo(ContainSubstring("next-0.0.4"))
			})
		})
	})
})

func bashScript(baseCmd *exec.Cmd, script string) *exec.Cmd {
	cmd := &exec.Cmd{}
	*cmd = *baseCmd
	cmd.Path = "/bin/bash"
	cmd.Args = []string{cmd.Path, "-e", "-u", "-c", script}
	return cmd
}

func runBashScript(baseCmd *exec.Cmd, script string) *gexec.Session {
	cmd := bashScript(baseCmd, script)
	session, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
	Expect(err).ToNot(HaveOccurred())
	Eventually(session, ExecutionTimeout).Should(gexec.Exit(0))
	return session
}

func prepareWorkingDirectory(blobsToCopy ...string) (string, *exec.Cmd) {
	workingDirectory, err := ioutil.TempDir("", "tagReleaseTest")
	Expect(err).ToNot(HaveOccurred())

	cmd := &exec.Cmd{
		Dir: workingDirectory,
		Env: append([]string{}, fmt.Sprintf("HOME=%s", workingDirectory)),
	}

	for _, blobToCopy := range blobsToCopy {
		cmd := exec.Command("cp", "-pPR", blobToCopy, workingDirectory)
		_, err := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
	}

	return workingDirectory, cmd
}

func cleanUpWorkingDirectory(workingDirectory string) {
	os.RemoveAll(workingDirectory)
}

func prepareSshKeys(baseCmd *exec.Cmd) {
	runBashScript(baseCmd, `
		mkdir -p git-keys
		cd git-keys
		ssh-keygen -f git-key -N ""
		tar -cvzf git-keys.tar.gz git-key git-key.pub
	`)
}

func configGitEmailAndName(baseCmd *exec.Cmd) {
	runBashScript(baseCmd, `
		git config --global user.email "you@example.com"
		git config --global user.name "Your Name"
	`)
}

func setupClonedRepository(baseCmd *exec.Cmd) string {
	runBashScript(baseCmd, `
		mkdir origin_repo
		cd origin_repo
		git init .
	`)
	originRepoPath := filepath.Join(baseCmd.Dir, "origin_repo")
	return originRepoPath
}

func cloneRepository(baseCmd *exec.Cmd, target string) {
	runBashScript(baseCmd, fmt.Sprintf(`
		git clone origin_repo %s
		cd %s
		git fetch --tags
	`, target, target))
}
