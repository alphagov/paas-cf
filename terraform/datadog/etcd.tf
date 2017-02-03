resource "datadog_monitor" "etcd_one_leader" {
  name                = "${format("%s etcd IsLeader count is exactly one (%s)", var.env, element(list("upper", "lower"), count.index))}"
  type                = "query alert"
  message             = "There is not exactly one etcd reporting IsLeader."
  escalation_message  = "There is still not exactly one etcd reporting IsLeader."
  notify_no_data      = false
  require_full_window = true

  count = 2

  query = "${
    format(
      "%s(last_5m):sum:cf.etcd.IsLeader{deployment:%s}.fill(last, 60) %s",
      element(list("max", "min"), count.index),
      var.env,
      element(list("> 1", "< 1"), count.index)
    )}"

  thresholds {
    critical = "1"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:etcd"]
}
