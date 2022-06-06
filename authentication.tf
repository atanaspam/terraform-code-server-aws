resource "aws_cognito_user_pool" "pool" {
  name = "code-server-user-pool"

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true

    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "code-server-user-pool-domain"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "pool_client" {
  name                                 = "code-server-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  callback_urls                        = ["https://${local.domain_name}/oauth2/idpresponse"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit", "code"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true
}

resource "aws_cognito_user" "user" {
  user_pool_id   = aws_cognito_user_pool.pool.id
  username       = var.code_server_username
  password       = var.code_server_password != null ? var.code_server_password : random_password.code_server_password[0].result
  message_action = "SUPPRESS"
}

resource "aws_secretsmanager_secret" "code_server_password" {
  name                    = "code-server-pass"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_policy" "code_server_password_policy" {
  secret_arn = aws_secretsmanager_secret.code_server_password.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.image_builder_role.arn
        },
        Resource = aws_secretsmanager_secret.code_server_password.arn
      },
    ]
  })
}

resource "aws_secretsmanager_secret_version" "code_server_password" {
  secret_id     = aws_secretsmanager_secret.code_server_password.id
  secret_string = var.code_server_password != null ? var.code_server_password : random_password.code_server_password[0].result
}

resource "random_password" "code_server_password" {
  count   = var.code_server_password == null ? 1 : 0
  length  = 16
  special = false
}
