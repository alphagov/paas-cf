package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/aws/aws-sdk-go/aws/credentials"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/pkg/errors"
)

const testS3File = "cats-test-file"
const testS3Content = "cats-test-content"

func s3Handler(w http.ResponseWriter, r *http.Request) {
	err := testS3BucketAccess()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testS3BucketAccess() error {
	var vcapService struct {
		AWSRegion          string `json:"aws_region"`
		AWSAccessKeyID     string `json:"aws_access_key_id"`
		AWSSecretAccessKey string `json:"aws_secret_access_key"`
		BucketName         string `json:"bucket_name"`
	}

	err := getVCAPServiceCredentials("aws-s3-bucket", &vcapService)
	if err != nil {
		return errors.Wrap(err, "failed to parse VCAP_SERVICES")
	}

	sess := session.Must(session.NewSession(&aws.Config{
		Region:      aws.String(vcapService.AWSRegion),
		Credentials: credentials.NewStaticCredentials(vcapService.AWSAccessKeyID, vcapService.AWSSecretAccessKey, ""),
	}))
	s3Client := s3.New(sess)

	_, err = s3Client.ListObjects(&s3.ListObjectsInput{
		Bucket: aws.String(vcapService.BucketName),
	})
	if err != nil {
		return err
	}

	_, err = s3Client.PutObject(&s3.PutObjectInput{
		Bucket: aws.String(vcapService.BucketName),
		Key:    aws.String(testS3File),
		Body:   strings.NewReader(testS3Content),
	})
	if err != nil {
		return err
	}

	getObjectOutput, err := s3Client.GetObject(&s3.GetObjectInput{
		Bucket: aws.String(vcapService.BucketName),
		Key:    aws.String(testS3File),
	})
	if err != nil {
		return err
	}

	content, err := ioutil.ReadAll(getObjectOutput.Body)
	if err != nil {
		return err
	}
	defer getObjectOutput.Body.Close()

	if string(content) != testS3Content {
		return fmt.Errorf("content mismatch, was writing %q but read %q", testS3Content, string(content))
	}

	_, err = s3Client.DeleteObject(&s3.DeleteObjectInput{
		Bucket: aws.String(vcapService.BucketName),
		Key:    aws.String(testS3File),
	})
	if err != nil {
		return err
	}

	return nil
}
