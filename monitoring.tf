resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/focalboard-log-group"
  retention_in_days = 7

  tags = local.common_tags
}
