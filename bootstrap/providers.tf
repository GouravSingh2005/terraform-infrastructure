########################################
# BOOTSTRAP PROVIDER CONFIGURATION
########################################
# AWS provider setup for bootstrap stack

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
