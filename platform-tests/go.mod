module github.com/alphagov/paas-cf/platform-tests

go 1.18

require (
	code.cloudfoundry.org/lager v2.0.0+incompatible
	github.com/alphagov/paas-cf/common-go/basic_logit_client v0.0.0-00010101000000-000000000000
	github.com/aws/aws-sdk-go v1.34.0
	github.com/cloudfoundry-community/go-cfclient v0.0.0-20220701174305-34d8f2860a20
	github.com/cloudfoundry/cf-acceptance-tests v1.9.1-0.20230622231030-594a914bd4f9
	github.com/cloudfoundry/cf-test-helpers v1.0.1-0.20220603211108-d498b915ef74
	github.com/concourse/atc v4.2.2+incompatible
	github.com/concourse/go-concourse v0.0.0-20160910211037-b260442fef03
	github.com/google/uuid v1.3.0
	github.com/hashicorp/go-retryablehttp v0.6.6
	github.com/onsi/ginkgo/v2 v2.15.0
	github.com/onsi/gomega v1.31.1
	github.com/tsenart/vegeta v6.3.0+incompatible
)

require (
	code.cloudfoundry.org/clock v1.1.0 // indirect
	code.cloudfoundry.org/credhub-cli v0.0.0-20240129140404-5d5c1a8dbf29 // indirect
	code.cloudfoundry.org/garden v0.0.0-20240129155822-be259116cd61 // indirect
	code.cloudfoundry.org/gofileutils v0.0.0-20170111115228-4d0c80011a0f // indirect
	code.cloudfoundry.org/lager/v3 v3.0.3 // indirect
	github.com/DataDog/datadog-go v4.8.3+incompatible // indirect
	github.com/Masterminds/semver v1.4.2 // indirect
	github.com/Masterminds/squirrel v1.4.0 // indirect
	github.com/Microsoft/go-winio v0.6.1 // indirect
	github.com/The-Cloud-Source/goryman v0.0.0-20150410173800-c22b6e4a7ac1 // indirect
	github.com/bmizerany/pat v0.0.0-20210406213842-e4b6760bdd6f // indirect
	github.com/cenkalti/backoff v2.2.1+incompatible // indirect
	github.com/cloudfoundry/bosh-cli v6.4.1+incompatible // indirect
	github.com/concourse/baggageclaim v1.11.0 // indirect
	github.com/concourse/flag v1.1.0 // indirect
	github.com/concourse/retryhttp v1.2.4 // indirect
	github.com/cppforlife/go-semi-semantic v0.0.0-20160921010311-576b6af77ae4 // indirect
	github.com/dgrijalva/jwt-go v3.2.0+incompatible // indirect
	github.com/fatih/color v1.16.0 // indirect
	github.com/go-logr/logr v1.4.1 // indirect
	github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572 // indirect
	github.com/gobuffalo/packr v1.30.1 // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/google/go-cmp v0.6.0 // indirect
	github.com/google/jsonapi v1.0.0 // indirect
	github.com/google/pprof v0.0.0-20240125082051-42cd04596328 // indirect
	github.com/hashicorp/errwrap v1.1.0 // indirect
	github.com/hashicorp/go-cleanhttp v0.5.2 // indirect
	github.com/hashicorp/go-hclog v0.16.2 // indirect
	github.com/hashicorp/go-multierror v1.1.1 // indirect
	github.com/hashicorp/vault/api v1.11.0 // indirect
	github.com/influxdata/influxdb v1.11.4 // indirect
	github.com/jessevdk/go-flags v1.5.0 // indirect
	github.com/jmespath/go-jmespath v0.4.0 // indirect
	github.com/kr/pretty v0.3.1 // indirect
	github.com/lib/pq v1.8.0 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/mitchellh/mapstructure v1.5.0 // indirect
	github.com/papertrail/remote_syslog2 v0.0.0-20221025131630-3efcaf211ef4 // indirect
	github.com/peterhellberg/link v1.0.0 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/prometheus/client_golang v1.18.0 // indirect
	github.com/rogpeppe/go-internal v1.10.0 // indirect
	github.com/streadway/quantile v0.0.0-20220407130108-4246515d968d // indirect
	github.com/stretchr/testify v1.8.4 // indirect
	github.com/tedsuo/ifrit v0.0.0-20230516164442-7862c310ad26 // indirect
	github.com/tedsuo/rata v1.0.1-0.20170830210128-07d200713958 // indirect
	github.com/vito/go-sse v0.0.0-20160212001227-fd69d275caac // indirect
	golang.org/x/net v0.20.0 // indirect
	golang.org/x/oauth2 v0.12.0 // indirect
	golang.org/x/sys v0.16.0 // indirect
	golang.org/x/text v0.14.0 // indirect
	golang.org/x/tools v0.17.0 // indirect
	google.golang.org/appengine v1.6.7 // indirect
	google.golang.org/protobuf v1.32.0 // indirect
	gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c // indirect
	gopkg.in/cheggaaa/pb.v1 v1.0.28 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
	k8s.io/api v0.29.1 // indirect
	k8s.io/apimachinery v0.29.1 // indirect
	k8s.io/client-go v0.29.1 // indirect
)

replace github.com/alphagov/paas-cf/common-go/basic_logit_client => ../common-go/basic_logit_client
