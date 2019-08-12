package main

import (
	"strings"
	"time"

	"code.cloudfoundry.org/lager"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
)

func ElasticCacheInstancesGauge(
	logger lager.Logger,
	ecs *elasticache.ElasticacheService,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}

		cacheParameterGroupCount := 0
		err := ecs.Client.DescribeCacheParameterGroupsPages(
			&awsec.DescribeCacheParameterGroupsInput{},
			func(page *awsec.DescribeCacheParameterGroupsOutput, lastPage bool) bool {
				for _, cacheParameterGroup := range page.CacheParameterGroups {
					if !strings.HasPrefix(*cacheParameterGroup.CacheParameterGroupName, "default.") {
						cacheParameterGroupCount++
					}
				}
				return true
			},
		)
		if err != nil {
			return err
		}

		metrics = append(metrics, Metric{
			Kind:  Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.cache_parameter_group.count",
			Value: float64(cacheParameterGroupCount),
			Unit:  "count",
		})

		nodeCount := int64(0)
		err = ecs.Client.DescribeCacheClustersPages(
			&awsec.DescribeCacheClustersInput{},
			func(page *awsec.DescribeCacheClustersOutput, lastPage bool) bool {
				for _, cacheCluster := range page.CacheClusters {
					nodeCount = nodeCount + *cacheCluster.NumCacheNodes
				}
				return true
			},
		)
		if err != nil {
			return err
		}

		metrics = append(metrics, Metric{
			Kind:  Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.node.count",
			Value: float64(nodeCount),
			Unit:  "count",
		})

		return w.WriteMetrics(metrics)
	})
}
