locals {
  container_name = "focalboard-container"
  container_port = 8000
  secret_name    = "focalboard/config"
}


# ECR- docker images repository
resource "aws_ecr_repository" "my_repository" {
  name = "focalboard"
}


#ECS service
resource "aws_ecs_service" "focalboard-service" {
  name            = "focalboard-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.private.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  tags = merge(local.common_tags, { Name = "amit-ecs-service" })
}


resource "aws_security_group" "focalboard-lb" {
  vpc_id = aws_vpc.custom.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "focalboard-lb" {
  name               = "amit-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.focalboard-lb.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public2.id
  ]

  tags = merge(local.common_tags, { Name = "focalboard-lb" })
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.focalboard-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
resource "aws_lb_target_group" "my_target_group" {
  name        = "focalboard-tg"
  port        = local.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.custom.id
  target_type = "ip"
  health_check {
    path     = "/login"
    protocol = "HTTP"
    port     = local.container_port
  }

  tags = merge(local.common_tags, { Name = "focalboard-tg" })
}


resource "aws_security_group" "ecs_security_group" {
  vpc_id = aws_vpc.custom.id

  ingress {
    from_port       = local.container_port
    to_port         = local.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.focalboard-lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "ecs-security-group" })
}

#ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "focalboard-ecs-cluster"

  tags = merge(local.common_tags, {
    Name = "focalboard-ecs-cluster"
  })
}


resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "focalboard-app"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn


  container_definitions = jsonencode([{
    name      = local.container_name
    image     = var.image_uri
    cpu       = 256
    memory    = 512
    essential = true

    environment = [
      {
        name  = "MY_JSON_FILE_PATH"
        value = "./config.json"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/focalboard-log-group"
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
    portMappings = [{
      containerPort = local.container_port
      hostPort      = local.container_port
      protocol      = "tcp"
    }]
    secrets = [
      {
        name      = "FOCALOARD_SECRET"
        valueFrom = var.secret_arn
      }
    ]
    entryPoint = ["/bin/sh", "-c"]
    command    = ["echo $FOCALOARD_SECRET > $MY_JSON_FILE_PATH && your_app_command"]
  }])
  tags = local.common_tags
}



resource "aws_iam_role" "ecs_task_role" {
  name = "focalboard_ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_task_secrets_policy" {
  name        = "ecs_task_secrets_policy"
  description = "Policy to allow ECS tasks to access secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = var.secret_arn
      }
    ]
  })
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_secrets_policy.arn
}


# resource "aws_vpc_security_group_ingress_rule" "ecs" {
#   security_group_id = aws_security_group.ecs_security_group.id

#   referenced_security_group_id = aws_security_group.focalboard-lb.id
#   from_port                    = local.container_port
#   to_port                      = local.container_port
#   ip_protocol                  = "tcp"
# }
