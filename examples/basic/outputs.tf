output "code_server_password" {
  value       = module.code_server_aws.code_server_password
  description = "The password for the code-server instance UI."
  sensitive   = true
}
