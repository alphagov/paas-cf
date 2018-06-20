resource "datadog_monitor" "bbs_lock_held_once" {
  name                = "${format("%s bbs lock held exactly once (%s)", var.env, element(list("upper", "lower"), count.index))}"
  type                = "query alert"
  message             = "${format("There is not exactly one bbs holding the lock. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = true

  count = 2

  query = "${
    format(
      "%s(last_5m):sum:cf.bbs.LockHeld.v1_locks_bbs_lock{deployment:%s}.fill(last, 60) %s",
      element(list("max", "min"), count.index),
      var.env,
      element(list("> 1", "< 1"), count.index)
    )}"

  thresholds {
    critical = "1" # This value must match the threshold set in the query. Otherwise datadog API would fail obscurely
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:bbs"]
}

resource "datadog_monitor" "bbs_healthy" {
  name                = "${format("%s bbs healthy", var.env)}"
  type                = "query alert"
  message             = "${format("BBS health check failed. Check BBS status immediately. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = true
  require_full_window = false

  query = "${format("min(last_1m):min:cf.bbs.Healthy{deploy_env:%s} < 1", var.env)}"

  thresholds {
    critical = "1"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:bbs"]
}
