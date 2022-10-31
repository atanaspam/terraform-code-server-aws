module "lambda_function_set_capacity" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.2"

  function_name = "code-server-set-capacity"
  description   = "Lambda responsible for scaling the code-server instance upon request"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  timeout       = 10


  source_path = [{
    path             = "${path.module}/src/code-server-set-capacity"
    pip_requirements = "${path.module}/src/code-server-set-capacity/requirements.txt"
  }]

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${module.code_server_controller_api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
    }
  }

  environment_variables = {
    ASG_NAME = module.code_server_autoscaling.autoscaling_group_name
  }

  attach_policy_statements = true
  policy_statements = {
    autoscalingModify = {
      effect    = "Allow",
      actions   = ["autoscaling:UpdateAutoScalingGroup", "autoscaling:SetDesiredCapacity"],
      resources = ["*"]
      condition = {
        stringequals_condition = {
          test     = "StringEquals"
          variable = "autoscaling:ResourceTag/Application"
          values   = ["code-server"]
        }
      }
    },
  }
}

module "lambda_function_get_capacity" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.2"

  function_name = "code-server-get-capacity"
  description   = "Lambda responsible for presenting the current code-server scaling info"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  timeout       = 5


  source_path = [{
    path = "${path.module}/src/code-server-get-capacity"
  }]

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${module.code_server_controller_api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
    }
  }

  environment_variables = {
    ASG_NAME = module.code_server_autoscaling.autoscaling_group_name
  }

  attach_policy_statements = true
  policy_statements = {
    autoscalingDescribe = {
      effect    = "Allow",
      actions   = ["autoscaling:DescribeAutoScalingGroups"],
      resources = ["*"]
    },
  }
}

module "code_server_controller_api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 2.2"

  name          = "code-server-controller"
  description   = "API Gateway that allows us to scale our code-server instance on HTTP requests"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Custom domain
  domain_name                 = local.controller_domain_name
  domain_name_certificate_arn = module.controller_acm_certificate.acm_certificate_arn

  # Access logs
  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.code_server_controller_log_group.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    "POST /scale" = {
      lambda_arn             = module.lambda_function_set_capacity.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
      authorizer_key         = "cognito"
    }

    "GET /scale" = {
      lambda_arn             = module.lambda_function_get_capacity.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 7000
      authorizer_key         = "cognito"
    }

    "$default" = {
      lambda_arn = module.lambda_function_get_capacity.lambda_function_arn
    }
  }

  authorizers = {
    "cognito" = {
      authorizer_type  = "JWT"
      identity_sources = "$request.header.Authorization"
      name             = "cognito"
      audience         = [aws_cognito_user_pool_client.pool_client.id]
      issuer           = "https://${aws_cognito_user_pool.pool.endpoint}"
    }
  }
}

module "controller_acm_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name               = local.controller_domain_name
  zone_id                   = data.aws_route53_zone.this.id
  subject_alternative_names = ["api.${local.controller_domain_name}"]
}

resource "aws_route53_record" "code_server_controller_dns_record" {
  name    = "api.${local.controller_domain_name}"
  zone_id = data.aws_route53_zone.this.id
  type    = "A"

  alias {
    name                   = module.code_server_controller_api_gateway.apigatewayv2_domain_name_target_domain_name
    zone_id                = module.code_server_controller_api_gateway.apigatewayv2_domain_name_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudwatch_log_group" "code_server_controller_log_group" {
  name              = "code-server-controller-api-gateway-logs"
  retention_in_days = 5
}
