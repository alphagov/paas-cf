package s3

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

func NewService(sess *session.Session) *S3Service {
	return &S3Service{
		Client: s3.New(sess),
	}
}
