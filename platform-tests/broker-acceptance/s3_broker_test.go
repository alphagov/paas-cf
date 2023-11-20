package broker_acceptance_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws/credentials"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"

	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/generator"
	"github.com/cloudfoundry/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("S3 broker", func() {
	const (
		serviceName  = "aws-s3-bucket"
		testPlanName = "default"
	)

	type ServiceKeyCredentials struct {
		BucketName         string `json:"bucket_name"`
		AWSAccessKeyID     string `json:"aws_access_key_id"`
		AWSSecretAccessKey string `json:"aws_secret_access_key"`
		AWSRegion          string `json:"aws_region"`
	}
	type ServiceKeyData struct {
		Credentials ServiceKeyCredentials `json:"credentials"`
	}

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-e", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring("default"))
	})

	Context("creating an S3 bucket", func() {
		var (
			serviceInstanceName string
		)

		createBucketWithCleanup := func(siName string) {
			By("creating the service: "+siName, func() {
				Expect(cf.Cf("create-service", serviceName, testPlanName, siName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceCreationCompletion(siName)
			})

			DeferCleanup(func() {
				By("deleting the service", func() {
					Expect(cf.Cf("delete-service", siName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
					pollForServiceDeletionCompletion(siName)
				})
			})
		}

		BeforeEach(func () {
			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-s3-bucket")

			createBucketWithCleanup(serviceInstanceName)
		})

		It("is accessible from the healthcheck app", func() {
			appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")

			By("pushing the healthcheck app", func() {
				Expect(cf.Cf(
					"push", appName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../example-apps/healthcheck",
					"-f", "../example-apps/healthcheck/manifest.yml",
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			defer By("deleting the app", func() {
				cf.Cf("delete", appName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("binding the service", func() {
				Expect(cf.Cf("bind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
			})

			By("starting the app", func() {
				Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			By("testing the S3 bucket access from the app", func() {
				resp, err := httpClient.Get(helpers.AppUri(appName, "/s3-test", testConfig))
				Expect(err).NotTo(HaveOccurred())
				body, err := ioutil.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			})
		})

		Context("external access", func() {
			var s3Client *s3.S3
			var bucketName string
			var serviceKeyName string

			createServiceKeyWithCleanup := func(
				siName string,
				skName string,
				allowExternalAccessJSON string,
			) {
				By("creating the service key: "+skName, func() {
					Expect(cf.Cf(
						"create-service-key",
						siName,
						skName,
						"-c",
						fmt.Sprintf(
							`{"allow_external_access": %s, "permissions": "read-write"}`,
							allowExternalAccessJSON,
						),
					).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				})

				DeferCleanup(func() {
					By("deleting the service key", func() {
						cf.Cf("delete-service-key", siName, skName, "-f").Wait(testConfig.DefaultTimeoutDuration())
					})
				})
			}

			s3ClientFromServiceKey := func(siName string, skName string) (*s3.S3, string) {
				var serviceKeyData ServiceKeyData
				cfSess := cf.Cf(
					"service-key",
					siName,
					skName,
				)
				Expect(cfSess.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

				outContents := cfSess.Out.Contents()
				err := json.Unmarshal(
					outContents[bytes.IndexByte(outContents, byte('{')):],
					&serviceKeyData,
				)
				Expect(err).ToNot(HaveOccurred())

				Expect(serviceKeyData.Credentials.BucketName).ToNot(Equal(""))
				Expect(serviceKeyData.Credentials.AWSAccessKeyID).ToNot(Equal(""))
				Expect(serviceKeyData.Credentials.AWSSecretAccessKey).ToNot(Equal(""))
				Expect(serviceKeyData.Credentials.AWSRegion).ToNot(Equal(""))

				sess := session.Must(session.NewSession(&aws.Config{
					Region:      aws.String(serviceKeyData.Credentials.AWSRegion),
					Credentials: credentials.NewStaticCredentials(
						serviceKeyData.Credentials.AWSAccessKeyID,
						serviceKeyData.Credentials.AWSSecretAccessKey,
						"",
					),
				}))
				return s3.New(sess), serviceKeyData.Credentials.BucketName
			}

			assertNoBucketAccess := func(bName string) {
				_, err := s3Client.PutObject(&s3.PutObjectInput{
					Bucket: aws.String(bName),
					Key:    aws.String("test-key"),
					Body:   strings.NewReader("test-content"),
				})
				Expect(err).To(MatchError(ContainSubstring("AccessDenied")))

				_, err = s3Client.ListObjects(&s3.ListObjectsInput{
					Bucket: aws.String(bName),
				})
				Expect(err).To(MatchError(ContainSubstring("AccessDenied")))

				_, err = s3Client.GetObject(&s3.GetObjectInput{
					Bucket: aws.String(bName),
					Key:    aws.String("test-key"),
				})
				Expect(err).To(MatchError(ContainSubstring("AccessDenied")))

				_, err = s3Client.GetObjectTagging(&s3.GetObjectTaggingInput{
					Bucket: aws.String(bName),
					Key:    aws.String("test-key"),
				})
				Expect(err).To(MatchError(ContainSubstring("AccessDenied")))

				_, err = s3Client.DeleteObject(&s3.DeleteObjectInput{
					Bucket: aws.String(bName),
					Key:    aws.String("test-key"),
				})
				Expect(err).To(MatchError(ContainSubstring("AccessDenied")))
			}

			BeforeEach(func() {
				serviceKeyName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-service-key")
			})

			Context("with a non-allow_external_access service key", func() {
				BeforeEach(func() {
					createServiceKeyWithCleanup(
						serviceInstanceName,
						serviceKeyName,
						`false`,
					)
				})

				It("is not externally accessible", func() {
					By("retrieving the service key credentials", func() {
						s3Client, bucketName = s3ClientFromServiceKey(
							serviceInstanceName,
							serviceKeyName,
						)
					})

					By("failing to access the bucket from the test host", func() {
						assertNoBucketAccess(bucketName)
					})
				})
			})

			Context("with an allow_external_access service key", func() {
				BeforeEach(func() {
					createServiceKeyWithCleanup(
						serviceInstanceName,
						serviceKeyName,
						`true`,
					)
					s3Client, bucketName = s3ClientFromServiceKey(
						serviceInstanceName,
						serviceKeyName,
					)
				})

				It("is externally accessible", func() {
					By("accessing the bucket from the test host", func() {
						_, err := s3Client.PutObject(&s3.PutObjectInput{
							Bucket: aws.String(bucketName),
							Key:    aws.String("test-key"),
							Body:   strings.NewReader("test-content"),
						})
						Expect(err).ToNot(HaveOccurred())

						defer func() {
							_, err := s3Client.DeleteObject(&s3.DeleteObjectInput{
								Bucket: aws.String(bucketName),
								Key:    aws.String("test-key"),
							})
							Expect(err).ToNot(HaveOccurred())
						}()

						listObjectsResult, err := s3Client.ListObjects(&s3.ListObjectsInput{
							Bucket: aws.String(bucketName),
						})
						Expect(err).ToNot(HaveOccurred())
						Expect(len(listObjectsResult.Contents)).To(Equal(1))
						Expect(listObjectsResult.Contents[0].Key).To(Equal(aws.String("test-key")))

						_, err = s3Client.GetObject(&s3.GetObjectInput{
							Bucket: aws.String(bucketName),
							Key:    aws.String("test-key"),
						})
						Expect(err).ToNot(HaveOccurred())

						_, err = s3Client.GetObjectTagging(&s3.GetObjectTaggingInput{
							Bucket: aws.String(bucketName),
							Key:    aws.String("test-key"),
						})
						Expect(err).ToNot(HaveOccurred())
					})
				})

				Context("and a second s3 service instance", func() {
					var serviceInstance2Name string
					var serviceKey2Name string

					BeforeEach(func() {
						serviceInstance2Name = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-s3-bucket-2")

						serviceKey2Name = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-service-key-2")

						createBucketWithCleanup(serviceInstance2Name)
						createServiceKeyWithCleanup(
							serviceInstance2Name,
							serviceKey2Name,
							`true`,
						)
					})

					It("is not able to use the first key to access the second bucket", func() {
						var bucket2Name string

						By("retrieving the other bucket name", func() {
							_, bucket2Name = s3ClientFromServiceKey(
								serviceInstance2Name,
								serviceKey2Name,
							)
						})

						By("failing to access the other bucket", func() {
							assertNoBucketAccess(bucket2Name)
						})
					})
				})
			})
		})
	})

	Context("multiple operations against a single bucket", func() {
		var (
			appOneName          string
			appTwoName          string
			serviceInstanceName string
		)

		BeforeEach(func() {
			appOneName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			appTwoName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")

			By("deploying a first app", func() {
				Expect(cf.Cf(
					"push", appOneName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../example-apps/healthcheck",
					"-f", "../example-apps/healthcheck/manifest.yml",
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			By("deploying a second app", func() {
				Expect(cf.Cf(
					"push", appTwoName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../example-apps/healthcheck",
					"-f", "../example-apps/healthcheck/manifest.yml",
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-s3-bucket")

			By("creating the service: "+serviceInstanceName, func() {
				Expect(
					cf.
						Cf("create-service", serviceName, testPlanName, serviceInstanceName).
						Wait(testConfig.DefaultTimeoutDuration()),
				).
					To(Exit(0))
				pollForServiceCreationCompletion(serviceInstanceName)
			})

			By("Waiting for AWS to be eventually consistent", func() {
				time.Sleep(10 * time.Second)
			})
		})

		AfterEach(func() {
			By("deleting the first app", func() {
				cf.Cf("delete", appOneName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("deleting the second app", func() {
				cf.Cf("delete", appTwoName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("deleting the service", func() {
				Expect(
					cf.Cf("delete-service", serviceInstanceName, "-f").
						Wait(testConfig.DefaultTimeoutDuration()),
				).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})
		})

		It("do not run in to race conditions", func() {
			By("binding the two apps simultaneously, we should see no errors", func() {
				bindAppOneChan := make(chan int)
				bindAppTwoChan := make(chan int)

				bindServiceToAppAsync(appOneName, serviceInstanceName, bindAppOneChan)
				bindServiceToAppAsync(appTwoName, serviceInstanceName, bindAppTwoChan)

				Expect(<-bindAppOneChan).To(Equal(0))
				Expect(<-bindAppTwoChan).To(Equal(0))
			})

			By("Waiting for AWS to be eventually consistent", func() {
				time.Sleep(10 * time.Second)
			})

			By("unbinding the two apps simultaneously, we should see no errors", func() {
				unbindAppOneChan := make(chan int)
				unbindAppTwoChan := make(chan int)

				unbindServiceFromAppAsync(appOneName, serviceInstanceName, unbindAppOneChan)
				unbindServiceFromAppAsync(appTwoName, serviceInstanceName, unbindAppTwoChan)

				Eventually(<-unbindAppOneChan, 60*time.Second).Should(Equal(0))
				Eventually(<-unbindAppTwoChan, 60*time.Second).Should(Equal(0))
			})
		}) // Override default timeout of 1 second for async to be one minute
	})
})

func bindServiceToAppAsync(appName string, serviceInstanceName string, outChan chan<- int) {
	go (func() {
		session := cf.Cf("bind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		exitCode := session.ExitCode()

		outChan <- exitCode
	})()
}

func unbindServiceFromAppAsync(appName string, serviceInstanceName string, outChan chan<- int) {
	go (func() {
		session := cf.Cf("unbind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		exitCode := session.ExitCode()

		outChan <- exitCode
	})()
}
