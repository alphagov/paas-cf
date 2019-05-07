package emails_test

import (
	"github.com/alphagov/paas-cf/tools/user_emails/emails"
	"github.com/alphagov/paas-cf/tools/user_emails/emails/stubs"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Emails", func() {
	Context("with 'normal' urgency", func(){
		It("gets the spaces for each organisation", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			emails.FetchEmails(&cfFake, false)
			Expect(cfFake.ListSpacesByQueryCallCount()).To(Equal(3))
		})

		It("extracts the username of each space developer in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false)
			Expect(names).To(ContainElement("user-1@paas.gov"))
			Expect(names).To(ContainElement("user-2@paas.gov"))
			Expect(names).To(ContainElement("user-3@paas.gov"))
		})

		It("only returns usernames which are valid email addresses", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false)
			Expect(names).ToNot(ContainElement("admin"))
		})

		It("catches addresses that are known to be problematic", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false)
			Expect(names).To(ContainElement("test@homeoffice.x.gsi.gov.uk"))
		})

		It("de-duplicates email addresses", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false)
			Expect(names).To(HaveLen(4))

			i := 0
			for _, value := range names {
				if value == "user-1@paas.gov"{
					i++
				}
			}
			Expect(i).To(Equal(1))
		})
	})

	Context("with 'critical' urgency", func(){
		It("includes the username of each org manager", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true)
			Expect(names).To(ContainElement("org-1-manager-1@paas.gov"))
			Expect(names).To(ContainElement("org-1-manager-2@paas.gov"))
			Expect(names).To(ContainElement("org-2-manager-1@paas.gov"))
			Expect(names).To(ContainElement("org-3-manager-1@paas.gov"))
		})

		It("includes the username of each org auditor", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true)
			Expect(names).To(ContainElement("org-1-auditor-1@paas.gov"))
			Expect(names).To(ContainElement("org-1-auditor-2@paas.gov"))
			Expect(names).To(ContainElement("org-2-auditor-1@paas.gov"))
			Expect(names).To(ContainElement("org-3-auditor-1@paas.gov"))
		})

		It("includes the username of each space manager in each space", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true)
			Expect(names).To(ContainElement("org-1-space-1-manager-1@paas.gov"))
			Expect(names).To(ContainElement("org-1-space-1-manager-2@paas.gov"))
			Expect(names).To(ContainElement("org-2-space-1-manager-1@paas.gov"))
			Expect(names).To(ContainElement("org-3-space-1-manager-1@paas.gov"))
		})

		It("includes the username of each space auditor in each space", func(){
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true)
			Expect(names).To(ContainElement("org-1-space-1-auditor-1@paas.gov"))
			Expect(names).To(ContainElement("org-1-space-1-auditor-2@paas.gov"))
			Expect(names).To(ContainElement("org-2-space-1-auditor-1@paas.gov"))
			Expect(names).To(ContainElement("org-3-space-1-auditor-1@paas.gov"))
		})

		It("includes the username of each space developer in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true)
			Expect(names).To(ContainElement("user-1@paas.gov"))
			Expect(names).To(ContainElement("user-2@paas.gov"))
			Expect(names).To(ContainElement("user-3@paas.gov"))
		})
	})
})
