########################################
# CI/CD LOCAL VARIABLES AND CONFIGURATION
########################################
# Pipeline and CodeBuild environment setup including artifact bucket names
# and Terraform variables passed to CodeBuild containers.
locals {
  pipeline_artifacts_bucket_name = "${local.name_prefix}-pipeline-artifacts"
  codebuild_environment_variables = {
    TF_IN_AUTOMATION                   = "true"
    TF_INPUT                           = "false"
    TF_STATE_BUCKET                    = local.tf_state_bucket_name
    TF_STATE_KEY                       = local.tf_state_key
    TF_STATE_REGION                    = var.region
    TF_LOCK_TABLE                      = local.tf_lock_table_name
    TF_VAR_region                      = var.region
    TF_VAR_environment                 = var.environment
    TF_VAR_project_name                = var.project_name
    TF_VAR_owner                       = var.owner
    TF_VAR_vpc_cidr                    = var.vpc_cidr
    TF_VAR_public_subnet_cidrs         = jsonencode(var.public_subnet_cidrs)
    TF_VAR_private_app_subnet_cidrs    = jsonencode(var.private_app_subnet_cidrs)
    TF_VAR_private_db_subnet_cidrs     = jsonencode(var.private_db_subnet_cidrs)
    TF_VAR_instance_type               = var.instance_type
    TF_VAR_desired_capacity            = tostring(var.desired_capacity)
    TF_VAR_min_capacity                = tostring(var.min_capacity)
    TF_VAR_max_capacity                = tostring(var.max_capacity)
    TF_VAR_ssh_allowed_cidr            = var.ssh_allowed_cidr
    TF_VAR_domain_name                 = var.domain_name
    TF_VAR_subdomain                   = var.subdomain
    TF_VAR_acm_certificate_arn         = var.acm_certificate_arn
    TF_VAR_key_name                    = var.key_name
    TF_VAR_app_port                    = tostring(var.app_port)
    TF_VAR_root_volume_size            = tostring(var.root_volume_size)
    TF_VAR_enable_deletion_protection  = tostring(var.enable_deletion_protection)
    TF_VAR_enable_alb_access_logs      = tostring(var.enable_alb_access_logs)
    TF_VAR_alb_access_logs_bucket_name = var.alb_access_logs_bucket_name
    TF_VAR_tf_state_bucket_name        = var.tf_state_bucket_name
    TF_VAR_tf_lock_table_name          = var.tf_lock_table_name
    TF_VAR_codestar_connection_arn     = var.codestar_connection_arn
    TF_VAR_github_owner                = local.github_owner
    TF_VAR_github_repo                 = local.github_repo
    TF_VAR_github_branch               = var.github_branch
    TF_VAR_monitoring_alarm_actions    = jsonencode(var.monitoring_alarm_actions)
  }
  codebuild_environment_variables_filtered = {
    for key, value in local.codebuild_environment_variables : key => value if value != null
  }
}

########################################
# IAM ASSUME ROLE POLICIES
########################################
# Trust policies allowing CodeBuild and CodePipeline services to assume roles.
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

########################################
# IAM PERMISSIONS POLICIES
########################################
# Least-privilege policies for CodeBuild (infrastructure access) and
# CodePipeline (orchestration and GitHub integration).
data "aws_iam_policy_document" "codebuild_policy" {
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
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    sid    = "ArtifactBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.pipeline_artifacts_bucket_name}",
      "arn:aws:s3:::${local.pipeline_artifacts_bucket_name}/*"
    ]
  }

  statement {
    sid    = "CodeBuildExecution"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:StopBuild"
    ]
    resources = local.pipeline_enabled ? [
      aws_codebuild_project.build[0].arn,
      aws_codebuild_project.test[0].arn,
      aws_codebuild_project.deploy[0].arn
    ] : []
  }

  statement {
    sid       = "GitHubConnection"
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = local.pipeline_enabled ? [var.codestar_connection_arn] : []
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
# IAM roles for CodeBuild and CodePipeline with attached policies
# providing necessary permissions for infrastructure automation.
resource "aws_iam_role" "codebuild" {
  count              = local.pipeline_enabled ? 1 : 0
  name               = "${local.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "codebuild" {
  count  = local.pipeline_enabled ? 1 : 0
  name   = "${local.name_prefix}-codebuild-policy"
  role   = aws_iam_role.codebuild[0].id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_role" "codepipeline" {
  count              = local.pipeline_enabled ? 1 : 0
  name               = "${local.name_prefix}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "codepipeline" {
  count  = local.pipeline_enabled ? 1 : 0
  name   = "${local.name_prefix}-codepipeline-policy"
  role   = aws_iam_role.codepipeline[0].id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

########################################
# CODEBUILD PROJECTS
########################################
# Three CodeBuild projects for Terraform workflow:
# - build: terraform fmt and init
# - test: terraform validate and plan
# - deploy: terraform apply
resource "aws_codebuild_project" "build" {
  count         = local.pipeline_enabled ? 1 : 0
  name          = "${local.name_prefix}-build"
  description   = "Terraform formatting and backend initialization"
  service_role  = aws_iam_role.codebuild[0].arn
  build_timeout = 60

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = local.codebuild_environment_variables_filtered

      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-build.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.name_prefix}-build"
      stream_name = "build"
    }
  }

  tags = local.common_tags
}

resource "aws_codebuild_project" "test" {
  count         = local.pipeline_enabled ? 1 : 0
  name          = "${local.name_prefix}-test"
  description   = "Terraform validate and plan"
  service_role  = aws_iam_role.codebuild[0].arn
  build_timeout = 60

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = local.codebuild_environment_variables_filtered

      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-test.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.name_prefix}-test"
      stream_name = "test"
    }
  }

  tags = local.common_tags
}

resource "aws_codebuild_project" "deploy" {
  count         = local.pipeline_enabled ? 1 : 0
  name          = "${local.name_prefix}-deploy"
  description   = "Terraform apply"
  service_role  = aws_iam_role.codebuild[0].arn
  build_timeout = 60

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = local.codebuild_environment_variables_filtered

      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.name_prefix}-deploy"
      stream_name = "deploy"
    }
  }

  tags = local.common_tags
}

########################################
# CODEPIPELINE ORCHESTRATION
########################################
# CodePipeline orchestrates GitHub source → build → test → deploy workflow
# with automatic status notifications and artifact management.
resource "aws_codepipeline" "this" {
  count    = local.pipeline_enabled ? 1 : 0
  name     = "${local.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline[0].arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts[0].bucket
    type     = "S3"
  }

  stage {
    name = "SOURCE"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = "${local.github_owner}/${local.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "BUILD"

    action {
      name             = "TerraformFmtInit"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build[0].name
      }
    }
  }

  stage {
    name = "TEST"

    action {
      name             = "TerraformValidatePlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["build_output"]
      output_artifacts = ["test_output"]

      configuration = {
        ProjectName = aws_codebuild_project.test[0].name
      }
    }
  }

  stage {
    name = "DEPLOY"

    action {
      name             = "TerraformApply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["test_output"]
      output_artifacts = ["deploy_output"]

      configuration = {
        ProjectName = aws_codebuild_project.deploy[0].name
      }
    }
  }

  tags = local.common_tags
}
