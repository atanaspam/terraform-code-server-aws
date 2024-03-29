variable "region" {
  type        = string
  description = "The AWS region to deploy the code-server instance to."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the code-server instance will be deployed."
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of private subnets to be used by the code-server instance."
  default     = []
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets to be used by the code-server instance."
}

variable "base_domain_name" {
  type        = string
  description = "The domain to be used when genrerating a URL for the code-server instance."
}

variable "deploy_to_private_subnets" {
  type        = bool
  description = "If set to true all instances will be deployed in the private subnets. When set to true VPC endpoints are required and the 'private_subnets' variable needs to be set."
  default     = false
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
  type        = bool
  description = "When set to 'true' an EFS volume will be attached to the code-server where data can be persisted accros instance restarts."
  default     = false
}

variable "start_code_server_on_deployment" {
  type        = bool
  description = "When set to 'true' the the instance will start automatically upon deployment. Otherwise a manual scale command is expected to start the server."
  default     = true
}
