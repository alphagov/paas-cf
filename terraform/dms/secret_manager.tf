data "aws_iam_role" "secrets_manager" {
  name = var.dms_secrets_manager_role_name
}

data "aws_secretsmanager_secret" "source" {
  for_each = local.migrations

  name = each.value.source_secret_name
}

data "aws_secretsmanager_secret_version" "source" {
  for_each = data.aws_secretsmanager_secret.source

  secret_id = each.value.id
}

data "aws_secretsmanager_secret" "target" {
  for_each = local.migrations

  name = each.value.target_secret_name
}

data "aws_secretsmanager_secret_version" "target" {
  for_each = data.aws_secretsmanager_secret.target

  secret_id = each.value.id
}
