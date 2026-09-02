terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  # checkov:skip=CKV_AWS_158: no customer-managed KMS key assumed by default for this dev
  # environment's operational logs; pass log_kms_key_id to encrypt with a CMK.
  kms_key_id = var.log_kms_key_id
  tags       = var.tags
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allows inbound HTTP(S) to the ${var.name} ALB"
  vpc_id      = var.vpc_id

  # checkov:skip=CKV_AWS_260: this capstone's dev environment has no ACM certificate/domain to
  # attach (see the certificate_arn variable), so port 80 is the only listener by default; set
  # certificate_arn to add a real :443 listener with an HTTP->HTTPS redirect.
  ingress {
    description = "HTTP from allowed CIDR blocks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  dynamic "ingress" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      description = "HTTPS from allowed CIDR blocks"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.alb_ingress_cidr_blocks
    }
  }

  # checkov:skip=CKV_AWS_382: an ALB needs unrestricted outbound to reach its targets across
  # AZs; the actual attack surface (inbound) is already scoped to alb_ingress_cidr_blocks above.
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group" "service" {
  name        = "${var.name}-service-sg"
  description = "Allows inbound traffic from the ${var.name} ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB on the container port"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # checkov:skip=CKV_AWS_382: tasks need outbound to pull images, write logs, and reach the
  # database/Secrets Manager; inbound is already scoped to the ALB's security group only.
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-service-sg" })
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
  # checkov:skip=CKV_AWS_150: controlled via enable_deletion_protection, defaulting false so
  # this dev environment can be cleanly `terraform destroy`ed; set true for long-lived envs.
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket_id != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket_id
      prefix  = var.name
      enabled = true
    }
  }
  # checkov:skip=CKV_AWS_91: access logging is opt-in via access_logs_bucket_id - a generic
  # module shouldn't force every caller to also stand up a dedicated log bucket.
  # checkov:skip=CKV2_AWS_28: attaching a WAF Web ACL is an app-specific decision (rule set,
  # rate limits) left to the calling environment, not assumed by this generic module.
  # checkov:skip=CKV2_AWS_20: this ALB only redirects HTTP->HTTPS once certificate_arn is set
  # (see the aws_lb_listener.http default_action below) - with no certificate there is nothing
  # secure to redirect to, which is this capstone's dev/local reality (no owned domain).

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  # checkov:skip=CKV_AWS_378: this target group is intentionally HTTP - the ALB terminates TLS
  # (see aws_lb_listener.https, enabled once certificate_arn is set) and forwards to targets
  # over the VPC-internal HTTP hop, which is the standard ALB TLS-termination pattern.
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # checkov:skip=CKV_AWS_2: no ACM certificate assumed for this capstone's local/dev
  # environment (no owned domain) - forwards directly when certificate_arn is unset.
  # checkov:skip=CKV_AWS_103: this listener is plain HTTP by design when certificate_arn is
  # unset; the HTTPS listener below (enabled once certificate_arn is set) pins TLS 1.2+ via
  # its ssl_policy.
  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  # checkov:skip=CKV_AWS_103: ssl_policy below already pins TLS 1.2+.
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image_url
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [for k, v in var.environment : { name = k, value = v }]
      secrets     = [for k, v in var.secrets : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.name
        }
      }
    }
  ])

  tags = var.tags
}

data "aws_region" "current" {}

resource "aws_ecs_service" "this" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = var.tags
}
