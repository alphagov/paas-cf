package health

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/health"
)

func NewService(sess *session.Session) *HealthService {
	return &HealthService{
		Client: health.New(sess),
	}
}
