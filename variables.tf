variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "base_domain_name" {
  type = string
}

variable "code_server_password" {
  type        = string
  description = "The password to be used for logging in to the code-server instance "
  sensitive   = true
  default     = null
}
