resource "datadog_timeboard" "concourse-jobs" {

  title = "${format("%s job runtime difference", var.env) }"
  description = "vs previous hour"
  read_only = false

  graph {
    title = "Runtime changes vs hour ago"
    viz = "change"
    request {
       q = "${format("avg:%s_concourse.build.finished{*} by {job}", var.env)}"
    }
  }
}
