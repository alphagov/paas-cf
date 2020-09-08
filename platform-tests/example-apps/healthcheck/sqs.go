package main

import (
	"fmt"
	"net/http"

	"github.com/aws/aws-sdk-go/aws/credentials"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/pkg/errors"
)

type SQSCredentials struct {
	AccessKeyID     string
	SecretAccessKey string
	QueueURL        string
	DLQueueURL      string
	Region          string
}

func sqsHandler(w http.ResponseWriter, r *http.Request) {
	err := testSQSQueueAccess()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testSQSQueueAccess() error {

	var creds SQSCredentials
	err := getVCAPServiceCredentials("aws-sqs-queue", &creds)
	if err != nil {
		return errors.Wrap(err, "failed to parse VCAP_SERVICES")
	}

	sess := session.Must(session.NewSession(&aws.Config{
		Region:      aws.String(creds.Region),
		Credentials: credentials.NewStaticCredentials(creds.AccessKeyID, creds.SecretAccessKey, ""),
	}))
	sqsClient := sqs.New(sess)

	queueURLS := []string{
		creds.QueueURL,
		creds.DLQueueURL,
	}

	for _, queueURL := range queueURLS {
		err := tryUsingQueue(sqsClient, queueURL)
		if err != nil {
			return fmt.Errorf("failed to use queue %s: %s", queueURL, err)
		}
	}

	return nil
}

func tryUsingQueue(sqsClient *sqs.SQS, queueURL string) error {
	_, err := sqsClient.SendMessage(&sqs.SendMessageInput{
		MessageAttributes: map[string]*sqs.MessageAttributeValue{
			"Title": {
				DataType:    aws.String("String"),
				StringValue: aws.String("The Whistler"),
			},
			"Author": {
				DataType:    aws.String("String"),
				StringValue: aws.String("John Grisham"),
			},
			"WeeksOn": {
				DataType:    aws.String("Number"),
				StringValue: aws.String("6"),
			},
		},
		MessageBody: aws.String("Information about current NY Times fiction bestseller for week of 12/11/2016."),
		QueueUrl:    &queueURL,
	})
	if err != nil {
		return err
	}

	var visTimeout int64 = 0
	msgResult, err := sqsClient.ReceiveMessage(&sqs.ReceiveMessageInput{
		AttributeNames: []*string{
			aws.String(sqs.MessageSystemAttributeNameSentTimestamp),
		},
		MessageAttributeNames: []*string{
			aws.String(sqs.QueueAttributeNameAll),
		},
		QueueUrl:            &queueURL,
		MaxNumberOfMessages: aws.Int64(1),
		VisibilityTimeout:   &visTimeout,
	})
	if err != nil {
		return err
	}
	if len(msgResult.Messages) != 1 {
		return fmt.Errorf("expected to 1x recv msg from queue, but got 0")
	}

	return nil
}
