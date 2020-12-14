package main_test

import (
	"os/exec"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
)

var _ = Describe("pipecleaner", func() {
	const runTimeout = 5 * time.Second

	var (
		toolpath string
		command  *exec.Cmd
		session  *gexec.Session
	)

	BeforeSuite(func() {
		var err error
		toolpath, err = gexec.Build("github.com/alphagov/paas-cf/tools/pipecleaner")
		Expect(err).NotTo(HaveOccurred())
	})

	JustBeforeEach(func() {
		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
		session.Wait(runTimeout)
	})

	Context("when run with no arguments, get usage", func() {
		BeforeEach(func() {
			command = exec.Command(toolpath)
		})

		It("should return non-zero, and print usage", func() {
			Expect(session).To(gexec.Exit(2))
			Expect(session).To(gbytes.Say("pipecleaner"))
			Expect(session).To(gbytes.Say("usage"))
			Expect(session).To(gbytes.Say("flags"))
		})
	})

	Context("when given a file which does not exist", func() {
		BeforeEach(func() {
			command = exec.Command(toolpath, "fixtures/pipecleaner_404.yml")
		})

		It("should report an error", func() {
			Expect(session).To(gexec.Exit(10))
			Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_404.yml"))
			Expect(session).To(gbytes.Say("PARSE error"))
			Expect(session).To(gbytes.Say("open fixtures/pipecleaner_404.yml: no such file or directory"))
		})
	})

	Context("when given invalid yaml", func() {
		BeforeEach(func() {
			command = exec.Command(toolpath, "fixtures/pipecleaner_invalid.yml")
		})

		It("should report an error", func() {
			Expect(session).To(gexec.Exit(10))
			Expect(session).To(gbytes.Say("PARSE error"))
		})
	})

	Context("shellcheck", func() {
		Context("when there is an non-portable compare ", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_shellcheck.yml")
			})

			It("should report an error", func() {
				Expect(session).To(gexec.Exit(10))

				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_shellcheck.yml"))

				Expect(session).To(gbytes.Say("JOB shellcheck"))
				Expect(session).To(gbytes.Say("TASK bad-compare"))
				Expect(session).To(gbytes.Say("SHELLCHECK"))
				Expect(session).To(gbytes.Say("SC2039 on line 2 on column 12: In POSIX sh, == in place of = is undefined[.]"))
				Expect(session).To(gbytes.Say("SC2050 on line 2 on column 12: This expression is constant. Did you forget the [$] on a variable[?]"))
			})
		})

		Context("when the shell script has no problems", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_shellcheck_params.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_shellcheck_params.yml"))
			})
		})
	})

	Context("secret-interpolation", func() {
		Context("when there's a param that looks like a secret but is not interpolated", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_secrets_interpolation.yml")
			})

			It("should report an error", func() {
				Expect(session).To(gexec.Exit(10))

				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_secrets_interpolation.yml"))

				Expect(session).To(gbytes.Say("RESOURCE my-git-repo"))
				Expect(session).To(gbytes.Say("SECRETS"))
				Expect(session).To(gbytes.Say("Resource source param private_key is not interpolated and may leak credentials"))

				Expect(session).To(gbytes.Say("JOB secrets-interpolate"))
				Expect(session).To(gbytes.Say("TASK bad-secrets-interpolate"))
				Expect(session).To(gbytes.Say("SECRETS"))
				// We are iterating over maps of params, secrets are returned unordered
				Expect(session.Buffer().Contents()).To(SatisfyAll(
					ContainSubstring("Task config param SECRET_PARAM_CONFIG is not interpolated and may leak credentials"),
					ContainSubstring("Task config param CONFIG_PARAM_KEY is not interpolated and may leak credentials"),
					ContainSubstring("Task config param CONFIG_PARAM_SECRET is not interpolated and may leak credentials"),
					ContainSubstring("Task config param SECRET_PARAM_TASK is not interpolated and may leak credentials"),
					ContainSubstring("Task config param TASK_PARAM_KEY is not interpolated and may leak credentials"),
					ContainSubstring("Task config param TASK_PARAM_SECRET is not interpolated and may leak credentials"),
				))
				Expect(session.Buffer().Contents()).To(SatisfyAll(
					Not(ContainSubstring("ABS_KEY_FILE_PATH")),
					Not(ContainSubstring("RELATIVE_KEY_FILE_PATH")),
					Not(ContainSubstring("PARENT_KEY_FILE_PATH")),

					Not(ContainSubstring("PUBLIC_KEY_IS_OKAY")),
					Not(ContainSubstring("EMPTY_SECRET_IS_OKAY")),
				))
			})
		})
	})

	Context("rubocop", func() {
		Context("when there are filthy semicolons", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_rubocop_semicolons.yml")
			})

			It("should report an error", func() {
				Expect(session).To(gexec.Exit(10))

				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_rubocop_semicolons.yml"))

				Expect(session).To(gbytes.Say("JOB rubocop"))
				Expect(session).To(gbytes.Say("TASK semicolons"))
				Expect(session).To(gbytes.Say("RUBOCOP"))
				Expect(session).To(gbytes.Say("Style/Semicolon on line 1 on column 1"))
				Expect(session).To(gbytes.Say("Do not use semicolons to terminate expressions"))
			})
		})

		Context("when the ruby script has no problems", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_rubocop.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_rubocop.yml"))
			})
		})
	})

	Context("all resources should be used in jobs", func() {
		Context("when there resources not used as inputs or triggers", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_all_resources_not_used.yml")
			})

			It("should report an error", func() {
				Expect(session).To(gexec.Exit(10))

				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_all_resources_not_used.yml"))

				Expect(session).To(gbytes.Say("JOB forget-to-use-resource"))
				Expect(session).To(gbytes.Say("ALL-RESOURCES-USED"))
				Expect(session).To(gbytes.Say("Resource my-git-repo is never used"))
			})
		})

		Context("when all resources are used as inputs", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_all_resources_used.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_all_resources_used.yml"))
			})
		})

		Context("when all resources are used as triggers", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_all_resources_used_to_trigger.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_all_resources_used_to_trigger.yml"))
			})
		})

		Context("when all resources are used as triggers with a passed gate", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_all_resources_used_passed.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_all_resources_used_passed.yml"))
			})
		})

		Context("when all resources are used with a task file", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_all_resources_used_task.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_all_resources_used_task.yml"))
			})
		})

		Context("when all resources are used as image", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_all_resources_used_image.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_all_resources_used_image.yml"))
			})
		})

		Context("when set_pipeline is used", func() {
			BeforeEach(func() {
				command = exec.Command(toolpath, "fixtures/pipecleaner_set_pipeline.yml")
			})

			It("should not report an issue", func() {
				Expect(session).To(gexec.Exit(0))
				Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_set_pipeline.yml"))
			})
		})

		Context("linting tasks", func() {
			Context("rubocop", func() {
				Context("when there is a bad compare", func() {
					BeforeEach(func() {
						command = exec.Command(toolpath, "fixtures/pipecleaner_task_rubocop_semicolons.yml")
					})

					It("should report an error", func() {
						Expect(session).To(gexec.Exit(10))

						Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_task_rubocop_semicolons.yml"))

						Expect(session).To(gbytes.Say("RUBOCOP"))
						Expect(session).To(gbytes.Say("Style/Semicolon on line 1 on column 1"))
						Expect(session).To(gbytes.Say("Do not use semicolons to terminate expressions"))
					})
				})

				Context("when there are no errors", func() {
					BeforeEach(func() {
						command = exec.Command(toolpath, "fixtures/pipecleaner_task_rubocop.yml")
					})

					It("should report an error", func() {
						Expect(session).To(gexec.Exit(0))

						Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_task_rubocop.yml"))
					})
				})
			})

			Context("shellcheck", func() {
				Context("when there is a bad compare", func() {
					BeforeEach(func() {
						command = exec.Command(toolpath, "fixtures/pipecleaner_task_shellcheck.yml")
					})

					It("should report an error", func() {
						Expect(session).To(gexec.Exit(10))

						Expect(session).To(gbytes.Say("FILE fixtures/pipecleaner_task_shellcheck.yml"))

						Expect(session).To(gbytes.Say("SHELLCHECK"))
						Expect(session).To(gbytes.Say("SC2039 on line 2 on column 12: In POSIX sh, == in place of = is undefined[.]"))
						Expect(session).To(gbytes.Say("SC2050 on line 2 on column 12: This expression is constant. Did you forget the [$] on a variable[?]"))
					})
				})
			})
		})
	})
})
