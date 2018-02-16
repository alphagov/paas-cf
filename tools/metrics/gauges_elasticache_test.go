package main_test

import (
	"errors"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	fakes "github.com/alphagov/paas-cf/tools/metrics/fakes"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/elasticache"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
)

var _ = Describe("Elasticache Gauges", func() {

	var (
		logger             lager.Logger
		log                *gbytes.Buffer
		elasticacheAPI     *fakes.FakeElastiCacheAPI
		elasticacheService *ElasticacheService

		cacheParameterGroups []*elasticache.CacheParameterGroup

		describeCacheParameterGroupsPagesStub = func(
			input *elasticache.DescribeCacheParameterGroupsInput,
			fn func(*elasticache.DescribeCacheParameterGroupsOutput, bool) bool,
		) error {
			for i, cacheParameterGroup := range cacheParameterGroups {
				page := &elasticache.DescribeCacheParameterGroupsOutput{
					CacheParameterGroups: []*elasticache.CacheParameterGroup{cacheParameterGroup},
				}
				if !fn(page, i+1 >= len(cacheParameterGroups)) {
					break
				}
			}
			return nil
		}

		replicationGroups []*elasticache.ReplicationGroup

		describeReplicationGroupsPagesStub = func(
			input *elasticache.DescribeReplicationGroupsInput,
			fn func(*elasticache.DescribeReplicationGroupsOutput, bool) bool,
		) error {
			for i, replicationGroup := range replicationGroups {
				page := &elasticache.DescribeReplicationGroupsOutput{
					ReplicationGroups: []*elasticache.ReplicationGroup{replicationGroup},
				}
				if !fn(page, i+1 >= len(replicationGroups)) {
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
		elasticacheAPI = &fakes.FakeElastiCacheAPI{}
		elasticacheAPI.DescribeCacheParameterGroupsPagesStub = describeCacheParameterGroupsPagesStub
		elasticacheAPI.DescribeReplicationGroupsPagesStub = describeReplicationGroupsPagesStub
		elasticacheService = &ElasticacheService{Client: elasticacheAPI}
	})

	It("returns zero if there are no clusters", func() {
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, 1*time.Second)
		defer gauge.Close()

		var metric Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.node.count"))

		Expect(metric.Value).To(Equal(float64(0)))
		Expect(metric.Kind).To(Equal(Gauge))
	})

	It("returns the number of nodes", func() {
		replicationGroups = []*elasticache.ReplicationGroup{
			{
				MemberClusters: aws.StringSlice([]string{"node1", "node2"}),
			},
			{
				MemberClusters: aws.StringSlice([]string{"node3"}),
			},
		}

		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, 1*time.Second)
		defer gauge.Close()

		var metric Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.node.count"))

		Expect(metric.Value).To(Equal(float64(3)))
		Expect(metric.Kind).To(Equal(Gauge))
	})

	It("handles AWS API errors when getting the number of nodes", func() {
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, 1*time.Second)
		defer gauge.Close()

		awsErr := errors.New("some error")
		elasticacheAPI.DescribeReplicationGroupsPagesStub = func(
			input *elasticache.DescribeReplicationGroupsInput,
			fn func(*elasticache.DescribeReplicationGroupsOutput, bool) bool,
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
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, 1*time.Second)
		defer gauge.Close()

		var metric Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.cache_parameter_group.count"))

		Expect(metric.Value).To(Equal(float64(0)))
		Expect(metric.Kind).To(Equal(Gauge))
	})

	It("returns the number of cache parameter groups", func() {
		cacheParameterGroups = []*elasticache.CacheParameterGroup{
			&elasticache.CacheParameterGroup{},
			&elasticache.CacheParameterGroup{},
		}

		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, 1*time.Second)
		defer gauge.Close()

		var metric Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.elasticache.cache_parameter_group.count"))

		Expect(metric.Value).To(Equal(float64(2)))
		Expect(metric.Kind).To(Equal(Gauge))
	})

	It("handles AWS API errors when getting the number of cache parameter groups", func() {
		gauge := ElasticCacheInstancesGauge(logger, elasticacheService, 1*time.Second)
		defer gauge.Close()

		awsErr := errors.New("some error")
		elasticacheAPI.DescribeCacheParameterGroupsPagesStub = func(
			input *elasticache.DescribeCacheParameterGroupsInput,
			fn func(*elasticache.DescribeCacheParameterGroupsOutput, bool) bool,
		) error {
			return awsErr
		}

		Eventually(func() error {
			metric, err := gauge.ReadMetric()
			Expect(metric.Name).To(Equal(""))
			return err
		}, 3*time.Second).Should(MatchError(awsErr))
	})

})
