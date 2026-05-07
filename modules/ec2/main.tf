########################################
# AMAZON LINUX 2 AMI DATA SOURCE
########################################
# Fetches the latest Amazon Linux 2 AMI to ensure security updates.
data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

########################################
# AMI RESOLUTION LOGIC
########################################
# Uses custom AMI if provided, otherwise defaults to latest Amazon Linux 2.
locals {
  resolved_ami_id = coalesce(var.ami_id, data.aws_ssm_parameter.amazon_linux_2.value)
}

########################################
# EC2 LAUNCH TEMPLATE
########################################
# Defines instance configuration: AMI, type, networking, storage, monitoring,
# and security settings for the application tier instances.
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = local.resolved_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  update_default_version = true

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
    delete_on_termination       = true
  }

  monitoring {
    enabled = true
  }

  user_data = var.user_data_base64

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
      throughput            = 125
      iops                  = 3000
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-app"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-root-volume"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-lt"
  })
}
