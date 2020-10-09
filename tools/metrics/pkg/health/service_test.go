package health_test

import (
	"errors"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/health/fakes"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/health"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	awshealth "github.com/aws/aws-sdk-go/service/health"
)

var _ = Describe("Service", func() {
	Describe("CountOpenEventsForServiceInRegion", func() {

		var (
			healthAPI fakes.FakeHealthAPI
			healthService health.HealthService
		)

		BeforeEach(func() {
			healthAPI = fakes.FakeHealthAPI{}
			healthService = health.HealthService{Client: &healthAPI}
		})

		It("finds events that are open", func() {
			healthAPI.DescribeEventsReturns(&awshealth.DescribeEventsOutput{
				Events:    []*awshealth.Event{},
			}, nil)

			_ , err := healthService.CountOpenEventsForServiceInRegion("EC2", "eu-west-1")

			Expect(err).ToNot(HaveOccurred())
			Expect(healthAPI.DescribeEventsCallCount()).To(Equal(1))

			callZero := healthAPI.DescribeEventsArgsForCall(0)
			Expect(callZero.Filter.EventStatusCodes).To(ConsistOf(aws.String(awshealth.EventStatusCodeOpen)))
		})

		It("finds events relating to the given service", func() {
			healthAPI.DescribeEventsReturns(&awshealth.DescribeEventsOutput{
				Events:    []*awshealth.Event{},
			}, nil)

			_ , err := healthService.CountOpenEventsForServiceInRegion("EC2", "eu-west-1")

			Expect(err).ToNot(HaveOccurred())
			Expect(healthAPI.DescribeEventsCallCount()).To(Equal(1))

			callZero := healthAPI.DescribeEventsArgsForCall(0)
			Expect(callZero.Filter.Services).To(ConsistOf(aws.String("EC2")))
		})

		It("finds events relating to the given region", func() {
			healthAPI.DescribeEventsReturns(&awshealth.DescribeEventsOutput{
				Events:    []*awshealth.Event{},
			}, nil)

			_ , err := healthService.CountOpenEventsForServiceInRegion("EC2", "eu-west-1")

			Expect(err).ToNot(HaveOccurred())
			Expect(healthAPI.DescribeEventsCallCount()).To(Equal(1))

			callZero := healthAPI.DescribeEventsArgsForCall(0)
			Expect(callZero.Filter.Regions).To(ConsistOf(aws.String("eu-west-1")))
		})

		It("returns a count of -1 when an error occurs", func() {
			healthAPI.DescribeEventsReturns(&awshealth.DescribeEventsOutput{}, errors.New("whoops"))

			count , err := healthService.CountOpenEventsForServiceInRegion("EC2", "eu-west-1")

			Expect(err).To(HaveOccurred())
			Expect(count).To(Equal(-1))
		})
	})
})
