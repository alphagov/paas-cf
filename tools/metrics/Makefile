UNAME := $(shell uname)

ifeq ($(UNAME),Linux)
	SED_CMD=sed -i -e
endif

ifeq ($(UNAME),Darwin)
	SED_CMD=sed -i '' -e
endif

.PHONY: acceptance-tests
acceptance-tests:
	go run github.com/onsi/ginkgo/v2/ginkgo acceptance

.PHONY: pkg-tests
# This looks broken. i can't see how this ever ran. should we remove it?
# (`. "github.com/onsi/ginkgo/v2"` is missing???)
pkg-tests:
	go run github.com/onsi/ginkgo/v2/ginkgo -r pkg

.PHONY: main-tests
main-tests:
	go run github.com/onsi/ginkgo/v2/ginkgo

.PHONY: test
test: main-tests pkg-tests

.PHONY: generate-fakes
generate-fakes:
	go generate ./...

	counterfeiter -o pkg/cloudfoundry/fakes/fake_cf_client.go \
		vendor/github.com/cloudfoundry-community/go-cfclient/client_interface.go \
		CloudFoundryClient

	counterfeiter -o pkg/cloudfront/fakes/fake_cloudfront_client.go \
		vendor/github.com/aws/aws-sdk-go/service/cloudfront/cloudfrontiface/interface.go \
		CloudFrontAPI

	counterfeiter -o pkg/cloudwatch/fakes/fake_cloudwatch_client.go \
		vendor/github.com/aws/aws-sdk-go/service/cloudwatch/cloudwatchiface/interface.go \
		CloudWatchAPI

	counterfeiter -o pkg/elasticache/fakes/fake_elasticacheiface_client.go \
		vendor/github.com/aws/aws-sdk-go/service/elasticache/elasticacheiface/interface.go \
		ElastiCacheAPI

	counterfeiter -o pkg/rds/fakes/fake_rds_client.go \
		vendor/github.com/aws/aws-sdk-go/service/rds/rdsiface/interface.go \
		RDSAPI

	counterfeiter -o pkg/s3/fakes/fake_s3_client.go \
		vendor/github.com/aws/aws-sdk-go/service/s3/s3iface/interface.go \
		S3API

	counterfeiter -o pkg/servicequotas/fakes/fake_servicequotas_client.go \
		vendor/github.com/aws/aws-sdk-go/service/servicequotas/servicequotasiface/interface.go \
		ServiceQuotasAPI

	counterfeiter -o pkg/health/fakes/fake_health_client.go \
		vendor/github.com/aws/aws-sdk-go/service/health/healthiface/interface.go \
		HealthAPI

	counterfeiter -o pkg/health/fakes/fake_health_service.go \
		pkg/health/types.go \
		HealthServiceInterface

	counterfeiter -o pkg/shield/fakes/fake_shield_client.go \
		vendor/github.com/aws/aws-sdk-go/service/shield/shieldiface/interface.go \
		ShieldAPI

	counterfeiter -o pkg/shield/fakes/fake_shield_service.go \
		pkg/shield/types.go \
		ShieldServiceInterface

	find pkg -name 'fake*.go' | xargs $(SED_CMD) "s|github.com/alphagov/paas-cf/tools/metrics/vendor/||"

.PHONY: run
run:
	go run .
