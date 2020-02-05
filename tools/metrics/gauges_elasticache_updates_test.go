package main_test

import (
	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	cftest "github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfoundry/test"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	esfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	paasElasticacheBrokerRedis "github.com/alphagov/paas-elasticache-broker/providers/redis"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	cf "github.com/cloudfoundry-community/go-cfclient"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"time"
)

var generateReplicationGroupName = paasElasticacheBrokerRedis.GenerateReplicationGroupName

var _ = Describe("Elasticache Updates", func() {
	var (
		logger             lager.Logger
		fakeElasticache    *esfakes.FakeElastiCacheAPI
		elasticacheService *elasticache.ElasticacheService
		cfAPI              *cftest.CloudFoundryAPIStub

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

		// map of service update name to update action
		updateActions                  map[string][]*awsec.UpdateAction
		describeUpdateActionsPagesStub = func(
			input *awsec.DescribeUpdateActionsInput,
			fn func(*awsec.DescribeUpdateActionsOutput, bool) bool,
		) error {
			for i, updateAction := range updateActions[aws.StringValue(input.ServiceUpdateName)] {
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

	BeforeEach(func() {
		logger = lager.NewLogger("gauge-elasticache-updates-test")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.DEBUG))

		fakeElasticache = &esfakes.FakeElastiCacheAPI{}
		fakeElasticache.DescribeServiceUpdatesPagesStub = describeServiceUpdatesPagesStub
		fakeElasticache.DescribeUpdateActionsPagesStub = describeUpdateActionsPagesStub
		elasticacheService = &elasticache.ElasticacheService{Client: fakeElasticache}

		cfAPI = cftest.NewCloudFoundryAPIStub()
		cfAPI.Services = map[string][]cf.Service{
			"label:redis": {{
				Guid:  "redis-svc",
				Label: "redis",
			}},
		}

		cfAPI.ServicePlans = map[string][]cf.ServicePlan{
			"service_guid:redis-svc": {{
				Name: "plan-1",
				Guid: "svc-plan-1",
			}},
		}

		cfAPI.Spaces = map[string]cf.Space{
			"space-1": cf.Space{Guid: "space-1", Name: "Space 1", OrganizationGuid: "org-1"},
			"space-2": cf.Space{Guid: "space-2", Name: "Space 2", OrganizationGuid: "org-2"},
			"space-3": cf.Space{Guid: "space-3", Name: "Space 3", OrganizationGuid: "org-2"},
		}

		cfAPI.Orgs = map[string]cf.Org{
			"org-1": cf.Org{Guid: "org-1", Name: "Org 1"},
			"org-2": cf.Org{Guid: "org-2", Name: "Org 2"},
		}
	})

	Describe("ElasticacheUpdatesGauge", func() {
		var (
			getFilteredMetrics = func(metricName string, expectedCount int) []m.Metric {
				gauge := ElasticacheUpdatesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
				defer gauge.Close()

				var metrics []m.Metric

				Eventually(func() int {
					metric, err := gauge.ReadMetric()
					Expect(err).NotTo(HaveOccurred())

					if metric.Name == metricName {
						metrics = append(metrics, metric)
					}
					return len(metrics)
				}, 3*time.Second).Should(Equal(expectedCount))

				return metrics
			}
		)
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
				{
					Engine:            aws.String("redis"),
					ServiceUpdateName: aws.String("redis20200303"),
				},
			}

			cfAPI.ServiceInstances = map[string][]cf.ServiceInstance{
				"service_plan_guid:svc-plan-1": {
					{
						ServiceGuid:     "redis-svc",
						ServicePlanGuid: "svc-plan-1",
						Guid:            "instance-guid-1",
						SpaceGuid:       "space-1",
					},
					{
						ServiceGuid:     "redis-svc",
						ServicePlanGuid: "svc-plan-1",
						Guid:            "instance-guid-2",
						SpaceGuid:       "space-2",
					},
					{
						ServiceGuid:     "redis-svc",
						ServicePlanGuid: "svc-plan-1",
						Guid:            "instance-guid-3",
						SpaceGuid:       "space-3",
					},
				},
			}

			updateActions = map[string][]*awsec.UpdateAction{
				"redis20200101": []*awsec.UpdateAction{
					{
						ReplicationGroupId: aws.String(generateReplicationGroupName("instance-guid-1")),
						ServiceUpdateName:  aws.String("redis20200101"),
					},
					{
						ReplicationGroupId: aws.String(generateReplicationGroupName("instance-guid-3")),
						ServiceUpdateName:  aws.String("redis20200101"),
					},
				},
				"redis20200303": []*awsec.UpdateAction{
					{
						ReplicationGroupId: aws.String(generateReplicationGroupName("instance-guid-2")),
						ServiceUpdateName:  aws.String("redis20200303"),
					}, {
						ReplicationGroupId: aws.String(generateReplicationGroupName("instance-guid-3")),
						ServiceUpdateName:  aws.String("redis20200303"),
					}, {
						ReplicationGroupId: aws.String("unexpected-replication-group"),
						ServiceUpdateName:  aws.String("redis20200303"),
					},
				},
			}
		})

		It("for each service update, exposes a metric counting the number of replication groups to which the update HASN'T been applied", func() {
			metrics := getFilteredMetrics("aws.elasticache.service_update.not_applied.count", 2)

			Expect(metrics[0].Name).To(Equal("aws.elasticache.service_update.not_applied.count"))
			Expect(metrics[0].Value).To(Equal(float64(2)))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200101",
			}))

			Expect(metrics[1].Name).To(Equal("aws.elasticache.service_update.not_applied.count"))
			Expect(metrics[1].Value).To(Equal(float64(3)))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200303",
			}))
		})

		It("for each redis service instance, exposes a metric for each service update that has not been applied", func() {
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_required", 4)

			Expect(metrics[0].Value).To(Equal(float64(1)))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200101",
			}))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_replication_group_id",
				Value: generateReplicationGroupName("instance-guid-1"),
			}))
			Expect(metrics[1].Value).To(Equal(float64(1)))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200101",
			}))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_replication_group_id",
				Value: generateReplicationGroupName("instance-guid-3"),
			}))

			Expect(metrics[2].Value).To(Equal(float64(1)))
			Expect(metrics[2].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200303",
			}))
			Expect(metrics[2].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_replication_group_id",
				Value: generateReplicationGroupName("instance-guid-2"),
			}))
			Expect(metrics[3].Value).To(Equal(float64(1)))
			Expect(metrics[3].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200303",
			}))
			Expect(metrics[3].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_replication_group_id",
				Value: generateReplicationGroupName("instance-guid-3"),
			}))
		})

		It("labels each redis service metric with the service guid", func() {
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_required", 4)

			// There are 2 instances, with 2 service update metrics each
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "instance-guid-1",
			}))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "instance-guid-3",
			}))
			Expect(metrics[2].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "instance-guid-2",
			}))
			Expect(metrics[3].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "instance-guid-3",
			}))
		})

		It("labels each redis service metric with the service's space name and guid", func() {
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_required", 4)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "space_guid",
				Value: "space-1",
			}))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "space_name",
				Value: "Space 1",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "space_guid",
				Value: "space-3",
			}))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "space_name",
				Value: "Space 3",
			}))
		})

		It("labels each redis service metric with the service's org name and guid", func() {
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_required", 4)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "org_guid",
				Value: "org-1",
			}))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "org_name",
				Value: "Org 1",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "org_guid",
				Value: "org-2",
			}))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "org_name",
				Value: "Org 2",
			}))
		})
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
				{
					Engine:            aws.String("redis, memcached"),
					ServiceUpdateName: aws.String("update20200101"),
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

			Expect(len(updates)).To(Equal(2))
			Expect(updates[0]).To(Equal("redis20200101"))
			Expect(updates[1]).To(Equal("update20200101"))
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

	Describe("ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate ", func() {
		BeforeEach(func() {
			updateActions = map[string][]*awsec.UpdateAction{
				"redis1": []*awsec.UpdateAction{
					{
						ReplicationGroupId:  aws.String("id-1"),
						ServiceUpdateName:   aws.String("redis1"),
						ServiceUpdateStatus: aws.String("available"),
						UpdateActionStatus:  aws.String("not-applied"),
					},
					{
						ReplicationGroupId:  aws.String("id-2"),
						ServiceUpdateName:   aws.String("redis1"),
						ServiceUpdateStatus: aws.String("available"),
						UpdateActionStatus:  aws.String("not-applied"),
					},
					{
						ReplicationGroupId:  aws.String("id-3"),
						ServiceUpdateName:   aws.String("redis1"),
						ServiceUpdateStatus: aws.String("available"),
						UpdateActionStatus:  aws.String("not-applied"),
					},
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
