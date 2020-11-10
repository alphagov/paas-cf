package shield

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	awsshield "github.com/aws/aws-sdk-go/service/shield"
	"time"
)

func NewService(sess *session.Session) *ShieldService {
	usEast1Session := sess.Copy(&aws.Config{
		Region: aws.String("us-east-1"),
	})
	return &ShieldService{
		Client: awsshield.New(usEast1Session),
	}
}

func (s ShieldService) CountOnGoingAttacks() (int, error) {
	yesterday := time.Now().Add(-24 * time.Hour)
	tomorrow := time.Now().Add(24 * time.Hour)

	attacks, err := s.Client.ListAttacks(&awsshield.ListAttacksInput{
		StartTime:    &awsshield.TimeRange{
			FromInclusive: &yesterday,
		},
		EndTime:      &awsshield.TimeRange{
			ToExclusive:   &tomorrow,
		},
	})

	if err != nil {
		return 0, err
	}

	return len(attacks.AttackSummaries), nil
}
