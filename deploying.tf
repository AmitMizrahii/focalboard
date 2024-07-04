locals {
  container_name = "focalboard-container"
  container_port = 8000
}


# ECR- docker images repository
resource "aws_ecr_repository" "my_repository" {
  name = "focalboard-repo"
}
