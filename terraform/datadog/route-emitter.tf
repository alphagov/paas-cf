resource "datadog_monitor" "route_emitter_process_running" {
  name                = "${format("%s route-emitter process running", var.env)}"
  type                = "service check"
  message             = "route-emitter process not running. Check router state."
  escalation_message  = "route-emitter rep process still not running. Check router state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('bosh-deployment:%s','process:route-emitter').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "route_emitter"
  }
}

resource "datadog_monitor" "route_emitter_healthy" {
  name                = "${format("%s route-emitter healthy", var.env)}"
  type                = "service check"
  message             = "Large portion of route-emitter unhealthy. Check deployment state."
  escalation_message  = "Large portion of route-emitter still unhealthy. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('bosh-deployment:%s','instance:route_emitter_debug_endpoint').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "route_emitter"
  }
}

resource "datadog_monitor" "route_emitter_consul_lock" {
  name                = "${format("%s route-emitter consul lock", var.env)}"
  type                = "service check"
  message             = "route-emitter consul lock not present in any VM. Check route-emitter state."
  escalation_message  = "route-emitter consul lock still not present in any VM. Check route-emitter state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('bosh-deployment:%s','instance:route_emitter_consul_lock').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 100
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "route_emitter"
  }
}

resource "datadog_monitor" "route_emitter_lock_held_once" {
  name                = "${format("%s route-emitter lock held exactly once (%s)", var.env, element(list("upper", "lower"), count.index))}"
  type                = "query alert"
  message             = "There is not exactly one route-emitter holding the lock."
  escalation_message  = "There is still not exactly one route-emitter holding the lock."
  notify_no_data      = false
  require_full_window = true

  count = 2

  query = "${
    format(
      "min(last_5m):sum:cf.route_emitter.LockHeld.v1_locks_route_emitter_lock{deployment:%s}.fill(last, 60) %s",
      var.env,
      element(list("> 1", "< 1"), count.index)
    )}"

  thresholds {
    critical = "${element(list("1", "1"), count.index)}"
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "route_emitter"
  }
}
