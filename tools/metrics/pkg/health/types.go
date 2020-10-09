package health

import (
	"github.com/aws/aws-sdk-go/service/health/healthiface"
)

type HealthService struct {
	Client healthiface.HealthAPI
}
type HealthServiceInterface interface {
	CountOpenEventsForServiceInRegion(service string, region string) (int, error)
}
