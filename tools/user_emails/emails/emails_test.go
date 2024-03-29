package emails_test

import (
	"github.com/alphagov/paas-cf/tools/user_emails/emails"
	"github.com/alphagov/paas-cf/tools/user_emails/emails/stubs"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Emails", func() {
	Context("with 'normal' urgency", func() {
		It("gets the spaces for each organisation", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			emails.FetchEmails(&cfFake, false, false, "https://admin.example.com/organisations/", "prod")
			Expect(cfFake.ListSpacesByQueryCallCount()).To(Equal(3))
		})

		It("extracts the username of each space developer in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false, false, "https://admin.example.com/organisations/", "prod")
			Expect(len(names)).To(Equal(5))
			for _, item := range names {
				Expect(item.Email).ToNot(BeNil())
				Expect(item.Org).ToNot(BeNil())
				Expect(item.Role).To(ContainSubstring("Developer"))
				Expect(item.Admin).ToNot(BeNil())
				Expect(item.Region).ToNot(BeNil())
			}
		})

		It("only returns usernames which are valid email addresses", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false, false, "https://admin.example.com/organisations/", "prod")
			Expect(names).ToNot(ContainElement("admin"))
		})

		It("catches addresses that are known to be problematic", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false, false, "https://admin.example.com/organisations/", "prod")
			Expect(len(names)).To(Equal(5))
			Expect(names[3].Email).To(ContainSubstring("test@homeoffice.x.gsi.gov.uk"))
			Expect(names[3].Org).To(ContainSubstring("Org 2"))
			Expect(names[3].Role).To(ContainSubstring("Developer"))
			Expect(names[3].Admin).To(ContainSubstring("org-2"))
			Expect(names[3].Region).To(ContainSubstring("prod"))
		})
	})

	Context("with 'critical' urgency", func() {
		It("includes the username of each org manager", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true, false, "https://admin.example.com/organisations/", "prod")
			Expect(names[6].Email).To(ContainSubstring("org-1-manager-1@paas.gov"))
			Expect(names[6].Org).To(ContainSubstring("Org 1"))
			Expect(names[6].Role).To(ContainSubstring("Org Manager"))
			Expect(names[6].Admin).To(ContainSubstring("org-1"))
			Expect(names[6].Region).To(ContainSubstring("prod"))
			Expect(names[7].Email).To(ContainSubstring("org-1-manager-2@paas.gov"))
			Expect(names[7].Org).To(ContainSubstring("Org 1"))
			Expect(names[7].Role).To(ContainSubstring("Org Manager"))
			Expect(names[7].Admin).To(ContainSubstring("org-1"))
			Expect(names[7].Region).To(ContainSubstring("prod"))
			Expect(names[14].Email).To(ContainSubstring("org-2-manager-1@paas.gov"))
			Expect(names[14].Org).To(ContainSubstring("Org 2"))
			Expect(names[14].Role).To(ContainSubstring("Org Manager"))
			Expect(names[14].Admin).To(ContainSubstring("org-2"))
			Expect(names[14].Region).To(ContainSubstring("prod"))
			Expect(names[19].Email).To(ContainSubstring("org-3-manager-1@paas.gov"))
			Expect(names[19].Org).To(ContainSubstring("Org 3"))
			Expect(names[19].Role).To(ContainSubstring("Org Manager"))
			Expect(names[19].Admin).To(ContainSubstring("org-3"))
			Expect(names[19].Region).To(ContainSubstring("prod"))
		})

		It("includes the username of each org auditor", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true, false, "https://admin.example.com/organisations/", "prod")
			Expect(names[8].Email).To(ContainSubstring("org-1-auditor-1@paas.gov"))
			Expect(names[8].Org).To(ContainSubstring("Org 1"))
			Expect(names[8].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[8].Admin).To(ContainSubstring("org-1"))
			Expect(names[8].Region).To(ContainSubstring("prod"))
			Expect(names[9].Email).To(ContainSubstring("org-1-auditor-2@paas.gov"))
			Expect(names[9].Org).To(ContainSubstring("Org 1"))
			Expect(names[9].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[9].Admin).To(ContainSubstring("org-1"))
			Expect(names[9].Region).To(ContainSubstring("prod"))
			Expect(names[15].Email).To(ContainSubstring("org-2-auditor-1@paas.gov"))
			Expect(names[15].Org).To(ContainSubstring("Org 2"))
			Expect(names[15].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[15].Admin).To(ContainSubstring("org-2"))
			Expect(names[15].Region).To(ContainSubstring("prod"))
			Expect(names[20].Email).To(ContainSubstring("org-3-auditor-1@paas.gov"))
			Expect(names[20].Org).To(ContainSubstring("Org 3"))
			Expect(names[20].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[20].Admin).To(ContainSubstring("org-3"))
			Expect(names[20].Region).To(ContainSubstring("prod"))
		})

		It("includes the username of each space manager in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true, false, "https://admin.example.com/organisations/", "prod")
			Expect(names[2].Email).To(ContainSubstring("org-1-space-1-manager-1@paas.gov"))
			Expect(names[2].Org).To(ContainSubstring("Org 1"))
			Expect(names[2].Role).To(ContainSubstring("Space Manager"))
			Expect(names[2].Admin).To(ContainSubstring("org-1"))
			Expect(names[2].Region).To(ContainSubstring("prod"))
			Expect(names[3].Email).To(ContainSubstring("org-1-space-1-manager-2@paas.gov"))
			Expect(names[3].Org).To(ContainSubstring("Org 1"))
			Expect(names[3].Role).To(ContainSubstring("Space Manager"))
			Expect(names[3].Admin).To(ContainSubstring("org-1"))
			Expect(names[3].Region).To(ContainSubstring("prod"))
			Expect(names[12].Email).To(ContainSubstring("org-2-space-1-manager-1@paas.gov"))
			Expect(names[12].Org).To(ContainSubstring("Org 2"))
			Expect(names[12].Role).To(ContainSubstring("Space Manager"))
			Expect(names[12].Admin).To(ContainSubstring("org-2"))
			Expect(names[12].Region).To(ContainSubstring("prod"))
			Expect(names[17].Email).To(ContainSubstring("org-3-space-1-manager-1@paas.gov"))
			Expect(names[17].Org).To(ContainSubstring("Org 3"))
			Expect(names[17].Role).To(ContainSubstring("Space Manager"))
			Expect(names[17].Admin).To(ContainSubstring("org-3"))
			Expect(names[17].Region).To(ContainSubstring("prod"))
		})

		It("includes the username of each space auditor in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true, false, "https://admin.example.com/organisations/", "prod")
			Expect(names[4].Email).To(ContainSubstring("org-1-space-1-auditor-1@paas.gov"))
			Expect(names[4].Org).To(ContainSubstring("Org 1"))
			Expect(names[4].Role).To(ContainSubstring("Space Auditor"))
			Expect(names[4].Admin).To(ContainSubstring("org-1"))
			Expect(names[4].Region).To(ContainSubstring("prod"))
			Expect(names[5].Email).To(ContainSubstring("org-1-space-1-auditor-2@paas.gov"))
			Expect(names[5].Org).To(ContainSubstring("Org 1"))
			Expect(names[5].Role).To(ContainSubstring("Space Auditor"))
			Expect(names[5].Admin).To(ContainSubstring("org-1"))
			Expect(names[5].Region).To(ContainSubstring("prod"))
			Expect(names[13].Email).To(ContainSubstring("org-2-space-1-auditor-1@paas.gov"))
			Expect(names[13].Org).To(ContainSubstring("Org 2"))
			Expect(names[13].Role).To(ContainSubstring("Space Auditor"))
			Expect(names[13].Admin).To(ContainSubstring("org-2"))
			Expect(names[13].Region).To(ContainSubstring("prod"))
			Expect(names[18].Email).To(ContainSubstring("org-3-space-1-auditor-1@paas.gov"))
			Expect(names[18].Org).To(ContainSubstring("Org 3"))
			Expect(names[18].Role).To(ContainSubstring("Space Auditor"))
			Expect(names[18].Admin).To(ContainSubstring("org-3"))
			Expect(names[18].Region).To(ContainSubstring("prod"))
		})

		It("includes the username of each space developer in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, true, false, "https://admin.example.com/organisations/", "prod")
			Expect(names[0].Email).To(ContainSubstring("user-1@paas.gov"))
			Expect(names[0].Org).To(ContainSubstring("Org 1"))
			Expect(names[0].Role).To(ContainSubstring("Developer"))
			Expect(names[0].Admin).To(ContainSubstring("org-1"))
			Expect(names[0].Region).To(ContainSubstring("prod"))
			Expect(names[1].Email).To(ContainSubstring("user-2@paas.gov"))
			Expect(names[1].Org).To(ContainSubstring("Org 1"))
			Expect(names[1].Role).To(ContainSubstring("Developer"))
			Expect(names[1].Admin).To(ContainSubstring("org-1"))
			Expect(names[1].Region).To(ContainSubstring("prod"))
			Expect(names[16].Email).To(ContainSubstring("user-3@paas.gov"))
			Expect(names[16].Org).To(ContainSubstring("Org 3"))
			Expect(names[16].Role).To(ContainSubstring("Developer"))
			Expect(names[16].Admin).To(ContainSubstring("org-3"))
			Expect(names[16].Region).To(ContainSubstring("prod"))
		})
	})

	Context("with 'management' message", func() {
		It("includes the username of each org manager", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false, true, "https://admin.example.com/organisations/", "prod")
			Expect(names[0].Email).To(ContainSubstring("org-1-manager-1@paas.gov"))
			Expect(names[0].Org).To(ContainSubstring("Org 1"))
			Expect(names[0].Role).To(ContainSubstring("Org Manager"))
			Expect(names[0].Admin).To(ContainSubstring("org-1"))
			Expect(names[0].Region).To(ContainSubstring("prod"))
			Expect(names[1].Email).To(ContainSubstring("org-1-manager-2@paas.gov"))
			Expect(names[1].Org).To(ContainSubstring("Org 1"))
			Expect(names[1].Role).To(ContainSubstring("Org Manager"))
			Expect(names[1].Admin).To(ContainSubstring("org-1"))
			Expect(names[1].Region).To(ContainSubstring("prod"))
			Expect(names[6].Email).To(ContainSubstring("org-2-manager-1@paas.gov"))
			Expect(names[6].Org).To(ContainSubstring("Org 2"))
			Expect(names[6].Role).To(ContainSubstring("Org Manager"))
			Expect(names[6].Admin).To(ContainSubstring("org-2"))
			Expect(names[6].Region).To(ContainSubstring("prod"))
			Expect(names[9].Email).To(ContainSubstring("org-3-manager-1@paas.gov"))
			Expect(names[9].Org).To(ContainSubstring("Org 3"))
			Expect(names[9].Role).To(ContainSubstring("Org Manager"))
			Expect(names[9].Admin).To(ContainSubstring("org-3"))
			Expect(names[9].Region).To(ContainSubstring("prod"))
		})

		It("includes the username of each org auditor", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false, true, "https://admin.example.com/organisations/", "prod")
			Expect(names[2].Email).To(ContainSubstring("org-1-auditor-1@paas.gov"))
			Expect(names[2].Org).To(ContainSubstring("Org 1"))
			Expect(names[2].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[2].Admin).To(ContainSubstring("org-1"))
			Expect(names[2].Region).To(ContainSubstring("prod"))
			Expect(names[3].Email).To(ContainSubstring("org-1-auditor-2@paas.gov"))
			Expect(names[3].Org).To(ContainSubstring("Org 1"))
			Expect(names[3].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[3].Admin).To(ContainSubstring("org-1"))
			Expect(names[3].Region).To(ContainSubstring("prod"))
			Expect(names[7].Email).To(ContainSubstring("org-2-auditor-1@paas.gov"))
			Expect(names[7].Org).To(ContainSubstring("Org 2"))
			Expect(names[7].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[7].Admin).To(ContainSubstring("org-2"))
			Expect(names[7].Region).To(ContainSubstring("prod"))
			Expect(names[10].Email).To(ContainSubstring("org-3-auditor-1@paas.gov"))
			Expect(names[10].Org).To(ContainSubstring("Org 3"))
			Expect(names[10].Role).To(ContainSubstring("Org Auditor"))
			Expect(names[10].Admin).To(ContainSubstring("org-3"))
			Expect(names[10].Region).To(ContainSubstring("prod"))
		})

		It("includes the username of each org auditor", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			names := emails.FetchEmails(&cfFake, false, true, "https://admin.example.com/organisations/", "prod")
			Expect(names[4].Email).To(ContainSubstring("org-1-billing-manager-1@paas.gov"))
			Expect(names[4].Org).To(ContainSubstring("Org 1"))
			Expect(names[4].Role).To(ContainSubstring("Billing Manager"))
			Expect(names[4].Admin).To(ContainSubstring("org-1"))
			Expect(names[4].Region).To(ContainSubstring("prod"))
			Expect(names[5].Email).To(ContainSubstring("org-1-billing-manager-2@paas.gov"))
			Expect(names[5].Org).To(ContainSubstring("Org 1"))
			Expect(names[5].Role).To(ContainSubstring("Billing Manager"))
			Expect(names[5].Admin).To(ContainSubstring("org-1"))
			Expect(names[5].Region).To(ContainSubstring("prod"))
			Expect(names[8].Email).To(ContainSubstring("org-2-billing-manager-1@paas.gov"))
			Expect(names[8].Org).To(ContainSubstring("Org 2"))
			Expect(names[8].Role).To(ContainSubstring("Billing Manager"))
			Expect(names[8].Admin).To(ContainSubstring("org-2"))
			Expect(names[8].Region).To(ContainSubstring("prod"))
			Expect(names[11].Email).To(ContainSubstring("org-3-billing-manager-1@paas.gov"))
			Expect(names[11].Org).To(ContainSubstring("Org 3"))
			Expect(names[11].Role).To(ContainSubstring("Billing Manager"))
			Expect(names[11].Admin).To(ContainSubstring("org-3"))
			Expect(names[11].Region).To(ContainSubstring("prod"))
		})

	})
})
