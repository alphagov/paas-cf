# paas-metrics

### Overview

Collects useful usage/platform metrics that are not currently provided by our other integrations, then reports those events somewhere useful (currently datadog).

### Metrics

The following metrics are currently collected:

| Name | Kind | Description | Tags |
| --- | --- | --- | --- |
|`aws.elb.unhealthy_node_count` | Gauge | Number of unhealthy ELB nodes | |
|`aws.elb.healthy_node_count` | Gauge | Number of healthy ELB nodes | |
|`op.apps.count` | Gauge | Number of applications | `state` |
|`op.services.provisioned` | Gauge | Number of provisioned services | `type` |
|`op.orgs.count` | Gauge | Number of organisations | `quota` |
|`op.spaces.count` | Gauge | Number of spaces | |
|`op.users.count` | Gauge | Number of users<sup>[1](#f1)</sup> | |
|`op.quotas.memory.reserved` | Gauge | Total amount of memory promised to orgs | |
|`op.quotas.memory.allocated` | Gauge | Total amount of memory promised to apps | |
|`op.quotas.services.reserved` | Gauge | Total number of services promised to orgs | |
|`op.quotas.services.allocated` | Gauge | Total number of services assigned | |

### Deploying as a Cloud Foundry app

From this directory, push the app to Cloud Foundry...

```bash
cf push paas-metrics --no-start
```

You'll need some environment variables set (you could also add these to the manifest)...

```bash
cf set-env paas-metrics DATADOG_API_KEY "API_KEY"           # datadog secret key
cf set-env paas-metrics DATADOG_APP_KEY "APP_KEY"           # datadog app key
cf set-env paas-metrics ELB_ADDRESS "https://healthcheck/"  # address of an ELB to check
cf set-env paas-metrics CF_API_ADDRESS "ENDPOINT"           # cloud foundry api endpoint url
cf set-env pass-metrics CF_CLIENT_ID "UAA_CLIENT_ID"        # uaa client with cloud_foundry.global_auditor scope
cf set-env paas-metrics CF_CLIENT_SECRET "SECRET"           # uaa client secret
cf set-env paas-metrics CF_SKIP_SSL_VALIDATION "true"       # [OPTIONAL] set to true if insecure
cf set-env paas-metrics LOG_LEVEL "0"                       # [OPTIONAL] set to 0 for more detailed logs
cf set-env paas-metrics DEPLOY_ENV "prod"                   # [OPTIONAL] set to tag metrics with env
```

Start the app...

```bash
cf start paas-metrics
```


### Implementing new metrics

There is a `MetricReader` / `MetricWriter` interface similar to `io.Reader` / `io.Writer`.

"gauges" are implemented as `MetricReaders` that are merged into a single stream of `Metrics` (see [main.go](main.go)).

"reporters" are implemented as `MetricWriters` (see [datadog_reporter.go](datadog_reporter.go)).

An example gauge that polls pointlessly for random numbers using the `NewMetricPoller` helper might look like:

```go
var RandomMetric := NewMetricPoller(10 * time.Second, func(w MetricWriter) error {
	return w.WriteMetrics([]Metric{
		{
			Kind: Gauge, // only "gauge" type supported by datadog unfortunatly
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

### Running tests

You can execute tests with the standard go test command from this dir:

```
go test -v
```

### Updating dependencies

dep is used for dependencies. to update the vendor dir do:

```
dep ensure
```

---

<a name="f1">1</a>: Only users that belong to organisations are counted.
