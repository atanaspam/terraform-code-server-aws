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

variable "code_server_username" {
  type        = string
  description = "The username to be used for logging in to the code-server instance."
  default     = "code-server"
}

variable "code_server_password" {
  type        = string
  description = "The password to be used for logging in to the code-server instance."
  sensitive   = true
  default     = null
}

variable "path_to_settings_json" {
  type        = string
  description = "The path to a settings.json file to be used for vs code settings."
  default     = null
}

variable "attach_persistent_storage" {
  type = bool
  description = "When set to 'true' an EFS volume will be attached to the code-server where data can be persisted accros instance restarts."
  default = false
}
