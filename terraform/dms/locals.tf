locals {

  task_settings  = file("task_settings.json")
  table_mappings = file("table_mappings.json")

  migrations = {
    for i, migration in var.dms_data : migration.name => {
      index              = i
      name               = migration.name
      source_secret_name = migration.source_secret_name
      target_secret_name = migration.target_secret_name
      instance           = migration.instance
      task               = migration.task
    }
  }

  secrets = {
    for migration in var.dms_data : migration.name => {
      source = jsondecode(data.aws_secretsmanager_secret_version.source[migration.name].secret_string)
      target = jsondecode(data.aws_secretsmanager_secret_version.target[migration.name].secret_string)
    }
  }

  // using range here which might not go along with the actual number of the subnets
  // might want to tackle this in a more elegant way. Keeping the data aws_subnets
  // as a temporary measure to keep data sane.
  subnet_names = [
    for index in range(0, 12) : "${var.env}-aws-backing-service-${index}"
  ]

  vpc_peering = {
    for i, migration in var.dms_data : migration.name => migration
    if migration.vpc_peering != null
  }
}
