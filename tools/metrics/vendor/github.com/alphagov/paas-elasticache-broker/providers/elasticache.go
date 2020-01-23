package providers

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/service/elasticache"
)

// ElastiCache is a partially extracted interface from the AWS Elasticache SDK
//
//go:generate counterfeiter -o mocks/elasticache.go . ElastiCache
type ElastiCache interface {
	CreateCacheParameterGroupWithContext(ctx aws.Context, input *elasticache.CreateCacheParameterGroupInput, opts ...request.Option) (*elasticache.CreateCacheParameterGroupOutput, error)
	CreateReplicationGroupWithContext(ctx aws.Context, input *elasticache.CreateReplicationGroupInput, opts ...request.Option) (*elasticache.CreateReplicationGroupOutput, error)
	DeleteCacheParameterGroupWithContext(ctx aws.Context, input *elasticache.DeleteCacheParameterGroupInput, opts ...request.Option) (*elasticache.DeleteCacheParameterGroupOutput, error)
	DeleteReplicationGroupWithContext(ctx aws.Context, input *elasticache.DeleteReplicationGroupInput, opts ...request.Option) (*elasticache.DeleteReplicationGroupOutput, error)
	DescribeReplicationGroupsWithContext(ctx aws.Context, input *elasticache.DescribeReplicationGroupsInput, opts ...request.Option) (*elasticache.DescribeReplicationGroupsOutput, error)
	DescribeCacheClustersWithContext(ctx aws.Context, input *elasticache.DescribeCacheClustersInput, opts ...request.Option) (*elasticache.DescribeCacheClustersOutput, error)
	DescribeCacheParametersWithContext(ctx aws.Context, input *elasticache.DescribeCacheParametersInput, opts ...request.Option) (*elasticache.DescribeCacheParametersOutput, error)
	ModifyCacheParameterGroupWithContext(ctx aws.Context, input *elasticache.ModifyCacheParameterGroupInput, opts ...request.Option) (*elasticache.CacheParameterGroupNameMessage, error)
	DescribeSnapshotsPagesWithContext(ctx aws.Context, input *elasticache.DescribeSnapshotsInput, fn func(*elasticache.DescribeSnapshotsOutput, bool) bool, opts ...request.Option) error
	ListTagsForResourceWithContext(ctx aws.Context, input *elasticache.ListTagsForResourceInput, opts ...request.Option) (*elasticache.TagListMessage, error)
}
