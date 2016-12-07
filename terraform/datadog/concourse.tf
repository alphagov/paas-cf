resource "datadog_monitor" "concourse-load" {
  name               = "${format("%s concourse load", var.env)}"
  type               = "query alert"
  message            = "${format("Concourse load is too high: {{value}}. Check VM health. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "Concourse load still too high: {{value}}."
  notify_no_data     = false
  query              = "${format("avg(last_5m):avg:system.load.5{bosh-job:concourse,bosh-deployment:%s} > 200", var.env)}"

  thresholds {
    warning  = "150.0"
    critical = "200.0"
  }

  require_full_window = true

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "concourse"
  }
}

resource "datadog_monitor" "continuous-smoketests" {
  name               = "${format("%s concourse continuous smoketests runtime", var.env)}"
  type               = "query alert"
  message            = "${format("Continuous smoketests too slow: {{value}} ms. Check concourse VM health. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "Continuous smoketests still too slow: {{value}} ms."
  no_data_timeframe  = "30"
  query              = "${format("max(last_1m):avg:concourse.build.finished{job:continuous-smoke-tests,bosh-deployment:%s} > 1800000", var.env)}"

  thresholds {
    warning  = "1200000.0"
    critical = "1800000.0"
  }

  require_full_window = false

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "concourse"
  }
}

resource "datadog_timeboard" "concourse-jobs" {
  title       = "${format("%s job runtime difference", var.env) }"
  description = "vs previous hour"
  read_only   = false

  graph {
    title = "Runtime changes vs hour ago"
    viz   = "change"

    request {
      q = "${format("avg:concourse.build.finished{bosh-deployment:%s} by {job}", var.env)}"
    }
  }

  graph {
    title = "CF pipeline run time"
    viz   = "timeseries"

    request {
      q = "${format("avg:concourse.pipeline_time{bosh-deployment:%s,pipeline_name:create-bosh-cloudfoundry}", var.env)}"
    }
  }

  graph {
    title = "Continuous smoke tests"
    viz   = "timeseries"

    request {
      q    = "${format("count_nonzero(avg:concourse.build.finished{build_status:failed,bosh-deployment:%s,job:continuous-smoke-tests})", var.env)}"
      type = "bars"

      style {
        palette = "warm"
      }
    }

    request {
      q    = "${format("count_nonzero(avg:concourse.build.finished{build_status:succeeded,bosh-deployment:%s,job:continuous-smoke-tests})", var.env)}"
      type = "bars"

      style {
        palette = "cool"
      }
    }
  }
}
