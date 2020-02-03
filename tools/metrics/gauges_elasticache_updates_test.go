package main_test

import (
	. "github.com/alphagov/paas-cf/tools/metrics"
	cftest "github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfoundry/test"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	esfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	cf "github.com/cloudfoundry-community/go-cfclient"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"time"
)

var _ = Describe("Elasticache Updates", func() {
	var (
		fakeElasticache    *esfakes.FakeElastiCacheAPI
		elasticacheService *elasticache.ElasticacheService
		cfAPI              *cftest.CloudFoundryAPIStub
		hashingFunction    elasticache.ElasticacheClusterIdHashingFunction
		serviceGuidToHash  map[string]string

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
			"space-2": cf.Space{Guid: "space-2", Name: "Space 2", OrganizationGuid: "org-1"},
		}

		cfAPI.Orgs = map[string]cf.Org{
			"org-1": cf.Org{Guid: "org-1", Name: "Org 1"},
		}

		hashingFunction = func(value string) string {
			return serviceGuidToHash[value]
		}
	})

	Describe("ElasticacheUpdatesGauge", func() {
		var (
			getFilteredMetrics = func(metricName string, expectedCount int) []m.Metric {
				gauge := ElasticacheUpdatesGauge(elasticacheService, cfAPI.APIFake, hashingFunction, 1*time.Second)
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
						Guid:            "instance-1",
						SpaceGuid:       "space-1",
					},
					{
						ServiceGuid:     "redis-svc",
						ServicePlanGuid: "svc-plan-1",
						Guid:            "instance-2",
						SpaceGuid:       "space-2",
					},
				},
			}

			updateActions = map[string][]*awsec.UpdateAction{
				"redis20200101": []*awsec.UpdateAction{
					{
						ReplicationGroupId: aws.String("cluster-1"),
						ServiceUpdateName:  aws.String("redis20200101"),
					},
				},
				"redis20200303": []*awsec.UpdateAction{
					{
						ReplicationGroupId: aws.String("cluster-2"),
						ServiceUpdateName:  aws.String("redis20200303"),
					}, {
						ReplicationGroupId: aws.String("cluster-3"),
						ServiceUpdateName:  aws.String("redis20200303"),
					},
				},
			}

			serviceGuidToHash = map[string]string {
				"instance-1": "cluster-1",
				"instance-2": "cluster-2",
				"instance-3": "cluster-3",
			}
		})

		It("for each service update, exposes a metric counting the number of cache clusters to which the update HASN'T been applied", func() {
			metrics := getFilteredMetrics("aws.elasticache.service_update.not_applied.count", 2)

			Expect(metrics[0].Name).To(Equal("aws.elasticache.service_update.not_applied.count"))
			Expect(metrics[0].Value).To(Equal(float64(1)))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200101",
			}))

			Expect(metrics[1].Name).To(Equal("aws.elasticache.service_update.not_applied.count"))
			Expect(metrics[1].Value).To(Equal(float64(2)))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200303",
			}))
		})

		It("for each redis service instance, exposes a metric to show whether each service update has been applied", func() {
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_applied", 5)

			// Update redis20200101 has NOT been applied
			Expect(metrics[0].Value).To(Equal(float64(0)))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_cache_cluster_id",
				Value: "cluster-1",
			}))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200101",
			}))

			// Update redis20200303 HAS been applied
			Expect(metrics[1].Value).To(Equal(float64(1)))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_cache_cluster_id",
				Value: "cluster-1",
			}))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "elasticache_service_update",
				Value: "redis20200303",
			}))
		})

		It("labels each redis service metric with the service guid", func(){
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_applied", 4)

			// There are 2 instances, with 2 service update metrics each
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "instance-1",
			}))

			Expect(metrics[2].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "instance-2",
			}))
		})

		It("labels each redis service metric with the service's space name and guid", func(){
			metrics := getFilteredMetrics("aws.elasticache.cluster.update_applied", 4)

			// There are 2 instances, with 2 service update metrics each
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "space_guid",
				Value: "space-1",
			}))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "space_name",
				Value: "Space 1",
			}))

			Expect(metrics[2].Tags).To(ContainElement(m.MetricTag{
				Label: "space_guid",
				Value: "space-2",
			}))
			Expect(metrics[2].Tags).To(ContainElement(m.MetricTag{
				Label: "space_name",
				Value: "Space 2",
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
