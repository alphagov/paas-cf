package main_test

import (
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	esfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache/fakes"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Elasticache Updates Gauges", func() {
	var (
		fakeElasticache    *esfakes.FakeElastiCacheAPI
		elasticacheService *elasticache.ElasticacheService

		serviceUpdates                  []*awsec.ServiceUpdate
		describeServiceUpdatesPagesStub = func(
			input *awsec.DescribeServiceUpdatesInput,
			fn func(*awsec.DescribeServiceUpdatesOutput, bool) bool,
		) error {
			for i, serviceUpdate := range serviceUpdates {
				page := &awsec.DescribeServiceUpdatesOutput{
					ServiceUpdates: []*awsec.ServiceUpdate{serviceUpdate},
				}
				if !fn(page, i+1 >= len(serviceUpdates)) {
					break
				}
			}
			return nil
		}

		updateActions []*awsec.UpdateAction
		describeUpdateActionsPagesStub = func(
			input *awsec.DescribeUpdateActionsInput,
			fn func(*awsec.DescribeUpdateActionsOutput, bool) bool,
		) error {
			for i, updateAction := range updateActions {
				page := &awsec.DescribeUpdateActionsOutput{
					UpdateActions: []*awsec.UpdateAction{updateAction},
				}
				if !fn(page, i+1 >= len(updateActions)) {
					break
				}
			}
			return nil
		}
	)

	BeforeEach(func(){
		fakeElasticache = &esfakes.FakeElastiCacheAPI{}
		fakeElasticache.DescribeServiceUpdatesPagesStub = describeServiceUpdatesPagesStub
		fakeElasticache.DescribeUpdateActionsPagesStub = describeUpdateActionsPagesStub
		elasticacheService = &elasticache.ElasticacheService{Client: fakeElasticache}
	})

	Describe("ListAvailableRedisServiceUpdates", func() {
		BeforeEach(func() {
			serviceUpdates = []*awsec.ServiceUpdate{
				{
					Engine:            aws.String("memcached"),
					ServiceUpdateName: aws.String("memcached20200101"),
				},
				{
					Engine:            aws.String("redis"),
					ServiceUpdateName: aws.String("redis20200101"),
				},
			}

		})

		It("returns the service update names", func() {
			serviceUpdates = []*awsec.ServiceUpdate{
				{
					Engine:            aws.String("redis"),
					ServiceUpdateName: aws.String("redis1"),
				},
				{
					Engine:            aws.String("redis"),
					ServiceUpdateName: aws.String("redis2"),
				},
				{
					Engine:            aws.String("redis"),
					ServiceUpdateName: aws.String("redis3"),
				},
			}

			updates, err := ListAvailableRedisServiceUpdates(elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			Expect(len(updates)).To(Equal(3))
			Expect(updates).To(ConsistOf("redis1", "redis2", "redis3"))
		})

		It("filters out non-redis updates", func() {
			updates, err := ListAvailableRedisServiceUpdates(elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			Expect(len(updates)).To(Equal(1))
			Expect(updates[0]).To(Equal("redis20200101"))
		})

		It("requests only 'available' service updates", func() {
			_, err := ListAvailableRedisServiceUpdates(elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			input, _ := fakeElasticache.DescribeServiceUpdatesPagesArgsForCall(0)
			Expect(input.ServiceUpdateStatus).To(ConsistOf(
				aws.String("available"),
			))
		})
	})

	Describe("ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate", func() {
		BeforeEach(func(){
			updateActions = []*awsec.UpdateAction{
				{
					ReplicationGroupId:                  aws.String("id-1"),
					ServiceUpdateName:                   aws.String("redis1"),
					ServiceUpdateStatus:                 aws.String("available"),
					UpdateActionStatus:                  aws.String("not-applied"),
				},
				{
					ReplicationGroupId:                  aws.String("id-2"),
					ServiceUpdateName:                   aws.String("redis1"),
					ServiceUpdateStatus:                 aws.String("available"),
					UpdateActionStatus:                  aws.String("not-applied"),
				},
				{
					ReplicationGroupId:                  aws.String("id-3"),
					ServiceUpdateName:                   aws.String("redis1"),
					ServiceUpdateStatus:                 aws.String("available"),
					UpdateActionStatus:                  aws.String("not-applied"),
				},
			}
		})
		
		It("returns the replication group IDs", func() {
			replicationGroupIds, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate("redis1", elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			Expect(replicationGroupIds).To(ConsistOf(
				"id-1",
				"id-2",
				"id-3",
			))
		})

		It("requests only update actions for the given service update", func() {
			_, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate("redis1", elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			input, _ := fakeElasticache.DescribeUpdateActionsPagesArgsForCall(0)
			Expect(input.ServiceUpdateName).To(Equal(
				aws.String("redis1"),
			))
		})

		It("requests only 'available' service updates", func() {
			_, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate("redis1", elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			input, _ := fakeElasticache.DescribeUpdateActionsPagesArgsForCall(0)
			Expect(input.ServiceUpdateStatus).To(ConsistOf(
				aws.String("available"),
			))
		})

		It("requests only 'not-applied' service update actions", func() {
			_, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate("redis1", elasticacheService)
			Expect(err).ToNot(HaveOccurred())

			input, _ := fakeElasticache.DescribeUpdateActionsPagesArgsForCall(0)
			Expect(input.UpdateActionStatus).To(ConsistOf(
				aws.String("not-applied"),
			))
		})
	})
})
