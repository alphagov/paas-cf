package main

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3iface"
)

type S3Service struct {
	Client s3iface.S3API
}

func NewS3Service(sess *session.Session) *S3Service {
	return &S3Service{
		Client: s3.New(sess),
	}
}
