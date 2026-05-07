########################################
# ALB NAME AND BUCKET RESOLUTION
########################################
# Determines effective bucket name for access logs.
locals {
  effective_access_logs_bucket_name = coalesce(var.access_logs_bucket_name, "${var.name_prefix}-alb-logs")
}

########################################
# APPLICATION LOAD BALANCER
########################################
# Internet-facing ALB with deletion protection and optional access logging.
# Deployed across public subnets for high availability.
resource "aws_lb" "this" {
  name                       = substr("${var.name_prefix}-alb", 0, 32)
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = var.security_group_ids
  subnets                    = var.subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = 60
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []

    content {
      bucket  = local.effective_access_logs_bucket_name
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

########################################
# ALB TARGET GROUP
########################################
# Target group for routing traffic to application instances.
# Includes health checks to ensure only healthy instances receive traffic.
resource "aws_lb_target_group" "this" {
  name                 = substr("${var.name_prefix}-tg", 0, 32)
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30
  slow_start           = 0

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    path                = var.health_check_path
    matcher             = "200-399"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tg"
  })
}

########################################
# HTTPS LISTENER
########################################
# HTTPS listener with ACM certificate for encrypted client connections.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

########################################
# HTTP REDIRECT LISTENER
########################################
# Automatically redirects HTTP traffic to HTTPS (301 permanent redirect).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
