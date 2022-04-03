variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}


variable "code_server_password" {
  type        = string
  description = "The password to be used by the code-server instance for authentication"
  sensitive   = true
  default     = null
}
