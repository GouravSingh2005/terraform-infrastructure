# Terraform Backend Configuration
# State file is stored remotely in S3 with DynamoDB state locking.
# Backend configuration is provided via backend.hcl.example at init time:
#   terraform init -backend-config=backend.hcl
#
# Remote backend enables:
# - Team collaboration (shared state)
# - Disaster recovery (S3 versioning)
# - State locking (prevents concurrent applies)
# - Audit trail (CloudTrail logs)

terraform {
  backend "s3" {}
}
