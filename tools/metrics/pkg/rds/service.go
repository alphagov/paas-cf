package rds

import (
	"github.com/aws/aws-sdk-go/aws/session"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
	"github.com/aws/aws-sdk-go/service/rds/rdsiface"
)


type RDSService struct {
	Client rdsiface.RDSAPI
}


func NewService(sess *session.Session) *RDSService {
	return &RDSService{
		Client: awsrds.New(sess),
	}
}

