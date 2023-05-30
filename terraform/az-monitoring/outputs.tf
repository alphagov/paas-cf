output "healthcheck_address_a" {
  value = var.enabled ? module.healthcheck_a[0].ip : ""
}

output "healthcheck_address_b" {
  value = var.enabled ? module.healthcheck_b[0].ip : ""
}

output "healthcheck_address_c" {
  value = var.enabled ? module.healthcheck_c[0].ip : ""
}
