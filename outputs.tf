output "instance_dns_record" {
  value       = local.domain_name
  description = "The DNS address for the code-server instance."
}

output "code_server_password" {
  value       = var.code_server_password != null ? var.code_server_password : random_password.code_server_password[0].result
  description = "The password for the code-server instance UI."
}
