locals {
  target_subnets         = var.deploy_to_private_subnets == true ? var.private_subnets : var.public_subnets
  controller_domain_name = "code-server-controller.${var.base_domain_name}"
  domain_name            = "code-server.${var.base_domain_name}"
}

data "aws_route53_zone" "this" {
  name = var.base_domain_name
}
