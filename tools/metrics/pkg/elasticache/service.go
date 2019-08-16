package elasticache

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/elasticache"
)

func NewService(sess *session.Session) *ElasticacheService {
	return &ElasticacheService{
		Client: elasticache.New(sess),
	}
}
