output "instance_dns_record" {
  value       = local.domain_name
  description = "The DNS address for the code-server instance."
}

output "code_server_password" {
  value       = var.code_server_password != null ? var.code_server_password : random_password.code_server_password[0].result
  description = "The password for the code-server instance UI."
  sensitive   = true
}

output "code_server_username" {
  value       = var.code_server_username
  description = "The username for the code-server instance UI."
}

output "code_server_controller_authentication_endpoint" {
  value       = "https://cognito-idp.${var.region}.amazonaws.com"
  description = "The endpoint used to authenticate to the code server controller API."
}

output "code_server_controller_endpoint" {
  value       = module.code_server_controller_api_gateway.apigatewayv2_api_api_endpoint
  description = "The endpoint which can be used to control wether the code-server instance should be running or not."
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.controller_pool_client.id
  description = "The client id used to authenticate to the code server controller API."
}
