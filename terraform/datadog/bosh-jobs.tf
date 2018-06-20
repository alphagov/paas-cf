resource "null_resource" "parsed_job_instances" {
  count = "${length(var.job_instances)}"

  triggers {
    job_name = "${element(split(":", element(var.job_instances, count.index)), 0)}"
    warning  = "${element(split(":", element(var.job_instances, count.index)), 1) - 1}"
    critical = "${element(split(":", element(var.job_instances, count.index)), 1) - 2}"
  }
}

resource "datadog_monitor" "job_healthy" {
  count = "${length(var.job_instances)}"

  name = "${format(
    "%s %s bosh job is healthy",
    var.env,
    element(null_resource.parsed_job_instances.*.triggers.job_name, count.index)
  )}"

  type = "metric alert"

  message = "${format(
    "%s bosh job has too many unhealthy instances @govpaas-alerting-%s@digital.cabinet-office.gov.uk",
    element(null_resource.parsed_job_instances.*.triggers.job_name, count.index), var.aws_account
  )}"

  escalation_message = "${format(
    "%s bosh job has still too many unhealthy instances",
    element(null_resource.parsed_job_instances.*.triggers.job_name, count.index)
  )}"

  no_data_timeframe   = "30"
  require_full_window = true

  query = "${format(
    "avg(last_5m):sum:bosh.healthmonitor.system.healthy{deployment:%s,job:%s} <= %s",
    var.env,
    element(null_resource.parsed_job_instances.*.triggers.job_name, count.index),
    element(null_resource.parsed_job_instances.*.triggers.critical, count.index)
  )}"

  thresholds {
    critical = "${element(null_resource.parsed_job_instances.*.triggers.critical, count.index)}"
    warning  = "${element(null_resource.parsed_job_instances.*.triggers.warning, count.index)}"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:${element(null_resource.parsed_job_instances.*.triggers.job_name, count.index)}"]
}
