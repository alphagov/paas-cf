package cloudfront_test

import (
	"errors"

	"github.com/aws/aws-sdk-go/aws"
	awscf "github.com/aws/aws-sdk-go/service/cloudfront"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront/fakes"
)

var _ = Describe("CloudFront", func() {
	var (
		fakeClient            *fakes.FakeCloudFrontAPI
		cfs                   *cloudfront.CloudFrontService
		distributionSummaries []*awscf.DistributionSummary
	)

	BeforeEach(func() {
		fakeClient = &fakes.FakeCloudFrontAPI{}
		cfs = &cloudfront.CloudFrontService{
			Client: fakeClient,
		}

		distributionSummaries = []*awscf.DistributionSummary{
			&awscf.DistributionSummary{
				Enabled:    aws.Bool(true),
				DomainName: aws.String("d1.cloudfront.aws"),
				Id:         aws.String("dist-1"),
				Aliases: &awscf.Aliases{
					Quantity: aws.Int64(2),
					Items: []*string{
						aws.String("s1.service.gov.uk"),
					},
				},
			},
			&awscf.DistributionSummary{
				Enabled:    aws.Bool(true),
				DomainName: aws.String("d2.cloudfront.aws"),
				Id:         aws.String("dist-2"),
				Aliases: &awscf.Aliases{
					Quantity: aws.Int64(2),
					Items: []*string{
						aws.String("s2.service.gov.uk"),
						aws.String("s3.service.gov.uk"),
					},
				},
			},
		}
	})

	It("lists all custom domains", func() {
		fakeClient.ListDistributionsPagesStub = func(
			input *awscf.ListDistributionsInput,
			fn func(*awscf.ListDistributionsOutput, bool) bool,
		) error {
			for i, distributionSummary := range distributionSummaries {
				page := &awscf.ListDistributionsOutput{
					DistributionList: &awscf.DistributionList{
						Items: []*awscf.DistributionSummary{
							distributionSummary,
						},
					},
				}
				if !fn(page, i+1 >= len(distributionSummaries)) {
					break
				}
			}
			return nil
		}

		domains, err := cfs.CustomDomains()
		Expect(err).ToNot(HaveOccurred())
		Expect(domains).To(Equal([]cloudfront.CustomDomain{
			{
				CloudFrontDomain: "d1.cloudfront.aws",
				AliasDomain:      "s1.service.gov.uk",
				DistributionId:   "dist-1",
			},
			{
				CloudFrontDomain: "d2.cloudfront.aws",
				AliasDomain:      "s2.service.gov.uk",
				DistributionId:   "dist-2",
			},
			{
				CloudFrontDomain: "d2.cloudfront.aws",
				AliasDomain:      "s3.service.gov.uk",
				DistributionId:   "dist-2",
			},
		}))
	})

	Context("when there are no CloudFront distributions", func() {
		It("lists all custom domains", func() {
			fakeClient.ListDistributionsPagesStub = func(
				input *awscf.ListDistributionsInput,
				fn func(*awscf.ListDistributionsOutput, bool) bool,
			) error {
				return nil
			}

			domains, err := cfs.CustomDomains()
			Expect(err).ToNot(HaveOccurred())
			Expect(domains).To(BeNil())
		})
	})

	Context("when CloudFront API returns an error", func() {
		cloudFrontErr := errors.New("some error")
		It("should return the error", func() {
			fakeClient.ListDistributionsPagesStub = func(
				input *awscf.ListDistributionsInput,
				fn func(*awscf.ListDistributionsOutput, bool) bool,
			) error {
				return cloudFrontErr
			}

			_, err := cfs.CustomDomains()
			Expect(err).To(MatchError(cloudFrontErr))
		})
	})

})
