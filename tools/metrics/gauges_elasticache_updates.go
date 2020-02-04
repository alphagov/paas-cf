package main

import (
	"code.cloudfoundry.org/lager"
	"fmt"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	paasElasticacheBrokerRedis "github.com/alphagov/paas-elasticache-broker/providers/redis"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/cloudfoundry-community/go-cfclient"
	"strings"
	"time"
)

func ElasticacheUpdatesGauge(
	logger lager.Logger,
	ecs *elasticache.ElasticacheService,
	cfAPI cfclient.CloudFoundryClient,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		logSess := logger.Session("metric-poller")
		elasticacheUpdateNames, err := ListAvailableRedisServiceUpdates(ecs)
		if err != nil {
			logSess.Error("list-available-redis-service-updates", err)
			return err
		}

		metrics, err := serviceUpdateNotAppliedCount(logSess, elasticacheUpdateNames, ecs)
		if err != nil {
			return err
		}

		redisServiceDetails, err := fetchRedisServiceInstances(cfAPI)
		if err != nil {
			logSess.Error("fetch-redis-service-instances", err)
			return err
		}

		for _, elasticacheUpdateName := range elasticacheUpdateNames {
			metrics2, err := serviceUpdateRequiredInstances(
				logSess,
				redisServiceDetails,
				elasticacheUpdateName,
				ecs,
			)
			if err != nil {
				logSess.Error("service-update-level-metrics", err, lager.Data{
					"elasticache_update_name": elasticacheUpdateName,
				})
				return err
			}
			metrics = append(metrics, metrics2...)
		}

		w.WriteMetrics(metrics)
		return nil
	})
}

func serviceUpdateNotAppliedCount(logger lager.Logger, elasticacheUpdateNames []string, ecs *elasticache.ElasticacheService) ([]m.Metric, error) {
	metrics := []m.Metric{}
	for _, elasticacheUpdateName := range elasticacheUpdateNames {
		replicationGroupIds, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate(elasticacheUpdateName, ecs)
		if err != nil {
			logger.Error(
				"list-replication-group-ids-with-available-update-actions-for-service-update",
				err,
				lager.Data{"service_update": elasticacheUpdateName},
			)
			return nil, fmt.Errorf("error fetching replication group ids for service update '%s': %s", elasticacheUpdateName, err)
		}

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.service_update.not_applied.count",
			Value: float64(len(replicationGroupIds)),
			Unit:  "count",
			Tags: m.MetricTags{
				{Label: "elasticache_service_update", Value: elasticacheUpdateName},
			},
		})
	}
	return metrics, nil
}

func serviceUpdateRequiredInstances(
	logger lager.Logger,
	cfRedisServiceInstances []CFRedisService,
	elasticacheUpdateName string,
	ecs *elasticache.ElasticacheService,
) ([]m.Metric, error) {
	replicationGroupIdsAwaitingUpdate, err := ListReplicationGroupIdsWithAvailableUpdateActionsForServiceUpdate(elasticacheUpdateName, ecs)
	if err != nil {
		logger.Error(
			"list-replication-group-ids-with-available-update-actions-for-service-update",
			err,
			lager.Data{"service_update": elasticacheUpdateName},
		)
		return nil, err
	}

	var metrics []m.Metric
	for _, instance := range cfRedisServiceInstances {
		replicationGroupId := paasElasticacheBrokerRedis.GenerateReplicationGroupName(instance.ServiceInstance.Guid)
		if !stringInSlice(replicationGroupIdsAwaitingUpdate, replicationGroupId) {
			continue
		}

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Name:  "aws.elasticache.cluster.update_required",
			Value: float64(1),
			Tags: m.MetricTags{
				{Label: "elasticache_service_update", Value: elasticacheUpdateName},
				{Label: "elasticache_replication_group_id", Value: replicationGroupId},
				{Label: "service_instance_guid", Value: instance.ServiceInstance.Guid},
				{Label: "space_guid", Value: instance.Space.Guid},
				{Label: "space_name", Value: instance.Space.Name},
				{Label: "org_guid", Value: instance.Org.Guid},
				{Label: "org_name", Value: instance.Org.Name},
			},
		})
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
				if !strings.Contains(aws.StringValue(describedServiceUpdate.Engine), "redis") {
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
