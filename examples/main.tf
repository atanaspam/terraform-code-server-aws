terraform {
  backend "s3" {}
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Application = "code-server"
    }
  }
}

locals {
  region = "eu-central-1"
  target_subnets = var.deploy_to_public_subnets == true ? var.public_subnets : var.private_subnets
}
