package internal_test

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Redactor", func() {
	Context("Does not redact", func() {
		It("if no redactees specified", func() {
			redactor := internal.NewRedactor()
			in := "whatever create-org foo"

			out := redactor.Redact(in)

			Expect(out).To(Equal("whatever create-org foo"))
		})

		It("if no matching redactees", func() {
			redactor := internal.NewRedactor("feh", "meh")
			in := "blah important"

			out := redactor.Redact(in)

			Expect(out).NotTo(ContainSubstring("[REDACTED]"))
			Expect(out).To(Equal("blah important"))
		})
	})

	Context("Redacts", func() {
		It("one value", func() {
			redactor := internal.NewRedactor("important")
			in := "blah important"

			out := redactor.Redact(in)

			Expect(out).NotTo(ContainSubstring("important"))
			Expect(out).To(Equal("blah [REDACTED]"))
		})

		It("strings with spaces", func() {
			redactor := internal.NewRedactor("sensitive secret")
			in := "command sensitive secret other"

			out := redactor.Redact(in)

			Expect(out).NotTo(ContainSubstring("sensitive"))
			Expect(out).NotTo(ContainSubstring("secret"))
			Expect(out).To(Equal("command [REDACTED] other"))

		})

		It("multiple values", func() {
			redactor := internal.NewRedactor("secret", "sensitive")
			in := "command sensitive secret other"

			out := redactor.Redact(in)

			Expect(out).NotTo(ContainSubstring("sensitive"))
			Expect(out).NotTo(ContainSubstring("secret"))
			Expect(out).To(Equal("command [REDACTED] [REDACTED] other"))
		})
	})
})
