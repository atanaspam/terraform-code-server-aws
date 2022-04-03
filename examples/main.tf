terraform {
  backend "s3" {}
}

provider "aws" {
  region = local.region
}

locals {
  region = "eu-central-1"
}
