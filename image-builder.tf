data "aws_vpc" "target" {
  id = var.vpc_id
}

resource "aws_cloudwatch_log_group" "code_server_recepie_log_group" {
  name = "code-server-base-ubuntu"
  retention_in_days = 5
}

resource "aws_imagebuilder_image_pipeline" "code_server_pipeline" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.code_server_recepie.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.code_server_config.arn
  name                             = "code-server-base"
  status                           = "ENABLED"
  description                      = "'Bakes' an Ubuntu Server base image for our code server."

  schedule {
    schedule_expression                = "cron(0 3 * 4 ? *)" # Every Wednesday at 03:00
    pipeline_execution_start_condition = "EXPRESSION_MATCH_ONLY"
  }

  # Test the image after build
  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }
}

resource "aws_imagebuilder_image_recipe" "code_server_recepie" {
  # aws-cli-version-2-linux
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/aws-cli-version-2-linux/x.x.x"
  }

  # update-linux
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/update-linux/x.x.x"
  }

  # docker
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/docker-ce-ubuntu/x.x.x"
  }

  # cloudwatch
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/amazon-cloudwatch-agent-linux/x.x.x"
  }

  # simple-boot-test-linux
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/simple-boot-test-linux/x.x.x"
  }

  name         = "code-server-base-ubuntu"
  parent_image = "arn:aws:imagebuilder:${var.region}:aws:image/ubuntu-server-20-lts-x86/x.x.x"
  version      = "0.0.1"
}

resource "aws_imagebuilder_distribution_configuration" "code_server_distribution" {
  name = "local-distribution"

  distribution {
    ami_distribution_configuration {
      name = "code-server-base-ubuntu-{{imagebuilder:buildDate}}"
    }
    region = var.region
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "code_server_config" {
  description                   = "code-server infrastructure configuration"
  instance_profile_name         = aws_iam_instance_profile.code_server_image_builder_profile.name
  instance_types                = ["t3.micro"]
  name                          = "code-server-infrastructure"
  security_group_ids            = [aws_security_group.image_builder.id]
  subnet_id                     = var.private_subnets[0]
  terminate_instance_on_failure = true
}

resource "aws_iam_instance_profile" "code_server_image_builder_profile" {
  name = "CodeServerEC2ImageBuilderProfile"
  role = aws_iam_role.image_builder_role.name
}

resource "aws_iam_role" "image_builder_role" {
  name = "EC2ImageBuilderRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    data.aws_iam_policy.ssm_policy.arn,
    data.aws_iam_policy.image_builder_policy.arn,
    aws_iam_policy.image_builder_s3.arn,
  ]
}

data "aws_iam_policy" "ssm_policy" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "image_builder_policy" {
  name = "EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_policy" "image_builder_s3" {
  name        = "EC2ImageBuilderS3"
  # description = "My test policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:List",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_security_group" "image_builder" {
  name        = "EC2 Image Builder Security Group"
  description = "Allow traffic required for EC2 Image Builder AMI baking process"
  vpc_id      = var.vpc_id

  ingress {
    description      = "SSM from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.target.cidr_block]
    ipv6_cidr_blocks = []
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
