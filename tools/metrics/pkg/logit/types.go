package logit

import (
	"code.cloudfoundry.org/lager"
	"net/url"
)

type Client struct {
	logger           lager.Logger
	elasticsearchUrl *url.URL
}

//go:generate go run github.com/maxbrunsfeld/counterfeiter/v6 . LogitElasticsearchClient
type LogitElasticsearchClient interface {
	Search(string, interface{}) error
}
