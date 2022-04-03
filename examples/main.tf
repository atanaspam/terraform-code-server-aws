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
}
