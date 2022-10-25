data "aws_ami" "code_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["code-server-base-ubuntu*"]
  }

  depends_on = [aws_imagebuilder_image.code_server_image]
}

resource "aws_iam_instance_profile" "code_server_profile" {
  name = "CodeServerProfile"
  role = aws_iam_role.code_server_role.name
}

resource "aws_iam_role" "code_server_role" {
  name = "CodeServerRole"
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
  ]
}

resource "aws_security_group" "code_server" {
  name        = "Code Server Security Group"
  description = "Allow traffic required for our Code Server instance"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.target.cidr_block]
    ipv6_cidr_blocks = []
  }

  ingress {
    description      = "EFS from VPC"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.target.cidr_block]
    ipv6_cidr_blocks = []
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 8080
    to_port          = 8080
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

resource "aws_launch_template" "code_server" {
  name = "code-server"

  block_device_mappings {
    device_name = "/dev/sdb"

    ebs {
      volume_size           = 25
      volume_type           = "gp3"
      delete_on_termination = true
      # encrypted             = true
      # kms_key_id            = aws_kms_key.jumphost_key.arn
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.code_server_profile.arn
  }

  image_id                             = data.aws_ami.code_server.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t3.micro"
  vpc_security_group_ids               = [aws_security_group.code_server.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Component = "code-server Instance"
    }
  }
}

module "code_server_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.0"

  #TODO Can we stop using a dedicated aws_launch_template resource and use the one created by this module?

  # Autoscaling group
  name              = "code-server-asg"
  target_group_arns = [module.alb.target_group_arns[0]]

  vpc_zone_identifier = local.target_subnets
  min_size            = 0
  max_size            = 1
  desired_capacity    = 1

  # Launch template
  create_launch_template  = false
  launch_template         = aws_launch_template.code_server.name
  launch_template_version = "$Latest"
  update_default_version  = true

  tags = {
    Component = "code-server ASG"
  }
}
