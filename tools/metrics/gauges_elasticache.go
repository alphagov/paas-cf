package main

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface"
	"strings"
	"time"

	"code.cloudfoundry.org/lager"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

func ElasticCacheInstancesGauge(
	logger lager.Logger,
	ecs *elasticache.ElasticacheService,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		metrics := []m.Metric{}

		cacheParameterGroupCount := 0
		err := iterateCacheParameterGroups(
			ecs.Client,
			func(cacheParameterGroup *awsec.CacheParameterGroup) {
				if !strings.HasPrefix(*cacheParameterGroup.CacheParameterGroupName, "default.") {
					cacheParameterGroupCount++
				}
			},
		)

		if err != nil {
			return err
		}

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.cache_parameter_group.count",
			Value: float64(cacheParameterGroupCount),
			Unit:  "count",
		})

		nodeCount := int64(0)
		err = iterateCacheClusterPages(
			ecs.Client,
			func(cacheCluster *awsec.CacheCluster){
				nodeCount = nodeCount + *cacheCluster.NumCacheNodes

				metrics = append(metrics, m.Metric{
					Kind: m.Gauge,
					Time: time.Now(),
					Name: "aws.elasticache.cluster.nodes.count",
					Value: float64(*cacheCluster.NumCacheNodes),
					Unit: "count",
					Tags: m.MetricTags{
						{ Label: "cluster_id", Value: cacheCluster.CacheClusterId },
					},
				})
			},
		)
		if err != nil {
			return err
		}

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.node.count",
			Value: float64(nodeCount),
			Unit:  "count",
		})

		return w.WriteMetrics(metrics)
	})
}

func iterateCacheParameterGroups(client elasticacheiface.ElastiCacheAPI, fn func(*awsec.CacheParameterGroup)) error {
	return client.DescribeCacheParameterGroupsPages(
		&awsec.DescribeCacheParameterGroupsInput{},
		func(page *awsec.DescribeCacheParameterGroupsOutput, lastPage bool) bool {
			for _, cacheParameterGroup := range page.CacheParameterGroups {
				fn(cacheParameterGroup)
			}
			return true
		},
	)
}

func iterateCacheClusterPages(client elasticacheiface.ElastiCacheAPI, fn func(cluster *awsec.CacheCluster)) error {
	return client.DescribeCacheClustersPages(
		&awsec.DescribeCacheClustersInput{},
		func(page *awsec.DescribeCacheClustersOutput, lastPage bool) bool {
			for _, cacheCluster := range page.CacheClusters {
				fn(cacheCluster)
			}
			return true
		},
	)
}
