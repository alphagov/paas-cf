# paas-metrics

### Overview

Collects useful usage/platform metrics that are not currently provided by our other integrations, then reports those events somewhere useful.

### Metrics

The following metrics are currently collected:

| Name | Kind | Description | Tags |
| --- | --- | --- | --- |
|`aiven.estimated.cost` | Gauge | Estimated cost of Aiven in the current month | |
|`aws.elasticache.node.count` | Gauge | Number of Elasticache nodes | |
|`aws.elasticache.cache_parameter_group.count` | Gauge | Number of Elasticache cache parameter groups | |
|`aws.elb.healthy_node_count` | Gauge | Number of healthy ELB nodes | |
|`aws.elb.unhealthy_node_count` | Gauge | Number of unhealthy ELB nodes | |
|`aws.cloudfront.4xxerrorrate` | Gauge | The rate of 4xx in a CloudFront distribution | `distribution_id` |
|`aws.cloudfront.5xxerrorrate` | Gauge | The rate of 5xx errors in a CloudFront distribution | `distribution_id` |
|`aws.cloudfront.bytes_downloaded` | Counter | Total number of bytes downloaded from a CloudFront distribution | `distribution_id` |
|`aws.cloudfront.bytes_uploaded` | Counter | Total number of bytes uploaded to a CloudFront distribution | `distribution_id` |
|`aws.cloudfront.requests` | Counter | Total number of requests made to a CloudFront distribution | `distribution_id` |
|`aws.cloudfront.totalerrorrate` | Gauge | The total rate of 4xx and 5xx errors in a CloudFront distribution | `distribution_id` |
|`aws.s3.buckets.count` | Gauge | The total number of buckets in the AWS account | |
|`cdn.tls.certificates.expiry` | Gauge | Number of days until a CloudFront cert expires | `hostname` |
|`cdn.tls.certificates.validity` | Gauge | Number of days CloudFront cert is valid for | `hostname` |
|`op.apps.count` | Gauge | Number of applications | `state`, `trial_org` |
|`op.orgs.count` | Gauge | Number of organisations | `quota` |
|`op.events.app.crash` | Gauge | Total times an app crash event has happened | |
|`op.services.provisioned` | Gauge | Number of provisioned services | `type`, `trial_org`, `free_service` |
|`op.spaces.count` | Gauge | Number of spaces | |
|`op.quota.memory.reserved` | Gauge | Total amount of memory promised to orgs | |
|`op.quota.memory.allocated` | Gauge | Total amount of memory promised to apps | |
|`op.quota.routes.resrved` | Gauge | Total number of routes reserved | |
|`op.quota.services.reserved` | Gauge | Total number of services promised to orgs | |
|`op.quota.services.allocated` | Gauge | Total number of services assigned | |
|`op.users.count` | Gauge | Number of users<sup>[1](#f1)</sup> | |
|`tls.certificates.validity` | Gauge | Number of days cert is valid for | `hostname` |

### Deploying as a Cloud Foundry app

From this directory, push the app to Cloud Foundry...

```bash
cf push paas-metrics --no-start
```

You'll need some environment variables set (you could also add these to the manifest)...

```bash
cf set-env paas-metrics ELB_ADDRESS "https://healthcheck/"  # Address of an ELB to check
cf set-env paas-metrics CF_API_ADDRESS "ENDPOINT"           # Cloud Foundry API endpoint URL
cf set-env paas-metrics CF_CLIENT_ID "UAA_CLIENT_ID"        # UAA client with cloud_foundry.global_auditor scope
cf set-env paas-metrics CF_CLIENT_SECRET "SECRET"           # UAA client secret
cf set-env paas-metrics AWS_REGION "eu-west-1"              # AWS region your CloudFront distributions are in
cf set-env paas-metrics AWS_ACCESS_KEY_ID "access_key"      # Key for a user capable of listing CloudFront distributions
cf set-env paas-metrics AWS_SECRET_ACCESS_KEY "secret"      # Secret key for the user above
cf set-env paas-metrics LOG_LEVEL "0"                       # [OPTIONAL] set to 0 for more detailed logs
cf set-env paas-metrics DEPLOY_ENV "prod"                   # [OPTIONAL] set to tag metrics with env
cf set-env paas-metrics TLS_DOMAINS "ssl1.com,ssl2.com"     # [OPTIONAL] csv list of domains to monitor TLS certs for
```

Start the app...

```bash
cf start paas-metrics
```


### Implementing new metrics

There is a `MetricReader` / `MetricWriter` interface similar to `io.Reader` / `io.Writer`.

"gauges" are implemented as `MetricReaders` that are merged into a single stream of `Metrics` (see [main.go](main.go)).

"reporters" are implemented as `MetricWriters` (see [prometheus_reporter.go](prometheus_reporter.go)).

An example gauge that polls pointlessly for random numbers using the `NewMetricPoller` helper might look like:

```go
var RandomMetric := NewMetricPoller(10 * time.Second, func(w MetricWriter) error {
	return w.WriteMetrics([]Metric{
		{
			Kind: Gauge,
			Name: "my.random.thing",
			Time: time.Now(),
			Value: rand.Float64(100.0),
		},
	})
})

```

You could then consume it by copying the metrics to a writer using CopyMetrics:

```go
_ = CopyMetrics(reporter, RandomMetric)
```

### Debugging

If you run the app with `DEBUG=1` it will write all metrics to the stdout.

### Running tests

You can execute tests with the standard go test command from this dir:

```
make test
```

### Regenerating mocks

```
make generate-fakes
```

### Updating dependencies

dep is used for dependencies. to update the vendor dir do:

```
dep ensure
```

---

<a name="f1">1</a>: Only users that belong to organisations are counted.
