resource "datadog_timeboard" "concourse-jobs" {
  title = "${data.null_data_source.datadog.inputs.env} job runtime difference"
  description = "vs previous hour"
  read_only = false

  graph {
    title = "Runtime changes vs hour ago"
    viz = "change"
    request {
       q = "avg:${data.null_data_source.datadog.inputs.env}_concourse.build.finished{*} by {job}"
    }
  }
}
