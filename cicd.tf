########################################
# CI/CD LOCAL VARIABLES AND CONFIGURATION
########################################
# Jenkins pipeline artifact bucket configuration.
# Environment variables are now managed through Jenkins credentials.
locals {
  pipeline_artifacts_bucket_name = "${local.name_prefix}-pipeline-artifacts"
}

########################################
# IAM ASSUME ROLE POLICIES
########################################
# Trust policy allowing Jenkins to assume this role.
# Jenkins can be configured to assume this role for cross-account access or
# for temporary credentials with specific permissions.
data "aws_iam_policy_document" "jenkins_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

########################################
# IAM PERMISSIONS POLICIES
########################################
# Least-privilege policy for Jenkins to deploy infrastructure.
# Includes permissions for Terraform state management and infrastructure provisioning.
data "aws_iam_policy_document" "jenkins_policy" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "StateAndArtifactsS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::${local.tf_state_bucket_name}",
      "arn:aws:s3:::${local.tf_state_bucket_name}/*",
      "arn:aws:s3:::${local.pipeline_artifacts_bucket_name}",
      "arn:aws:s3:::${local.pipeline_artifacts_bucket_name}/*"
    ]
  }

  statement {
    sid    = "StateLockTable"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:Scan"
    ]
    resources = ["arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.tf_lock_table_name}"]
  }

  statement {
    sid    = "TerraformManagedInfrastructure"
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "logs:*",
      "ssm:*",
      "s3:*",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListRoleTags",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "AssumeDeploymentRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.jenkins[0].name}"]
  }
}

########################################
# PIPELINE ARTIFACT STORAGE
########################################
# S3 bucket for CodePipeline artifacts with versioning, encryption,
# and public access blocking for security.
resource "aws_s3_bucket" "pipeline_artifacts" {
  count  = local.pipeline_enabled ? 1 : 0
  bucket = local.pipeline_artifacts_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  count  = local.pipeline_enabled ? 1 : 0
  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  count  = local.pipeline_enabled ? 1 : 0
  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  count  = local.pipeline_enabled ? 1 : 0
  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# IAM ROLES AND POLICIES
########################################
# IAM role for Jenkins with permissions to deploy infrastructure
resource "aws_iam_role" "jenkins" {
  count              = local.pipeline_enabled ? 1 : 0
  name               = "${local.name_prefix}-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "jenkins" {
  count  = local.pipeline_enabled ? 1 : 0
  name   = "${local.name_prefix}-jenkins-policy"
  role   = aws_iam_role.jenkins[0].id
  policy = data.aws_iam_policy_document.jenkins_policy.json
}

# Instance profile for Jenkins EC2 instance
resource "aws_iam_instance_profile" "jenkins" {
  count = local.pipeline_enabled ? 1 : 0
  name  = "${local.name_prefix}-jenkins-profile"
  role  = aws_iam_role.jenkins[0].name

  tags = local.common_tags
}

########################################
# CODEBUILD PROJECTS - DEPRECATED
########################################
# CodeBuild projects have been replaced with Jenkins pipeline.
# Jenkins now handles: build (terraform fmt and init), test (terraform validate and plan), deploy (terraform apply)
# See Jenkinsfile for pipeline stages and configuration.

########################################
# CODEPIPELINE ORCHESTRATION - DEPRECATED
########################################
# AWS CodePipeline has been replaced with Jenkins pipeline.
# Jenkins orchestrates the following workflow:
# 1. SOURCE: Checkout from GitHub (configured via Jenkins webhook/polling)
# 2. BUILD: Terraform fmt and init
# 3. TEST: Terraform validate and plan
# 4. APPROVAL: Manual approval gate
# 5. DEPLOY: Terraform apply
#
# See Jenkinsfile for complete pipeline definition.
# 
# Jenkins Configuration:
# - Install required plugins: Pipeline, GitHub, AWS (or use AWS credentials)
# - Create Jenkins credentials for all TF_VAR_* variables
# - Configure webhook on GitHub repository for automatic triggers
# - Or use polling for periodic checks
