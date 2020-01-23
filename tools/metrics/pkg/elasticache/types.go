package elasticache

import (
	"github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface"
)

type ElasticacheClusterIdHashingFunction = func(value string) string

type ElasticacheService struct {
	Client elasticacheiface.ElastiCacheAPI
}
