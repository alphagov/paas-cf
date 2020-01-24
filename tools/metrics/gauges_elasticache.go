package main

import (
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface"
	"github.com/cloudfoundry-community/go-cfclient"
	"net/url"
	"regexp"
	"strings"
	"time"

	"code.cloudfoundry.org/lager"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

const NonClusteredIdPattern = "[a-z0-9]+-\\d+"
const ClusteredIdPattern = "[a-z0-9]+-\\d+-\\d+"

type RedisServiceDetails struct {
	ServiceInstance cfclient.ServiceInstance
	Space           cfclient.Space
	Org             cfclient.Org
}

func ElasticCacheInstancesGauge(
	logger lager.Logger,
	ecs *elasticache.ElasticacheService,
	cfAPI cfclient.CloudFoundryClient,
	clusterIdHashingFunction elasticache.ElasticacheClusterIdHashingFunction,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsess := logger.Session("elasticache-gauges")

		metrics, err := cacheParameterMetrics(ecs)
		if err != nil {
			return err
		}

		clusterMetrics, err := cacheClusterMetrics(lsess, ecs, cfAPI, clusterIdHashingFunction)
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

func cacheClusterMetrics(
	logger lager.Logger,
	ecs *elasticache.ElasticacheService,
	cfAPI cfclient.CloudFoundryClient,
	clusterIdHashingFunction elasticache.ElasticacheClusterIdHashingFunction,
) ([]m.Metric, error) {
	redisServiceDetails, err := fetchRedisServiceInstances(cfAPI)
	if err != nil {
		return nil, err
	}

	userSuppliedClusterIdToDetail := map[string]RedisServiceDetails{}
	for _, details := range redisServiceDetails {
		userSuppliedClusterId := clusterIdHashingFunction(details.ServiceInstance.Guid)
		userSuppliedClusterIdToDetail[userSuppliedClusterId] = details
	}

	metrics := []m.Metric{}
	nodeCount := int64(0)
	err = iterateCacheClusterPages(
		ecs.Client,
		func(cacheCluster *awsec.CacheCluster) error {
			nodeCount = nodeCount + *cacheCluster.NumCacheNodes
			elasticacheClusterId := aws.StringValue(cacheCluster.CacheClusterId)
			userSuppliedClusterId := cleanClusterId(cacheCluster)

			details, ok := userSuppliedClusterIdToDetail[userSuppliedClusterId]
			if !ok {
				e := fmt.Errorf("unable to find details of cluster with user supplied cluster id of %s", userSuppliedClusterId)
				logger.Error("details-not-found", e, lager.Data{
					"cluster_id":               elasticacheClusterId,
					"user_supplied_cluster_id": userSuppliedClusterId,
				})
				return e
			}

			metrics = append(metrics, m.Metric{
				Kind:  m.Gauge,
				Time:  time.Now(),
				Name:  "aws.elasticache.cluster.nodes.count",
				Value: float64(*cacheCluster.NumCacheNodes),
				Unit:  "count",
				Tags: m.MetricTags{
					{Label: "cluster_id", Value: userSuppliedClusterId},
					{Label: "elasticache_cluster_id", Value: elasticacheClusterId},
					{Label: "service_instance_guid", Value: details.ServiceInstance.Guid},
					{Label: "space_name", Value: details.Space.Name},
					{Label: "space_guid", Value: details.Space.Guid},
					{Label: "org_name", Value: details.Org.Name},
					{Label: "org_guid", Value: details.Org.Guid},
				},
			})
			return nil
		},
	)
	if err != nil {
		return nil, err
	}

	metrics = append(metrics, m.Metric{
		Kind:  m.Gauge,
		Time:  time.Now(),
		Name:  "aws.elasticache.node.count",
		Value: float64(nodeCount),
		Unit:  "count",
	})
	return metrics, nil
}

func fetchRedisServiceInstances(cfAPI cfclient.CloudFoundryClient) ([]RedisServiceDetails, error) {
	spacesCache := map[string]cfclient.Space{}
	orgsCache := map[string]cfclient.Org{}

	servicesWithRedisLabel, err := cfAPI.ListServicesByQuery(url.Values{
		"q": []string{"label:redis"},
	})

	if err != nil {
		return []RedisServiceDetails{}, err
	}

	if len(servicesWithRedisLabel) == 0 {
		return nil, fmt.Errorf("could not find service with label=redis")
	}

	redisServiceGuid := servicesWithRedisLabel[0].Guid
	redisServicePlans, err := cfAPI.ListServicePlansByQuery(url.Values{
		"q": []string{"service_guid:" + redisServiceGuid},
	})

	if err != nil {
		return []RedisServiceDetails{}, err
	}

	var serviceDetails []RedisServiceDetails
	for _, plan := range redisServicePlans {
		planInstances, err := cfAPI.ListServiceInstancesByQuery(url.Values{
			"q": []string{"service_plan_guid:" + plan.Guid},
		})

		if err != nil {
			return []RedisServiceDetails{}, err
		}

		for _, instance := range planInstances {
			var space cfclient.Space
			if s, ok := spacesCache[instance.SpaceGuid]; ok {
				space = s
			} else {
				space, err = cfAPI.GetSpaceByGuid(instance.SpaceGuid)
				if err != nil {
					return []RedisServiceDetails{}, err
				}

				spacesCache[space.Guid] = space
			}

			var org cfclient.Org
			if o, ok := orgsCache[space.OrganizationGuid]; ok {
				org = o
			} else {
				org, err = cfAPI.GetOrgByGuid(space.OrganizationGuid)
				if err != nil {
					return []RedisServiceDetails{}, err
				}

				orgsCache[org.Guid] = org
			}

			serviceDetails = append(serviceDetails, RedisServiceDetails{
				ServiceInstance: instance,
				Space:           space,
				Org:             org,
			})
		}
	}

	return serviceDetails, nil
}

// The AWS API documentation says that
// CacheClusterId is the user-supplied name
// of the cache cluster. However, in reality,
// it returns that value, plus some extra
// information.
//
// It is in the format {user-supplied}-{n}[-{m}].
// Typically, our cache cluster names have the
// format "cf-{FNV hash of guid}", but that's
// not guaranteed, so this method only strips
// the last one/two parts.
func cleanClusterId(cluster *awsec.CacheCluster) string {
	clusteredRegex := regexp.MustCompile(ClusteredIdPattern)
	unclusteredRegex := regexp.MustCompile(NonClusteredIdPattern)

	strBytes := []byte(aws.StringValue(cluster.CacheClusterId))

	parts := strings.Split(
		aws.StringValue(cluster.CacheClusterId),
		"-",
	)

	var topIndex int
	if clusteredRegex.Match(strBytes) {
		topIndex = len(parts) - 2 // Minus two because we want to stop before the second-to-last part
		return strings.Join(parts[:topIndex], "-")

	} else if unclusteredRegex.Match(strBytes) {
		topIndex = len(parts) - 1 // Minus one because we want to stop before the last part
		return strings.Join(parts[:topIndex], "-")

	} else {
		// Return the original value if it doesn't match either pattern
		return aws.StringValue(cluster.CacheClusterId)
	}
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
