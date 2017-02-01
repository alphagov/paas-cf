resource "datadog_timeboard" "gorouter" {
  title       = "${format("%s gorouter", var.env)}"
  description = "Monitoring GoRouter"
  read_only   = true

  graph {
    title = "Total Routes"
    viz   = "timeseries"

    request {
      q = "${format("avg:cf.gorouter.total_routes{deployment:%s,job:router}", var.env)}"
    }
  }

  graph {
    title = "Running GoRoutines"
    viz   = "timeseries"

    request {
      q = "${format("avg:cf.MetronAgent.numGoRoutines{deployment:%s,job:router}", var.env)}"
    }
  }

  graph {
    title = "Requests vs. Responses"
    viz   = "timeseries"

    request {
      q = "${format("avg:cf.gorouter.total_requests{deployment:%s,job:router}", var.env)}"
    }

    request {
      q = "${format("avg:cf.gorouter.responses{deployment:%s,job:router}", var.env)}"
    }
  }

  graph {
    title = "Last registry update"
    viz   = "timeseries"

    request {
      q = "${format("avg:cf.gorouter.ms_since_last_registry_update{deployment:%s,job:router}", var.env)}"
    }
  }
}

resource "datadog_monitor" "route_update_latency" {
  name                = "${format("%s route update latency", var.env)}"
  type                = "metric alert"
  message             = "Route update latency too high, possibly serving stale routes."
  escalation_message  = "Route update latency still too high. Check the deployment."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("max(last_1m):avg:cf.gorouter.ms_since_last_registry_update{deployment:%s,job:router} by {ip} > 45000", var.env)}"

  thresholds {
    warning  = "25000.0"
    critical = "45000.0"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}

variable "datadog_monitor_total_routes_drop_enabled" {
  description = "Selector to enable/disable the named resource"

  default = 1
}

resource "datadog_monitor" "total_routes_drop" {
  name                = "${format("%s total routes difference", var.env)}"
  type                = "query alert"
  message             = "Amount of the routes has decreased considerably, check deployment status."
  escalation_message  = "Total routes still dropping quickly. Check the deployment."
  no_data_timeframe   = "7"
  require_full_window = true

  # Conditionally enable this resource based on var.aws_account.
  count = "${var.datadog_monitor_total_routes_drop_enabled}"

  query = "${format("pct_change(avg(last_1m),last_30m):avg:cf.gorouter.total_routes{deployment:%s,job:router} < -33", var.env)}"

  thresholds {
    warning  = "-20.0"
    critical = "-33.0"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}

resource "datadog_monitor" "total_routes_discrepancy" {
  name                = "${format("%s total routes discrepancy", var.env)}"
  type                = "query alert"
  message             = "Discrepancy in the amount of routes on routers. Check deployment status."
  escalation_message  = "Routers still have considerably different amount of total routes!"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("avg(last_5m):outliers(avg:cf.gorouter.total_routes{deployment:%s,job:router} by {ip}, 'dbscan', 3.0) > 0", var.env)}"

  thresholds {}

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}

resource "datadog_monitor" "gorouter_process_running" {
  name                = "${format("%s gorouter process running", var.env)}"
  type                = "service check"
  message             = "gorouter process not running. Check router state."
  escalation_message  = "gorouter process still not running. Check router state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:gorouter').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}

resource "datadog_monitor" "gorouter_healthy" {
  name                = "${format("%s gorouter healthy", var.env)}"
  type                = "service check"
  message             = "Large portion of gorouters unhealthy. Check deployment state."
  escalation_message  = "Large portion of gorouters still unhealthy. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('deploy_env:%s','instance:gorouter','url:http://localhost:80/').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}
