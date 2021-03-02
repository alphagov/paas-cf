package servicequotas

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/servicequotas"
)

func NewService(sess *session.Session) *ServiceQuotas {
	return &ServiceQuotas{
		Client: servicequotas.New(sess),
	}
}
