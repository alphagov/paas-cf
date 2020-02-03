package main

import (
	"fmt"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/cloudfoundry-community/go-cfclient"
	"time"
)

func ElasticacheUpdatesGauge(
	ecs *elasticache.ElasticacheService,
	cfAPI cfclient.CloudFoundryClient,
	hashingFunction elasticache.ElasticacheClusterIdHashingFunction,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		redisServiceUpdateNames, err := ListAvailableRedisServiceUpdates(ecs)
		if err != nil {
			return err
		}

		metrics, err := serviceUpdateLevelMetrics(redisServiceUpdateNames, ecs)
		if err != nil {
			return err
		}

		clusterMetrics, err := serviceInstanceLevelMetrics(redisServiceUpdateNames, cfAPI, ecs, hashingFunction)
		if err != nil {
			return err
		}
		metrics = append(metrics, clusterMetrics...)

		w.WriteMetrics(metrics)
		return nil
	})
}

func serviceUpdateLevelMetrics(redisServiceUpdateNames []string, ecs *elasticache.ElasticacheService) ([]m.Metric, error) {
	metrics := []m.Metric{}
	for _, redisServiceUpdateName := range redisServiceUpdateNames {
		replicationGroupIds, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate(redisServiceUpdateName, ecs)
		if err != nil {
			return nil, fmt.Errorf("error fetching replication group ids for service update '%s': %s", redisServiceUpdateName, err)
		}

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.service_update.not_applied.count",
			Value: float64(len(replicationGroupIds)),
			Unit:  "count",
			Tags: m.MetricTags{
				{Label: "elasticache_service_update", Value: redisServiceUpdateName},
			},
		})
	}
	return metrics, nil
}

func serviceInstanceLevelMetrics(redisServiceUpdateNames []string, cfAPI cfclient.CloudFoundryClient, ecs *elasticache.ElasticacheService, hashingFunction elasticache.ElasticacheClusterIdHashingFunction) ([]m.Metric, error) {
	redisServiceInstances, err := fetchRedisServiceInstances(cfAPI)

	if err != nil {
		return nil, err
	}

	serviceUpdateToClustersAwaitingUpdate := map[string][]string{}
	for _, updateName := range redisServiceUpdateNames {
		clusters, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate(updateName, ecs)
		if err != nil {
			return nil, err
		}

		serviceUpdateToClustersAwaitingUpdate[updateName] = clusters
	}

	var metrics []m.Metric
	for _, instance := range redisServiceInstances {
		for _, updateName := range redisServiceUpdateNames {
			unappliedClusters := serviceUpdateToClustersAwaitingUpdate[updateName]

			// Judging from the API responses we've seen,
			// ReplicationGroupID (the only field we get
			// back from the DescribeUpdateActions API)
			// matches the user-supplied cluster id perfectly.
			// All we need to do here is repeat the hash of
			// the service guid.
			clusterId := hashingFunction(instance.ServiceInstance.Guid)

			applied := 1
			if stringInSlice(unappliedClusters, clusterId) {
				applied = 0
			}

			metrics = append(metrics, m.Metric{
				Kind:  m.Gauge,
				Name:  "aws.elasticache.cluster.update_applied",
				Value: float64(applied),
				Tags: m.MetricTags{
					{Label: "elasticache_service_update", Value: updateName},
					{Label: "elasticache_cache_cluster_id", Value: clusterId},
				},
			})
		}
	}

	return metrics, nil
}

func ListAvailableRedisServiceUpdates(ecs *elasticache.ElasticacheService) ([]string, error) {
	serviceUpdateNames := []string{}

	err := ecs.Client.DescribeServiceUpdatesPages(
		&awsec.DescribeServiceUpdatesInput{
			ServiceUpdateStatus: []*string{
				aws.String("available"),
			},
		},
		func(output *awsec.DescribeServiceUpdatesOutput, lastPage bool) bool {
			for _, describedServiceUpdate := range output.ServiceUpdates {
				if aws.StringValue(describedServiceUpdate.Engine) != "redis" {
					continue
				}

				serviceUpdateName := aws.StringValue(describedServiceUpdate.ServiceUpdateName)
				serviceUpdateNames = append(serviceUpdateNames, serviceUpdateName)
			}

			return true
		},
	)

	if err != nil {
		return nil, err
	}

	return serviceUpdateNames, nil
}

func ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate(serviceUpdateName string, ecs *elasticache.ElasticacheService) ([]string, error) {
	replicationGroupIds := []string{}
	err := ecs.Client.DescribeUpdateActionsPages(
		&awsec.DescribeUpdateActionsInput{
			ServiceUpdateName: aws.String(serviceUpdateName),
			ServiceUpdateStatus: []*string{
				aws.String("available"),
			},
			UpdateActionStatus: []*string{
				aws.String("not-applied"),
			},
		},
		func(output *awsec.DescribeUpdateActionsOutput, lastPage bool) bool {
			for _, describedUpdateAction := range output.UpdateActions {
				// We use replication group ID because it seems to be the only field available
				// for mapping available update actions to cache clusters (i.e., Redises.)
				// CacheClusterId *is* listed in some of the AWS API docs but it wasn't actually
				// in the API replies we received :(
				replicationGroupId := aws.StringValue(describedUpdateAction.ReplicationGroupId)
				replicationGroupIds = append(replicationGroupIds, replicationGroupId)
			}

			return true
		},
	)
	if err != nil {
		return nil, err
	}

	return replicationGroupIds, nil
}

func stringInSlice(haystack []string, needle string) bool {
	for _, s := range haystack {
		if s == needle {
			return true
		}
	}

	return false
}
