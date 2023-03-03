package logit

import (
	"code.cloudfoundry.org/lager"
	"net/url"
)

type Client struct {
	logger           lager.Logger
	elasticsearchUrl *url.URL
}

//go:generate counterfeiter -o logitfakes/fake_logit_elasticsearch_client.go . LogitElasticsearchClient
type LogitElasticsearchClient interface {
	Search(string, interface{}) error
}
