package health

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	awshealth "github.com/aws/aws-sdk-go/service/health"
)

func NewService(sess *session.Session) *HealthService {
	usEast1Session := sess.Copy(&aws.Config{
		Region: aws.String("us-east-1"),
	})
	return &HealthService{
		Client: awshealth.New(usEast1Session),
	}
}

func (hs HealthService) CountOpenEventsForServiceInRegion(service string, region string) (int, error) {
	apiResult, err := hs.Client.DescribeEvents(&awshealth.DescribeEventsInput{
		Filter: &awshealth.EventFilter{
			EventStatusCodes: []*string {
				aws.String(awshealth.EventStatusCodeOpen),
			},
			Services: []*string {
				aws.String(service),
			},
			Regions: []*string {
				aws.String(region),
			},
			EventTypeCategories: []*string {
				aws.String(awshealth.EventTypeCategoryInvestigation),
				aws.String(awshealth.EventTypeCategoryIssue),
				aws.String(awshealth.EventTypeCategoryScheduledChange),
			},
		},
		// We don't really expect there to be >100
		// open events for a single service.
		// If there are, that's a pretty serious
		// incident and we probably know about it
		// already, so this number isn't super important
		MaxResults: aws.Int64(100),
	})

	if err != nil {
		return -1, err
	}

	return len(apiResult.Events), nil
}
