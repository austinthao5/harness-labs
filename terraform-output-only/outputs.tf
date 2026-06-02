output "environment" {
  value = local.environment
}

output "application" {
  value = local.application
}

output "tags" {
  value = local.tags
}

output "timestamp" {
  value = timestamp()
}
