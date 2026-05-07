########################################
# LOAD BALANCER SECURITY GROUP
########################################
# Edge tier security group allowing public HTTP/HTTPS access.
# ALB forwards traffic to app tier via internal security group rule.
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for the public Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP redirect entrypoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS entrypoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
    Tier = "edge"
  })
}

########################################
# APPLICATION TIER SECURITY GROUP
########################################
# Application tier allowing traffic only from ALB and SSH from approved CIDR.
# Implements principle of least privilege.
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for private application instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Application traffic from the ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
    Tier = "app"
  })
}

########################################
# CONDITIONAL SSH RULE
########################################
# Create SSH ingress only when an allowed CIDR is provided. This avoids
# opening port 22 by default when users do not supply SSH access.
resource "aws_security_group_rule" "app_ssh" {
  count             = var.ssh_allowed_cidr == null ? 0 : 1
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_allowed_cidr == null ? [] : [var.ssh_allowed_cidr]
  security_group_id = aws_security_group.app.id
  description       = "SSH from approved CIDR (conditional)"
}

########################################
# DATABASE TIER SECURITY GROUP (PLACEHOLDER)
########################################
# Reserved security group for future database workloads.
# Allows traffic from app tier on standard database ports.
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "Placeholder security group for future database workloads"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Database traffic from the application tier"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
    Tier = "database"
  })
}
