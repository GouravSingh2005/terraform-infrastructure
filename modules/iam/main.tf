########################################
# EC2 ASSUME ROLE POLICY
########################################
# Trust policy allowing EC2 service to assume the instance role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

########################################
# EC2 INSTANCE ROLE AND PROFILE
########################################
# Role used by EC2 instances for secure AWS API access.
# Includes SSM and CloudWatch permissions without static credentials.
resource "aws_iam_role" "ec2" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-role"
  })
}

########################################
# AWS SYSTEMS MANAGER PERMISSIONS
########################################
# Enables SSH-less access via AWS Systems Manager Session Manager.
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

########################################
# CLOUDWATCH AGENT PERMISSIONS
########################################
# Enables CloudWatch agent to push logs and metrics from instances.
resource "aws_iam_role_policy_attachment" "ec2_cw_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

########################################
# EC2 INSTANCE PROFILE
########################################
# Attaches the IAM role to EC2 instances at launch.
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-profile"
  })
}
