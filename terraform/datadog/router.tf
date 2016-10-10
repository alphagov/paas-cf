resource "datadog_timeboard" "gorouter" {
  title = "${format("%s gorouter", var.env)}"
  description = "Monitoring GoRouter"
  read_only = true

  graph {
    title = "Total Routes"
    viz = "timeseries"
    request {
      q = "${format("avg:cf.gorouter.total_routes{deployment:%s,job:router}", var.env)}"
    }
  }

  graph {
    title = "Running GoRoutines"
    viz = "timeseries"
    request {
      q = "${format("avg:cf.MetronAgent.numGoRoutines{deployment:%s,job:router}", var.env)}"
    }
  }

  graph {
    title = "Requests vs. Responses"
    viz = "timeseries"
    request {
      q = "${format("avg:cf.gorouter.total_requests{deployment:%s,job:router}", var.env)}"
    }

    request {
      q = "${format("avg:cf.gorouter.responses{deployment:%s,job:router}", var.env)}"
    }
  }

  graph {
    title = "Last registry update"
    viz = "timeseries"
    request {
      q = "${format("avg:cf.gorouter.ms_since_last_registry_update{deployment:%s,job:router}", var.env)}"
    }
  }
}

resource "datadog_monitor" "router" {
  name = "${format("%s router hosts", var.env)}"
  type = "service check"
  message = "Missing router hosts in environment {{host.environment}}. Notify: @the-multi-cloud-paas-team@digital.cabinet-office.gov.uk"
  escalation_message = "Missing router hosts! Check VM state."
  no_data_timeframe = "2"
  query = "${format("'datadog.agent.up'.over('environment:%s','job:router').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    ok = 0
    warning = 0
    critical = 10
  }

  require_full_window = true
  tags {
    "environment" = "${var.env}"
    "job" = "router"
  }
}
