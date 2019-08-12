package cloudwatch

import (
	"code.cloudfoundry.org/lager"
	"github.com/aws/aws-sdk-go/service/cloudwatch/cloudwatchiface"
)

type CloudWatchService struct {
	Client cloudwatchiface.CloudWatchAPI
	Logger lager.Logger
}

type metricMapping struct {
	Name      string
	Statistic string
}
