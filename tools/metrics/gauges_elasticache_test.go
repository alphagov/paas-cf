package main_test

import (
	"errors"
	"net/url"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	cf "github.com/cloudfoundry-community/go-cfclient"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"

	cffakes "github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfoundry/fakes"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	esfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("Elasticache Gauges", func() {

	var (
		logger             lager.Logger
		log                *gbytes.Buffer
		elasticacheAPI     *esfakes.FakeElastiCacheAPI
		elasticacheService *elasticache.ElasticacheService
		cfAPI              *cffakes.FakeCloudFoundryClient
		hashingFunction    elasticache.ElasticacheClusterIdHashingFunction
		serviceGuidToHash  map[string]string

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

		cfServices            []cf.Service
		cfServicesByQueryStub = func(
			query url.Values,
		) ([]cf.Service, error) {
			return cfServices, nil
		}

		cfServicePlans            []cf.ServicePlan
		cfServicePlansByQueryStub = func(
			query url.Values,
		) ([]cf.ServicePlan, error) {
			return cfServicePlans, nil
		}

		cfServiceInstances        []cf.ServiceInstance
		cfServiceInstancesByQuery = func(
			query url.Values,
		) ([]cf.ServiceInstance, error) {
			return cfServiceInstances, nil
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

		cfAPI = &cffakes.FakeCloudFoundryClient{}
		cfAPI.ListServicesByQueryStub = cfServicesByQueryStub
		cfAPI.ListServiceInstancesByQueryStub = cfServiceInstancesByQuery
		cfAPI.ListServicePlansByQueryStub = cfServicePlansByQueryStub

		hashingFunction = func(value string) string {
			return serviceGuidToHash[value]
		}
	})

	It("returns zero if there are no clusters", func() {
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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

	It("returns the number of nodes", func() {
		cacheClusters = []*awsec.CacheCluster{
			{
				CacheClusterId: aws.String("cf-hash1-0001-001"),
				NumCacheNodes:  aws.Int64(2),
			},
			{
				CacheClusterId: aws.String("cf-hash2-001"),
				NumCacheNodes:  aws.Int64(1),
			},
		}

		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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

	It("returns the number of cache parameter groups exluding the default ones", func() {
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

		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
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

	Describe("aws.elasticache.cluster.nodes.count", func() {
		getMetrics := func() []m.Metric {
			gauge := ElasticCacheInstancesGauge(logger, elasticacheService, cfAPI, hashingFunction, 1*time.Second)
			defer gauge.Close()

			var metrics []m.Metric
			Eventually(func() int {
				var err error
				metric, err := gauge.ReadMetric()
				Expect(err).NotTo(HaveOccurred())

				if metric.Name == "aws.elasticache.cluster.nodes.count" {
					metrics = append(metrics, metric)
				}

				return len(metrics)
			}, 3*time.Second).Should(Equal(2))

			return metrics
		}

		BeforeEach(func() {
			cacheClusters = []*awsec.CacheCluster{
				{
					// The AWS API produces cache cluster id's which
					// contain the user-supplied name, and then some
					// extra information
					CacheClusterId: aws.String("cf-hash1-0001-001"),
					NumCacheNodes:  aws.Int64(2),
				},
				{
					CacheClusterId: aws.String("cf-2hsah-001"),
					NumCacheNodes:  aws.Int64(1),
				},
			}

			cfServices = []cf.Service{
				{
					Guid:  "redis-service-guid",
					Label: "redis",
				},
			}

			cfServicePlans = []cf.ServicePlan{
				{
					Name: "plan-1",
					Guid: "svc-plan-1",
				},
				{
					Name: "plan-2",
					Guid: "svc-plan-2",
				},
			}

			cfServiceInstances = []cf.ServiceInstance{
				{
					ServiceGuid: "redis-service-guid",
					Guid:        "svc-instance-1-guid",
				},
				{
					ServiceGuid: "redis-service-guid",
					Guid:        "svc-instance-2-guid",
				},
			}

			serviceGuidToHash = map[string]string{
				"svc-instance-1-guid": "cf-hash1-0001-001",
				"svc-instance-2-guid": "cf-2hsah-001",
			}
		})

		It("returns the number of nodes per cache cluster", func() {
			metrics := getMetrics()

			Expect(metrics[0].Value).To(Equal(float64(2)))
			Expect(metrics[0].Kind).To(Equal(m.Gauge))
			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "cluster_id",
				Value: "cf-hash1",
			}))

			Expect(metrics[1].Value).To(Equal(float64(1)))
			Expect(metrics[1].Kind).To(Equal(m.Gauge))
			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "cluster_id",
				Value: "cf-2hsah",
			}))
		})

		It("labels the metrics with the service guid", func() {
			metrics := getMetrics()

			Expect(metrics[0].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "svc-instance-1-guid",
			}))

			Expect(metrics[1].Tags).To(ContainElement(m.MetricTag{
				Label: "service_instance_guid",
				Value: "svc-instance-2-guid",
			}))
		})
	})
})
