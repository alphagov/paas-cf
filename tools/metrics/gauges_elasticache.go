package main

import (
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/aws/aws-sdk-go/service/elasticache"
)

func ElasticCacheInstancesGauge(
	logger lager.Logger,
	ecs *ElasticacheService,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		metrics := []Metric{}

		cacheParameterGroupCount := 0
		err := ecs.Client.DescribeCacheParameterGroupsPages(
			&elasticache.DescribeCacheParameterGroupsInput{},
			func(page *elasticache.DescribeCacheParameterGroupsOutput, lastPage bool) bool {
				cacheParameterGroupCount = cacheParameterGroupCount + len(page.CacheParameterGroups)
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
		})

		nodeCount := 0
		err = ecs.Client.DescribeReplicationGroupsPages(
			&elasticache.DescribeReplicationGroupsInput{},
			func(page *elasticache.DescribeReplicationGroupsOutput, lastPage bool) bool {
				for _, replicationGroup := range page.ReplicationGroups {
					nodeCount = nodeCount + len(replicationGroup.MemberClusters)
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
		})

		return w.WriteMetrics(metrics)
	})
}
