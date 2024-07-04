locals {
  subnetIds = [aws_subnet.private.id, aws_subnet.private2.id]
}

resource "aws_efs_file_system" "focalboard" {
  creation_token = "my-efs-token"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_mount_target" "focalboard" {
  count           = length(local.subnetIds)
  file_system_id  = aws_efs_file_system.focalboard.id
  subnet_id       = element(local.subnetIds, count.index)
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name        = "efs_sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.custom.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.custom.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
