package main

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface"
)

type ElasticacheService struct {
	Client elasticacheiface.ElastiCacheAPI
}

func NewElasticacheService(sess *session.Session) *ElasticacheService {
	return &ElasticacheService{
		Client: elasticache.New(sess),
	}
}
