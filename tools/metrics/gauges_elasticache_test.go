package main_test

import (
	"errors"
	paasElasticacheBrokerRedis "github.com/alphagov/paas-elasticache-broker/providers/redis"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	cf "github.com/cloudfoundry-community/go-cfclient"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"

	cftest "github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfoundry/test"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	esfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("Elasticache Gauges", func() {

	var (
		generateReplicationGroupId = paasElasticacheBrokerRedis.GenerateReplicationGroupName

		logger             lager.Logger
		log                *gbytes.Buffer
		elasticacheAPI     *esfakes.FakeElastiCacheAPI
		elasticacheService *elasticache.ElasticacheService
		cfAPI              *cftest.CloudFoundryAPIStub

		cacheParameterGroups                  []*awsec.CacheParameterGroup
		describeCacheParameterGroupsPagesStub = func(
			input *awsec.DescribeCacheParameterGroupsInput,
			fn func(*awsec.DescribeCacheParameterGroupsOutput, bool) bool,
		) error {
			for i, cacheParameterGroup := range cacheParameterGroups {
				page := &awsec.DescribeCacheParameterGroupsOutput{
					CacheParameterGroups: []*awsec.CacheParameterGroup{cacheParameterGroup},
				}
				if !fn(page, i+1 >= len(cacheParameterGroups)) {
					break
				}
			}
			return nil
		}

		cacheClusters                  []*awsec.CacheCluster
		describeCacheClustersPagesStub = func(
			input *awsec.DescribeCacheClustersInput,
			fn func(*awsec.DescribeCacheClustersOutput, bool) bool,
		) error {
			for i, cacheCluster := range cacheClusters {
				page := &awsec.DescribeCacheClustersOutput{
					CacheClusters: []*awsec.CacheCluster{cacheCluster},
				}
				if !fn(page, i+1 >= len(cacheClusters)) {
					break
				}
			}
			return nil
		}
	)

	BeforeEach(func() {
		logger = lager.NewLogger("logger")
		log = gbytes.NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(log, lager.INFO))

		elasticacheAPI = &esfakes.FakeElastiCacheAPI{}
		elasticacheAPI.DescribeCacheParameterGroupsPagesStub = describeCacheParameterGroupsPagesStub
		elasticacheAPI.DescribeCacheClustersPagesStub = describeCacheClustersPagesStub
		elasticacheService = &elasticache.ElasticacheService{Client: elasticacheAPI}

		cfAPI = cftest.NewCloudFoundryAPIStub()
		cacheClusters = []*awsec.CacheCluster{
			{
				ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-1-guid")),
				CacheClusterId: aws.String("cf-hash1-0001-001"),
				NumCacheNodes:  aws.Int64(2),
			},
			{
				ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-2-guid")),
				CacheClusterId: aws.String("cf-2hsah-001"),
				NumCacheNodes:  aws.Int64(1),
			},
		}

		cfAPI.Services = map[string][]cf.Service{
			"label:redis": []cf.Service{
				{
					Guid:  "redis-service-guid",
					Label: "redis",
				},
			},
		}

		cfAPI.ServicePlans = map[string][]cf.ServicePlan{
			"service_guid:redis-service-guid": []cf.ServicePlan{
				{
					Name: "plan-1",
					Guid: "svc-plan-1",
				},
				{
					Name: "plan-2",
					Guid: "svc-plan-2",
				},
			},
		}

		cfAPI.ServiceInstances = map[string][]cf.ServiceInstance{
			"service_plan_guid:svc-plan-1": []cf.ServiceInstance{{
				ServiceGuid:     "redis-service-guid",
				Guid:            "svc-instance-1-guid",
				SpaceGuid:       "space-guid-1",
				ServicePlanGuid: "svc-plan-1",
			}},
			"service_plan_guid:svc-plan-2": []cf.ServiceInstance{{
				ServiceGuid:     "redis-service-guid",
				Guid:            "svc-instance-2-guid",
				SpaceGuid:       "space-guid-2",
				ServicePlanGuid: "svc-plan-1",
			}},
		}

		cfAPI.Spaces = map[string]cf.Space{
			"space-guid-1": {
				Guid:             "space-guid-1",
				Name:             "Space 1",
				OrganizationGuid: "org-guid-1",
			},
			"space-guid-2": {
				Guid:             "space-guid-2",
				Name:             "Space 2",
				OrganizationGuid: "org-guid-2",
			},
		}

		cfAPI.Orgs = map[string]cf.Org{
			"org-guid-1": {
				Guid: "org-guid-1",
				Name: "Org 1",
			},
			"org-guid-2": {
				Guid: "org-guid-2",
				Name: "Org 2",
			},
		}
	})

	It("returns zero if there are no clusters", func() {
		cacheClusters = []*awsec.CacheCluster{}

		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.node.count"))

		Expect(metric.Value).To(Equal(float64(0)))
		Expect(metric.Kind).To(Equal(m.Gauge))
	})

	It("returns the total number of nodes across all clusters", func() {
		cacheClusters = []*awsec.CacheCluster{
			{
				ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-1-guid")),
				CacheClusterId: aws.String("cf-hash1-0001-001"),
				NumCacheNodes:  aws.Int64(2),
			},
			{
				ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-2-guid")),
				CacheClusterId: aws.String("cf-2hsah-001"),
				NumCacheNodes:  aws.Int64(1),
			},
		}

		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.node.count"))

		Expect(metric.Value).To(Equal(float64(3)))
		Expect(metric.Kind).To(Equal(m.Gauge))
	})

	It("handles AWS API errors when getting the number of nodes", func() {
		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		awsErr := errors.New("some error")
		elasticacheAPI.DescribeCacheClustersPagesStub = func(
			input *awsec.DescribeCacheClustersInput,
			fn func(*awsec.DescribeCacheClustersOutput, bool) bool,
		) error {
			return awsErr
		}

		Eventually(func() error {
			metric, err := gauge.ReadMetric()
			Expect(metric.Name).To(Equal(""))
			return err
		}, 3*time.Second).Should(MatchError(awsErr))
	})

	It("returns zero if there are no cache parameter groups", func() {
		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.cache_parameter_group.count"))

		Expect(metric.Value).To(Equal(float64(0)))
		Expect(metric.Kind).To(Equal(m.Gauge))
	})

	It("returns zero if there are only default cache parameter groups", func() {
		cacheParameterGroups = []*awsec.CacheParameterGroup{
			&awsec.CacheParameterGroup{
				CacheParameterGroupName: aws.String("default.redis3.2"),
			},
		}
		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.cache_parameter_group.count"))

		Expect(metric.Value).To(Equal(float64(0)))
		Expect(metric.Kind).To(Equal(m.Gauge))
	})

	It("returns the number of cache parameter groups excluding the default ones", func() {
		cacheParameterGroups = []*awsec.CacheParameterGroup{
			&awsec.CacheParameterGroup{
				CacheParameterGroupName: aws.String("default.redis3.2"),
			},
			&awsec.CacheParameterGroup{
				CacheParameterGroupName: aws.String("group-1"),
			},
			&awsec.CacheParameterGroup{
				CacheParameterGroupName: aws.String("group-1"),
			},
		}

		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.cache_parameter_group.count"))

		Expect(metric.Value).To(Equal(float64(2)))
		Expect(metric.Kind).To(Equal(m.Gauge))
	})

	It("handles AWS API errors when getting the number of cache parameter groups", func() {
		gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Second)
		defer gauge.Close()

		awsErr := errors.New("some error")
		elasticacheAPI.DescribeCacheParameterGroupsPagesStub = func(
			input *awsec.DescribeCacheParameterGroupsInput,
			fn func(*awsec.DescribeCacheParameterGroupsOutput, bool) bool,
		) error {
			return awsErr
		}

		Eventually(func() error {
			metric, err := gauge.ReadMetric()
			Expect(metric.Name).To(Equal(""))
			return err
		}, 3*time.Second).Should(MatchError(awsErr))
	})

	Describe("aws.elasticache.replication_group.nodes.count", func() {
		var (
			getMetrics = func(metricName string, expectedCount int) []m.Metric {
				gauge := ElasticacheInstancesGauge(logger, elasticacheService, cfAPI.APIFake, 1*time.Minute)
				defer gauge.Close()

				var metrics []m.Metric
				Eventually(func() int {
					metric, err := gauge.ReadMetric()
					Expect(err).NotTo(HaveOccurred())

					// Empty name suggests empty struct.
					// The empty struct is returned when
					// there are no more metrics.
					if metric.Name == metricName {
						metrics = append(metrics, metric)
					}

					return len(metrics)
				}, 3*time.Second).Should(Equal(expectedCount))

				return metrics
			}
		)

		BeforeEach(func(){
			cacheClusters = []*awsec.CacheCluster{
				// The first two cache clusters belong to the same replication group
				{
					ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-1-guid")),
					CacheClusterId: aws.String(generateReplicationGroupId("svc-instance-1-guid")+"001-0001"),
					NumCacheNodes:  aws.Int64(2),
				},
				{
					ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-1-guid")),
					CacheClusterId: aws.String(generateReplicationGroupId("svc-instance-1-guid")+"001-0002"),
					NumCacheNodes:  aws.Int64(1),
				},
				{
					ReplicationGroupId: aws.String(generateReplicationGroupId("svc-instance-2-guid")),
					CacheClusterId: aws.String(generateReplicationGroupId("svc-instance-2-guid")+"001"),
					NumCacheNodes:  aws.Int64(1),
				},
			}
		})

		It("returns the number of nodes per replication group, summing the number of cache nodes across replication groups", func() {
			metrics := getMetrics("aws.elasticache.replication_group.nodes.count", 2)

			Expect(metrics[0].Value).To(Equal(float64(3)))
			Expect(metrics[0].Kind).To(Equal(m.Gauge))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "replication_group_id",
				Value: generateReplicationGroupId("svc-instance-1-guid"),
			}))

			Expect(metrics[1].Value).To(Equal(float64(1)))
			Expect(metrics[1].Kind).To(Equal(m.Gauge))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "replication_group_id",
				Value: generateReplicationGroupId("svc-instance-2-guid"),
			}))
		})

		It("labels the metrics with the service guid", func() {
			metrics := getMetrics("aws.elasticache.replication_group.nodes.count", 2)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "svc-instance-1-guid",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "svc-instance-2-guid",
			}))
		})

		It("labels the metrics with the space name", func() {
			metrics := getMetrics("aws.elasticache.replication_group.nodes.count", 2)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "space_name",
				Value: "Space 1",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "space_name",
				Value: "Space 2",
			}))
		})

		It("labels the metrics with the space guid", func() {
			metrics := getMetrics("aws.elasticache.replication_group.nodes.count", 2)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "space_guid",
				Value: "space-guid-1",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "space_guid",
				Value: "space-guid-2",
			}))
		})

		It("labels the metrics with the org name", func() {
			metrics := getMetrics("aws.elasticache.replication_group.nodes.count", 2)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "org_name",
				Value: "Org 1",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "org_name",
				Value: "Org 2",
			}))
		})

		It("labels the metrics with the org guid", func() {
			metrics := getMetrics("aws.elasticache.replication_group.nodes.count", 2)

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "org_guid",
				Value: "org-guid-1",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "org_guid",
				Value: "org-guid-2",
			}))
		})
	})
})
