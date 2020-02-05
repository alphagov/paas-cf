package elasticache

import (
	"github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface"
)

type ElasticacheService struct {
	Client elasticacheiface.ElastiCacheAPI
}
