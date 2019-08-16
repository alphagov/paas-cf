package cloudfront

import (
	"github.com/aws/aws-sdk-go/service/cloudfront/cloudfrontiface"
)

type CloudFrontServiceInterface interface {
	CustomDomains() ([]CustomDomain, error)
}

type CloudFrontService struct {
	Client cloudfrontiface.CloudFrontAPI
}
