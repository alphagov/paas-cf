package main

import (
	"fmt"
	paasElasticacheBrokerRedis "github.com/alphagov/paas-elasticache-broker/providers/redis"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface"
	"github.com/cloudfoundry-community/go-cfclient"
	"net/url"
	"strings"
	"time"

	"code.cloudfoundry.org/lager"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

type CFRedisService struct {
	ServiceInstance cfclient.ServiceInstance
	Space           cfclient.Space
	Org             cfclient.Org
}

func ElasticacheInstancesGauge(
	logger lager.Logger,
	ecs *elasticache.ElasticacheService,
	cfAPI cfclient.CloudFoundryClient,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("elasticache-gauges")

		metrics, err := cacheParameterMetrics(ecs)
		if err != nil {
			return err
		}

		clusterMetrics, err := cacheClusterMetrics(lsess, ecs, cfAPI)
		if err != nil {
			return err
		}
		metrics = append(metrics, clusterMetrics...)

		return w.WriteMetrics(metrics)
	})
}

func cacheParameterMetrics(ecs *elasticache.ElasticacheService) ([]m.Metric, error) {
	cacheParameterGroupCount := 0
	err := iterateCacheParameterGroups(
		ecs.Client,
		func(cacheParameterGroup *awsec.CacheParameterGroup) error {
			if !strings.HasPrefix(*cacheParameterGroup.CacheParameterGroupName, "default.") {
				cacheParameterGroupCount++
			}
			return nil
		},
	)
	if err != nil {
		return nil, err
	}

	return []m.Metric{{
		Kind:  m.Gauge,
		Time:  time.Now(),
		Name:  "aws.elasticache.cache_parameter_group.count",
		Value: float64(cacheParameterGroupCount),
		Unit:  "count",
	}}, nil
}

func cacheClusterMetrics(logger lager.Logger, ecs *elasticache.ElasticacheService, cfAPI cfclient.CloudFoundryClient, ) ([]m.Metric, error) {
	redisServiceDetails, err := fetchRedisServiceInstances(cfAPI)
	if err != nil {
		return nil, err
	}

	replicationGroupIdToServiceDetail := map[string]CFRedisService{}
	for _, details := range redisServiceDetails {
		replicationGroupId := paasElasticacheBrokerRedis.GenerateReplicationGroupName(details.ServiceInstance.Guid)
		replicationGroupIdToServiceDetail[replicationGroupId] = details
	}

	metrics := []m.Metric{}
	totalNodeCount := int64(0)

	replicationGroupIdToNodeCount := map[string]int{}
	err = iterateCacheClusterPages(
		ecs.Client,
		func(cacheCluster *awsec.CacheCluster) error {
			totalNodeCount = totalNodeCount + *cacheCluster.NumCacheNodes

			replicationGroupId := aws.StringValue(cacheCluster.ReplicationGroupId)
			if _, ok := replicationGroupIdToNodeCount[replicationGroupId]; !ok {
				replicationGroupIdToNodeCount[replicationGroupId] = 0
			}

			replicationGroupIdToNodeCount[replicationGroupId] =
				replicationGroupIdToNodeCount[replicationGroupId] + int(*cacheCluster.NumCacheNodes)
			return nil
		},
	)
	if err != nil {
		return nil, err
	}

	for _, details := range redisServiceDetails {
		replicationGroupId := paasElasticacheBrokerRedis.GenerateReplicationGroupName(details.ServiceInstance.Guid)
		count := replicationGroupIdToNodeCount[replicationGroupId]

		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "aws.elasticache.replication_group.nodes.count",
			Value: float64(count),
			Unit:  "count",
			Tags: m.MetricTags{
				{Label: "replication_group_id", Value: replicationGroupId},
				{Label: "service_instance_guid", Value: details.ServiceInstance.Guid},
				{Label: "space_name", Value: details.Space.Name},
				{Label: "space_guid", Value: details.Space.Guid},
				{Label: "org_name", Value: details.Org.Name},
				{Label: "org_guid", Value: details.Org.Guid},
			},
		})
	}

	metrics = append(metrics, m.Metric{
		Kind:  m.Gauge,
		Time:  time.Now(),
		Name:  "aws.elasticache.node.count",
		Value: float64(totalNodeCount),
		Unit:  "count",
	})
	return metrics, nil
}

func fetchRedisServiceInstances(cfAPI cfclient.CloudFoundryClient) ([]CFRedisService, error) {
	spacesCache := map[string]cfclient.Space{}
	orgsCache := map[string]cfclient.Org{}

	servicesWithRedisLabel, err := cfAPI.ListServicesByQuery(url.Values{
		"q": []string{"label:redis"},
	})

	if err != nil {
		return []CFRedisService{}, err
	}

	if len(servicesWithRedisLabel) == 0 {
		return nil, fmt.Errorf("could not find service with label=redis")
	}

	redisServiceGuid := servicesWithRedisLabel[0].Guid
	redisServicePlans, err := cfAPI.ListServicePlansByQuery(url.Values{
		"q": []string{"service_guid:" + redisServiceGuid},
	})

	if err != nil {
		return []CFRedisService{}, err
	}

	var serviceDetails []CFRedisService
	for _, plan := range redisServicePlans {
		planInstances, err := cfAPI.ListServiceInstancesByQuery(url.Values{
			"q": []string{"service_plan_guid:" + plan.Guid},
		})

		if err != nil {
			return []CFRedisService{}, err
		}

		for _, instance := range planInstances {
			var space cfclient.Space
			if s, ok := spacesCache[instance.SpaceGuid]; ok {
				space = s
			} else {
				space, err = cfAPI.GetSpaceByGuid(instance.SpaceGuid)
				if err != nil {
					return []CFRedisService{}, err
				}

				spacesCache[space.Guid] = space
			}

			var org cfclient.Org
			if o, ok := orgsCache[space.OrganizationGuid]; ok {
				org = o
			} else {
				org, err = cfAPI.GetOrgByGuid(space.OrganizationGuid)
				if err != nil {
					return []CFRedisService{}, err
				}

				orgsCache[org.Guid] = org
			}

			serviceDetails = append(serviceDetails, CFRedisService{
				ServiceInstance: instance,
				Space:           space,
				Org:             org,
			})
		}
	}

	return serviceDetails, nil
}

func iterateCacheParameterGroups(client elasticacheiface.ElastiCacheAPI, fn func(*awsec.CacheParameterGroup) error) error {
	errs := []error{}
	err := client.DescribeCacheParameterGroupsPages(
		&awsec.DescribeCacheParameterGroupsInput{},
		func(page *awsec.DescribeCacheParameterGroupsOutput, lastPage bool) bool {
			for _, cacheParameterGroup := range page.CacheParameterGroups {
				err := fn(cacheParameterGroup)
				if err != nil {
					errs = append(errs, err)
				}
			}
			return true
		},
	)
	if err != nil {
		return err
	}
	if len(errs) > 0 {
		return errs[0]
	}
	return nil
}

func iterateCacheClusterPages(client elasticacheiface.ElastiCacheAPI, fn func(cluster *awsec.CacheCluster) error) error {
	errs := []error{}
	err := client.DescribeCacheClustersPages(
		&awsec.DescribeCacheClustersInput{},
		func(page *awsec.DescribeCacheClustersOutput, lastPage bool) bool {
			for _, cacheCluster := range page.CacheClusters {
				err := fn(cacheCluster)
				if err != nil {
					errs = append(errs, err)
				}
			}
			return true
		},
	)
	if err != nil {
		return err
	}
	if len(errs) > 0 {
		return errs[0]
	}
	return nil
}
