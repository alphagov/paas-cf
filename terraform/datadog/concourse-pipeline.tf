resource "datadog_timeboard" "pipeline" {
  title = "${data.null_data_source.datadog.inputs.env} - Concourse timeboard"
  description = "Concourse metrics"
  read_only = true

  graph {
    title = "Pipeline run time"
    viz = "timeseries"
    request {
      q = "avg:${data.null_data_source.datadog.inputs.env}.pipeline_time{environment:${data.null_data_source.datadog.inputs.env}}"
    }
  }
}
