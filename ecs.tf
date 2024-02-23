resource "aws_ecs_cluster" "ecs_cluster" {
  name = "sange-ecs-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "sange-docker-family"
  container_definitions = jsonencode(
    [
      {
        "name" : "sange-container",
        "image" : "654654553207.dkr.ecr.us-east-1.amazonaws.com/ecr-sandra:latest",
        "entryPoint" : ["/"],
        "essential" : true,
        "networkMode" : "awsvpc",
        "portMappings" : [
          {
            "containerPort" : var.container_port,
            "hostPort" : var.container_port,
          }
        ]
      }
    ]
  )
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskRole.arn
}

resource "aws_ecs_service" "ecs_service" {
  name                = "sange-ecs-service"
  cluster             = aws_ecs_cluster.ecs_cluster.arn
  task_definition     = aws_ecs_task_definition.task_definition.arn
  launch_type         = "FARGATE"
  desired_count       = 2

  network_configuration {
    subnets          = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "sange-container"
    container_port   = var.container_port
  }
  depends_on = [aws_lb_listener.listener]
}

resource "aws_alb" "application_load_balancer" {
  name               = "sange-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "target_group" {
  name        = "sange-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = var.container_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id                 = aws_vpc.my_vpc.id
  name                   = "sange-sg-ecs"
  description            = "Security group for ecs app"
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "ecs_alb_ingress" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  description              = "Allow inbound traffic from ALB"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group" "alb_sg" {
  vpc_id                 = aws_vpc.my_vpc.id
  name                   = "sange-sg-alb"
  description            = "Security group for alb"
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = var.container_port
  to_port           = var.container_port
  protocol          = "tcp"
  description       = "Allow http inbound traffic from internet"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "sange-app-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecsTaskRole" {
  name               = "ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}