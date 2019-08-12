UNAME := $(shell uname)

ifeq ($(UNAME),Linux)
	SED_CMD=sed -i -e
endif

ifeq ($(UNAME),Darwin)
	SED_CMD=sed -i '' -e
endif

.PHONY: test
test:
	go test -v ./...

.PHONY: generate-fakes
generate-fakes:
	go generate ./...

	# AWS fakes
	counterfeiter -o fakes/fake_elasticacheiface_client.go \
		vendor/github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface/interface.go ElastiCacheAPI

	counterfeiter -o pkg/cloudfront/fakes/fake_cloudfront_client.go \
		vendor/github.com/aws/aws-sdk-go/service/cloudfront/cloudfrontiface/interface.go CloudFrontAPI

	counterfeiter -o fakes/fake_s3_client.go \
		vendor/github.com/aws/aws-sdk-go/service/s3/s3iface/interface.go S3API

	counterfeiter -o fakes/fake_cloudwatch_client.go \
		vendor/github.com/aws/aws-sdk-go/service/cloudwatch/cloudwatchiface/interface.go CloudWatchAPI

	$(SED_CMD) "s|github.com/alphagov/paas-cf/tools/metrics/vendor/||" fakes/fake_*.go
	$(SED_CMD) "s|github.com/alphagov/paas-cf/tools/metrics/vendor/||" service_fakes/fake_*.go
