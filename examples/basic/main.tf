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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "code-server-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6 = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  vpc_tags = {
    Name = "code-server-vpc"
  }
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_tls.id]
  subnet_ids         = module.vpc.private_subnets

  endpoints = {
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
    },

    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
    },

    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
    },

    imagebuilder = {
      service             = "imagebuilder"
      private_dns_enabled = true
    },

    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    },
  }
}

resource "aws_security_group" "vpc_tls" {
  name_prefix = "ssm-vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "random_string" "random_dns_name" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_route53_zone" "code_server_zone" {
  name = "${random_string.random_dns_name.result}.net"
}

################################################################################
# code-server-aws Module
################################################################################

module "code_server_aws" {
  source = "../../"

  region                    = local.region
  vpc_id                    = module.vpc.vpc_id
  private_subnets           = module.vpc.private_subnets
  public_subnets            = module.vpc.public_subnets
<<<<<<< HEAD
  base_domain_name          = aws_route53_zone.code_server_zone.name
=======
  base_domain_name          = "maturite.net"
>>>>>>> 47301d5 (ci: Introduce GitHub Actions Pipelines and commit hooks. (#1))
  path_to_settings_json     = "example_settings.json"
  attach_persistent_storage = true
}
