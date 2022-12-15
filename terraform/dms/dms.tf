provider "aws" {
  region = var.region
}

resource "aws_dms_endpoint" "source" {
  for_each = local.migrations

  database_name                   = try(local.secrets[each.key].source.database_name, null)
  endpoint_id                     = "${var.env}-source-${each.key}"
  endpoint_type                   = "source"
  engine_name                     = try(local.secrets[each.key].source.engine_name, "postgres")
  ssl_mode                        = "require"
  secrets_manager_arn             = try(data.aws_secretsmanager_secret.source[each.key].arn, null)
  secrets_manager_access_role_arn = data.aws_iam_role.secrets_manager.arn
  extra_connection_attributes     = try("secretsManagerEndpointOverride=${aws_vpc_endpoint.secrets_manager[0].dns_entry[0].dns_name}", null)

  tags = {
    Build       = "terraform"
    Resource    = "aws_dms_endpoint"
    Environment = var.env
    Name        = "${var.env}-source-${each.key}"
  }
}

resource "aws_dms_endpoint" "target" {
  for_each = local.migrations

  database_name                   = try(local.secrets[each.key].target.database_name, null)
  endpoint_id                     = "${var.env}-target-${each.key}"
  endpoint_type                   = "target"
  engine_name                     = try(local.secrets[each.key].target.engine_name, "postgres")
  ssl_mode                        = "require"
  secrets_manager_arn             = try(data.aws_secretsmanager_secret.target[each.key].arn, null)
  secrets_manager_access_role_arn = data.aws_iam_role.secrets_manager.arn
  extra_connection_attributes     = try("secretsManagerEndpointOverride=${aws_vpc_endpoint.secrets_manager[0].dns_entry[0].dns_name}", null)

  tags = {
    Build       = "terraform"
    Resource    = "aws_dms_endpoint"
    Environment = var.env
    Name        = "${var.env}-target-${each.key}"
  }
}

resource "aws_dms_replication_subnet_group" "default" {
  for_each = local.migrations

  replication_subnet_group_description = "DMS subnet group for ${each.key} in ${var.env}"
  replication_subnet_group_id          = "${var.env}-${each.key}"

  subnet_ids = try([aws_subnet.aws_dms_replication_zone_0[each.key].id, aws_subnet.aws_dms_replication_zone_1[each.key].id, aws_subnet.aws_dms_replication_zone_2[each.key].id], [])
  tags = {
    Build       = "terraform"
    Resource    = "aws_dms_replication_subnet_group"
    Environment = var.env
    Name        = "${var.env}-${each.key}"
  }
}

resource "aws_dms_replication_instance" "default" {
  for_each = local.migrations

  allocated_storage            = each.value.instance.allocated_storage
  allow_major_version_upgrade  = each.value.instance.allow_major_version_upgrade
  apply_immediately            = each.value.instance.apply_immediately
  auto_minor_version_upgrade   = each.value.instance.auto_minor_version_upgrade
  availability_zone            = each.value.instance.availability_zone
  engine_version               = each.value.instance.engine_version
  multi_az                     = each.value.instance.multi_az
  preferred_maintenance_window = each.value.instance.preferred_maintenance_window
  publicly_accessible          = each.value.instance.publicly_accessible
  replication_instance_class   = each.value.instance.replication_instance_class
  replication_instance_id      = "${var.env}-${each.key}"

  replication_subnet_group_id = aws_dms_replication_subnet_group.default[each.key].id
  vpc_security_group_ids      = setunion(data.aws_security_groups.rds_broker_db_clients.ids, [aws_security_group.secrets_manager_dms_access.id])

  tags = {
    Build       = "terraform"
    Resource    = "aws_dms_replication_instance"
    Environment = var.env
    Name        = "${var.env}-${each.key}"
  }
}

resource "aws_dms_replication_task" "default" {
  for_each = local.migrations

  migration_type = each.value.task.migration_type

  replication_task_settings = local.task_settings
  table_mappings            = local.table_mappings

  replication_task_id      = "${var.env}-${each.key}"
  replication_instance_arn = aws_dms_replication_instance.default[each.key].replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source[each.key].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target[each.key].endpoint_arn

  tags = {
    Build       = "terraform"
    Resource    = "aws_dms_replication_task"
    Environment = var.env
    Name        = "${var.env}-${each.key}"
  }
}
