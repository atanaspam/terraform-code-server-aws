locals {
  target_subnets         = var.deploy_to_public_subnets == true ? var.public_subnets : var.private_subnets
  controller_domain_name = "code-server-controller.${var.base_domain_name}"
}

data "aws_route53_zone" "this" {
  name = var.base_domain_name
}
