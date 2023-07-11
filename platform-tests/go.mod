module github.com/alphagov/paas-cf/platform-tests

go 1.18

require (
	code.cloudfoundry.org/lager v2.0.0+incompatible
	github.com/alphagov/paas-cf/common-go/basic_logit_client v0.0.0-00010101000000-000000000000
	github.com/aws/aws-sdk-go v1.44.299
	github.com/cloudfoundry-community/go-cfclient v0.0.0-20220701174305-34d8f2860a20
	github.com/cloudfoundry/cf-acceptance-tests v1.9.1-0.20230622231030-594a914bd4f9
	github.com/cloudfoundry/cf-test-helpers v1.0.1-0.20220603211108-d498b915ef74
	github.com/concourse/atc v0.0.0-20160908214930-406261dbd768
	github.com/concourse/go-concourse v0.0.0-20160910211037-b260442fef03
	github.com/google/uuid v1.1.1
	github.com/hashicorp/go-retryablehttp v0.5.2
	github.com/onsi/ginkgo/v2 v2.11.0
	github.com/onsi/gomega v1.27.8
	github.com/tsenart/vegeta v6.3.0+incompatible
)

require (
	code.cloudfoundry.org/gofileutils v0.0.0-20170111115228-4d0c80011a0f // indirect
	github.com/Masterminds/semver v1.4.2 // indirect
	github.com/Masterminds/squirrel v1.4.0 // indirect
	github.com/bmizerany/pat v0.0.0-20160217103242-c068ca2f0aac // indirect
	github.com/go-logr/logr v1.2.4 // indirect
	github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572 // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/google/go-cmp v0.5.9 // indirect
	github.com/google/pprof v0.0.0-20210407192527-94a9f03dee38 // indirect
	github.com/hashicorp/errwrap v0.0.0-20141028054710-7554cd9344ce // indirect
	github.com/hashicorp/go-cleanhttp v0.5.0 // indirect
	github.com/hashicorp/go-multierror v0.0.0-20160811015721-8c5f0ad93604 // indirect
	github.com/jackc/pgx v3.6.2+incompatible // indirect
	github.com/jmespath/go-jmespath v0.4.0 // indirect
	github.com/lib/pq v1.8.0 // indirect
	github.com/mitchellh/mapstructure v0.0.0-20150717051158-281073eb9eb0 // indirect
	github.com/peterhellberg/link v1.0.0 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/streadway/quantile v0.0.0-20220407130108-4246515d968d // indirect
	github.com/tedsuo/rata v0.0.0-20150202174335-b15ebd8bd97a // indirect
	github.com/vito/go-sse v0.0.0-20160212001227-fd69d275caac // indirect
	golang.org/x/net v0.10.0 // indirect
	golang.org/x/oauth2 v0.0.0-20190130055435-99b60b757ec1 // indirect
	golang.org/x/sys v0.9.0 // indirect
	golang.org/x/text v0.10.0 // indirect
	golang.org/x/tools v0.9.3 // indirect
	google.golang.org/appengine v1.4.0 // indirect
	google.golang.org/protobuf v1.30.0 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/alphagov/paas-cf/common-go/basic_logit_client => ../common-go/basic_logit_client
