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
  message             = "${format("Route update latency too high, possibly serving stale routes. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
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
  message             = "${format("Amount of the routes has decreased considerably, check deployment status. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
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
  message             = "${format("Discrepancy in the amount of routes on routers. Check deployment status. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("avg(last_5m):outliers(avg:cf.gorouter.total_routes{deployment:%s,job:router} by {ip}, 'scaledDBSCAN', 3.0) > 0", var.env)}"

  thresholds {}

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}

resource "datadog_monitor" "gorouter_process_running" {
  name                = "${format("%s gorouter process running", var.env)}"
  type                = "service check"
  message             = "${format("gorouter process not running. Check router state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
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
  message             = "${format("Large portion of gorouters unhealthy. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('deploy_env:%s','instance:gorouter','url:http://localhost:80/').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 55
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}

resource "datadog_monitor" "gorouter_latency" {
  name                = "${format("%s gorouter latency", var.env)}"
  type                = "metric alert"
  message             = "${format("Gorouter latency too high. See: %s#Gorouter-high-latency-alerts @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("avg(last_10m):avg:cf.gorouter.latency{deployment:%s,job:router} by {ip} > 1500", var.env)}"

  thresholds {
    warning  = "750.0"
    critical = "1500.0"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:router"]
}
