resource "aws_efs_file_system" "persistent_fs" {
  count = var.attach_persistent_storage ? 1 : 0

  creation_token = "code-server-fs"
}

resource "aws_efs_file_system_policy" "policy" {
  count = var.attach_persistent_storage ? 1 : 0

  file_system_id = aws_efs_file_system.persistent_fs[0].id

  bypass_policy_lockout_safety_check = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "CodeServerEFSPolicy"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.code_server_role.arn
        },
        Resource = aws_efs_file_system.persistent_fs[0].arn,
        Action = [
          "elasticfilesystem:*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      },
    ],
  })
}

resource "aws_security_group" "code_server_efs" {
  count = var.attach_persistent_storage ? 1 : 0

  name        = "Code Server EFS Security Group"
  description = "Allow traffic to EFS from our Code Server instance"
  vpc_id      = var.vpc_id

  ingress {
    description      = "EFS from VPC"
    from_port        = 2049
    to_port          = 2049
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

resource "aws_efs_mount_target" "alpha" {
  for_each        = var.attach_persistent_storage ? toset(local.target_subnets) : []
  file_system_id  = aws_efs_file_system.persistent_fs[0].id
  subnet_id       = each.key
  security_groups = [aws_security_group.code_server_efs[0].id]
}
