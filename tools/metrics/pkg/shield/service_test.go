package shield_test

import (
	"github.com/alphagov/paas-cf/tools/metrics/pkg/shield"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/shield/fakes"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/gomega"
	"time"

	awsshield "github.com/aws/aws-sdk-go/service/shield"
)

var _ = Describe("ShieldService", func() {

	var (
		shieldAPI     fakes.FakeShieldAPI
		shieldService shield.ShieldService
	)

	BeforeEach(func() {
		shieldAPI = fakes.FakeShieldAPI{}
		shieldService = shield.ShieldService{Client: &shieldAPI}
	})

	It("is", func() {
		Expect(true).To(BeTrue())
	})

	Describe("CountOnGoingAttacks", func() {
		It("looks for attacks with a start time in the past, and an end time in the future", func() {
			shieldAPI.ListAttacksReturns(&awsshield.ListAttacksOutput{
				AttackSummaries: []*awsshield.AttackSummary{},
			}, nil)

			_, err := shieldService.CountOnGoingAttacks()
			Expect(err).ToNot(HaveOccurred())

			Expect(shieldAPI.ListAttacksCallCount()).To(Equal(1))
			callZero := shieldAPI.ListAttacksArgsForCall(0)
			Expect(*callZero.StartTime.FromInclusive).To(BeTemporally("<=", time.Now()))
			Expect(*callZero.EndTime.ToExclusive).To(BeTemporally(">", time.Now()))
		})

		It("returns the count of ongoing attacks", func() {
			future := time.Now().Add(1 * time.Hour)
			past := time.Now().Add(-1 * time.Hour)
			shieldAPI.ListAttacksReturns(&awsshield.ListAttacksOutput{
				AttackSummaries: []*awsshield.AttackSummary{
					&awsshield.AttackSummary{
						AttackId: aws.String("attacker-1"),
						AttackVectors: []*awsshield.AttackVectorDescription{
							&awsshield.AttackVectorDescription{VectorType: aws.String("REQUEST_FLOOD")},
						},
						EndTime:     &future,
						ResourceArn: aws.String("an ARN"),
						StartTime:   &past,
					},
					&awsshield.AttackSummary{
						AttackId: aws.String("attacker-2"),
						AttackVectors: []*awsshield.AttackVectorDescription{
							&awsshield.AttackVectorDescription{VectorType: aws.String("DNS_REFLECTION")},
						},
						EndTime:     &future,
						ResourceArn: aws.String("another ARN"),
						StartTime:   &past,
					},
				},
			}, nil)

			count, err := shieldService.CountOnGoingAttacks()
			Expect(err).ToNot(HaveOccurred())

			Expect(count).To(Equal(2))
		})
	})
})
