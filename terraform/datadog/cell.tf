resource "datadog_monitor" "cell-available-memory" {
  name               = "${format("%s cell available memory", var.env)}"
  type               = "query alert"
  message            = "${format("Less than {{threshold}}%% memory free on cells. There is only {{value}}%% memory free on average on cells. Review if we need to scale... @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is only {{value}}% memory free on average on cells. Check the deployment!"
  no_data_timeframe  = "7"
  query              = "${format("avg(last_2h):ewma_5(avg:system.mem.pct_usable{bosh-job:cell,deploy_env:%s}) * 100 < 50", var.env)}"

  thresholds {
    warning  = "55.0"
    critical = "50.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}

resource "datadog_monitor" "cell-idle-cpu" {
  name               = "${format("%s cell idle CPU", var.env)}"
  type               = "query alert"
  message            = "${format("Less than {{threshold}}%% CPU idle on cells. There is only {{value}}%% CPU idle on average on cells. Review if we need to scale... @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is only {{value}}% CPU idle on average on cells. Check the deployment!"
  no_data_timeframe  = "7"
  query              = "${format("avg(last_2h):ewma_5(avg:system.cpu.idle{deploy_env:%s,bosh-job:cell}) < 50", var.env)}"

  thresholds {
    warning  = "55.0"
    critical = "50.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}

resource "datadog_monitor" "rep_process_running" {
  name                = "${format("%s Cell rep process running", var.env)}"
  type                = "service check"
  message             = "Cell rep process not running."
  escalation_message  = "Cell rep process still not running."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:rep').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}

resource "datadog_monitor" "rep_healthy" {
  name                = "${format("%s Cell rep healthy", var.env)}"
  type                = "service check"
  message             = "Large portion of Cell reps unhealthy. Check deployment state."
  escalation_message  = "Large portion of Cell reps still unhealthy. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('deploy_env:%s','instance:rep_service_endpoint').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}

resource "datadog_monitor" "rep-container-capacity" {
  name               = "${format("%s rep container capacity", var.env)}"
  type               = "query alert"
  message            = "${format("More than {{threshold}}%% of container capacity across reps is utilised. There is {{value}}%% of container capacity in use. Review if we need to scale... @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is {{value}}% container capacity in use. Check the deployment!"
  no_data_timeframe  = "7"
  query              = "${format("avg(last_2h):( ewma_5(sum:cf.rep.ContainerCount{deployment:%s,job:cell}) / ewma_5(sum:cf.rep.CapacityTotalContainers{deployment:%s,job:cell}) ) * 100 > 80", var.env, var.env)}"

  thresholds {
    warning  = "75.0"
    critical = "80.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}

resource "datadog_monitor" "rep-memory-capacity" {
  name               = "${format("%s rep advertised memory capacity", var.env)}"
  type               = "query alert"
  message            = "${format("Less than {{threshold}}%% of rep advertised memory capacity. There is {{value}}%% of rep advertised remaining memory capacity. Review if we need to scale... @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is only {{value}}% of rep advertised memory capacity. Check the deployment!"
  no_data_timeframe  = "7"
  query              = "${format("avg(last_2h):( ewma_5(sum:cf.rep.CapacityRemainingMemory{deployment:%s,job:cell}) / ewma_5(sum:cf.rep.CapacityTotalMemory{deployment:%s,job:cell}) ) * 100 < 33", var.env, var.env)}"

  thresholds {
    warning  = "35.0"
    critical = "33.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}

resource "datadog_monitor" "garden_process_running" {
  name                = "${format("%s Cell garden process running", var.env)}"
  type                = "service check"
  message             = "Cell garden process not running."
  escalation_message  = "Cell garden process still not running."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:guardian').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cell"]
}
