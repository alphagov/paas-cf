resource "datadog_monitor" "concourse-load" {
  name           = "${format("%s concourse load", var.env)}"
  type           = "query alert"
  message        = "${format("Concourse load is too high: {{value}}. Check VM health. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data = false
  query          = "${format("max(last_1m):max:system.load.1{bosh-job:concourse,deploy_env:%s} > 200", var.env)}"

  thresholds {
    warning  = "150.0"
    critical = "200.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:concourse"]
}

resource "datadog_monitor" "continuous-smoketests" {
  name              = "${format("%s concourse continuous smoketests runtime", var.env)}"
  type              = "query alert"
  message           = "${format("Continuous smoketests too slow: {{value}} ms. Check concourse VM health. {{#is_alert}}%s{{/is_alert}} {{#is_warning}}%s{{/is_warning}} {{#is_no_data}}The continuous smoke tests have not reported any metrics for a while. Check concourse status. %s{{/is_no_data}} @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_notification_24x7, var.datadog_notification_in_hours, var.datadog_notification_24x7, var.aws_account)}"
  no_data_timeframe = "20"
  query             = "${format("max(last_1m):avg:concourse.build.finished{job:continuous-smoke-tests,deploy_env:%s} > 1200000", var.env)}"

  thresholds {
    warning  = "720000.0"
    critical = "1200000.0"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:concourse"]
}

resource "datadog_monitor" "continuous-smoketests-failures" {
  name  = "${format("%s concourse continuous smoketests failures", var.env)}"
  type  = "query alert"
  query = "${format("sum(last_15m):count_nonzero(max:concourse.build.finished{build_status:failed,deploy_env:%s,job:continuous-smoke-tests}) >= 3", var.env)}"

  message = "${format("{{#is_alert}}The `continuous-smoke-tests` have been failing for a while now. We need to investigate. Notify: %s{{/is_alert}} @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_notification_24x7, var.aws_account)}"

  require_full_window = false
  notify_no_data      = false

  thresholds {
    critical = "3"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "check-certificates-failures" {
  name  = "${format("%s concourse check certificates failures", var.env)}"
  type  = "query alert"
  query = "${format("sum(last_1d):count_nonzero(max:concourse.build.finished{build_status:failed,deploy_env:%s,job:check-certificates}) >= 1", var.env)}"

  message = "${format("{{#is_alert}}Some of the Cloud Foundry certificates might be expiring soon. Check the health/check-certificates job on Concourse.\n\nVisit the [Team Manual > Responding to alerts > Cloud Foundry internal certificates](%s#cloud-foundry-internal-certificates) for more info.{{/is_alert}} @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"

  require_full_window = false
  notify_no_data      = true
  no_data_timeframe   = 2880

  thresholds {
    critical = "1"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_timeboard" "concourse-jobs" {
  title       = "${format("%s job runtime difference", var.env) }"
  description = "vs previous hour"
  read_only   = false

  graph {
    title = "Runtime changes vs hour ago"
    viz   = "change"

    request {
      q = "${format("avg:concourse.build.finished{deploy_env:%s} by {job}", var.env)}"
    }
  }

  graph {
    title = "CF pipeline run time"
    viz   = "timeseries"

    request {
      q = "${format("avg:concourse.pipeline_time{deploy_env:%s,pipeline_name:create-cloudfoundry}", var.env)}"
    }
  }

  graph {
    title = "Continuous smoke tests"
    viz   = "timeseries"

    request {
      q    = "${format("count_nonzero(avg:concourse.build.finished{build_status:failed,deploy_env:%s,job:continuous-smoke-tests})", var.env)}"
      type = "bars"

      style {
        palette = "warm"
      }
    }

    request {
      q    = "${format("count_nonzero(avg:concourse.build.finished{build_status:succeeded,deploy_env:%s,job:continuous-smoke-tests})", var.env)}"
      type = "bars"

      style {
        palette = "cool"
      }
    }
  }
}
