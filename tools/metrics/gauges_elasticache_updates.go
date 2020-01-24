package main

import (
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	"github.com/aws/aws-sdk-go/aws"
	awsec "github.com/aws/aws-sdk-go/service/elasticache"
)

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
