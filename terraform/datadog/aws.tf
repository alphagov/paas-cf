resource "datadog_monitor" "ec2-cpu-credits" {
  name           = "${format("%s EC2 CPU credits", var.env)}"
  type           = "query alert"
  message        = "${format("Instance is {{#is_warning}}low on{{/is_warning}}{{#is_alert}}out of{{/is_alert}} CPU credits and may perform badly. See: %s#cpu-credits @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = false
  query          = "${format("avg(last_30m):avg:aws.ec2.cpucredit_balance{deploy_env:%s} by {bosh-job,bosh-index} <= 1", var.env)}"

  thresholds {
    warning  = "20"
    critical = "1"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "rds-cpu-credits" {
  name           = "${format("%s RDS CPU credits", var.env)}"
  type           = "query alert"
  message        = "${format("Instance is {{#is_warning}}low on{{/is_warning}}{{#is_alert}}out of{{/is_alert}} CPU credits and may perform badly. See: %s#cpu-credits @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = false
  query          = "${format("avg(last_30m):avg:aws.rds.cpucredit_balance{deploy_env:%s,!created_by:aws_rds_service_broker} by {dbinstanceidentifier} <= 1", var.env)}"

  thresholds {
    warning  = "20"
    critical = "1"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "rds-disk-utilisation" {
  name           = "${format("%s RDS Disk utilisation", var.env)}"
  type           = "query alert"
  message        = "${format("Instance is {{#is_warning}}low on{{/is_warning}}{{#is_alert}}critically low on{{/is_alert}} storage space. See: %s#rds-disk-utilisation @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = false
  query          = "${format("min(last_1h):min:aws.rds.free_storage_space{aws_account:%s} by {hostname} / min:aws.rds.total_storage_space{aws_account:%s} by {hostname} <= 0.1", var.aws_account, var.aws_account)}"

  thresholds {
    warning  = "0.2"
    critical = "0.1"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "rds-failure" {
  name           = "${format("%s RDS Failure", var.env)}"
  type           = "event alert"
  message        = "${format("Instance has failed. See: %s#rds-failure @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = false
  query          = "${format("events('sources:rds priority:all tags:aws_account:%s,event_type:failure').by('hostname').rollup('count').last('5m') > 0", var.aws_account)}"

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "ec2-cpu-utilisation" {
  name                = "${format("%s EC2 high CPU utilisation", var.env)}"
  type                = "metric alert"
  query               = "${format("avg(last_1h):avg:aws.ec2.cpuutilization{deploy_env:%s,!bosh-job:diego-cell} by {bosh-job,bosh-index} > 90", var.env)}"
  message             = "${format("{{bosh-job.name}}/{{bosh-index.name}} CPU utilisation has been over {{#is_warning}}{{warn_threshold}}{{/is_warning}}{{#is_alert}}{{threshold}}{{/is_alert}}%% for 1h @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = false

  thresholds {
    critical = "90"
    warning  = "70"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "elasticache-node-limit" {
  name                = "${format("%s Number of elasticache nodes is close to the limit", var.env)}"
  type                = "metric alert"
  query               = "${format("avg(last_1h):avg:aws.elasticache.node.count{deploy_env:%s} > %d", var.env, (var.aws_limits_elasticache_nodes * 90) / 100)}"
  message             = "${format("Number of elasticache nodes has been over {{#is_warning}}{{warn_threshold}}{{/is_warning}}{{#is_alert}}{{threshold}}{{/is_alert}}%% for 1h @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = false

  thresholds {
    critical = "${(var.aws_limits_elasticache_nodes * 90) / 100}"
    warning  = "${(var.aws_limits_elasticache_nodes * 80) / 100}"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "elasticache-cache-parameter-groups-limit" {
  name                = "${format("%s Number of elasticache cache parameter groups is close to the limit", var.env)}"
  type                = "metric alert"
  query               = "${format("avg(last_1h):avg:aws.elasticache.cache_parameter_group.count{deploy_env:%s} > %d", var.env, (var.aws_limits_elasticache_cache_parameter_groups * 90) / 100)}"
  message             = "${format("Number of elasticache cache parameter groups has been over {{#is_warning}}{{warn_threshold}}{{/is_warning}}{{#is_alert}}{{threshold}}{{/is_alert}}%% for 1h @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = false

  thresholds {
    critical = "${(var.aws_limits_elasticache_cache_parameter_groups * 90) / 100}"
    warning  = "${(var.aws_limits_elasticache_cache_parameter_groups * 80) / 100}"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}
