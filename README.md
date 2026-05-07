# Enterprise AWS Three-Tier Platform with Terraform

This repository provisions a production-style, highly modular AWS infrastructure for a public application load balancer, private application EC2 instances, and a database-ready network layout. The code is structured for real-world operations: reusable modules, remote state, IAM-based automation, optional ALB access logs, CloudWatch logs, and a CodePipeline/CodeBuild delivery chain.

## Architecture

```
Internet
  -> Public Application Load Balancer
  -> Private EC2 Auto Scaling Group
  -> Private DB subnets reserved for future database workloads
```

The application tier runs in private subnets with no public IPs. The ALB is internet-facing and terminates HTTPS with your ACM certificate. HTTP is redirected to HTTPS. The EC2 instances are launched from an encrypted launch template with IMDSv2 enforced, detailed monitoring enabled, and user data that installs and runs a Node.js service directly.

## Folder Structure

- `bootstrap/` creates the S3 backend bucket and DynamoDB state lock table.
- `modules/vpc/` creates the VPC, subnets, route tables, IGW, NAT gateway, and associations.
- `modules/security-groups/` isolates the ALB, application tier, and future database tier.
- `modules/iam/` creates the EC2 instance role and instance profile.
- `modules/userdata/` renders the production-style `user_data.sh` script.
- `modules/ec2/` defines the launch template.
- `modules/alb/` provisions the ALB, target group, and listeners.
- `modules/asg/` provisions the Auto Scaling Group and target tracking policy.
- `modules/monitoring/` creates CloudWatch log groups and alarms.
- `cicd.tf` defines CodePipeline, CodeBuild, and the required IAM roles.
- `buildspec-build.yml`, `buildspec-test.yml`, `buildspec-deploy.yml` are used by CodeBuild.
- `app/` contains the Node.js app source used by the bootstrap script.

## Bootstrap Remote State

Terraform state is designed to live in S3 with DynamoDB locking.

1. Deploy the bootstrap stack first:

```bash
cd bootstrap
terraform init
terraform apply \
  -var="region=us-east-1" \
  -var="environment=prod" \
  -var="project_name=enterprise-3tier" \
  -var="owner=platform-team"
```

2. Note the outputs:
- `state_bucket_name`
- `lock_table_name`

3. Initialize the root stack with the backend config file:

```bash
cd ..
terraform init -backend-config=backend.hcl.example
```

For production, replace `backend.hcl.example` with a real backend config file containing your actual bucket and lock table names.

## Deployment Commands

```bash
terraform fmt -recursive
terraform init -backend-config=backend.hcl.example
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## One-Command Deployment

If you want Terraform to run end-to-end with one command, use the helper script in `scripts/deploy.sh`.
It will:

1. Run the bootstrap stack if backend values are not provided.
2. Read the S3 bucket and DynamoDB lock table from bootstrap outputs.
3. Initialize the root stack backend.
4. Run `terraform plan` and `terraform apply` with the minimum required inputs.

Required environment variables:

- `GITHUB_REPOSITORY` in `owner/repo` form
- `ACM_CERTIFICATE_ARN`

Optional environment variables:

- `CODESTAR_CONNECTION_ARN` to enable the GitHub pipeline
- `REGION` to override the AWS region, default `ap-south-1`
- `ENVIRONMENT`, `PROJECT_NAME`, `OWNER` to override naming defaults
- `BACKEND_BUCKET` and `BACKEND_LOCK_TABLE` if you already know the backend names

Example:

```bash
cd /home/gourav/Terraform-new
chmod +x scripts/deploy.sh

GITHUB_REPOSITORY=GouravSingh2005/terraform-infrastructure \
ACM_CERTIFICATE_ARN=arn:aws:acm:ap-south-1:626052500009:certificate/96174bb0-b5d4-4278-a9fb-1cb7457dc95a \
CODESTAR_CONNECTION_ARN=arn:aws:codestar-connections:ap-south-1:626052500009:connection/xxxx \
scripts/deploy.sh
```

If `CODESTAR_CONNECTION_ARN` is omitted, the infrastructure still deploys, but the GitHub-triggered pipeline stays disabled until you add and authorize the connection.

## Example Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values for your environment. The important inputs are:

- `region`
- `environment`
- `project_name`
- `vpc_cidr`
- subnet CIDRs
- `instance_type`
- `desired_capacity`, `min_capacity`, `max_capacity`
- `ssh_allowed_cidr`
- `domain_name`
- `subdomain`
- `acm_certificate_arn`

## GitHub Integration and CodePipeline

The pipeline uses CodeStar Connections for GitHub integration. Create or reuse a CodeStar connection in AWS, authorize access to your GitHub repository, and set:

- `codestar_connection_arn`
- `github_owner`
- `github_repo`
- `github_branch`

Pipeline stages:

1. Source pulls from GitHub.
2. Build runs `terraform fmt` and `terraform init`.
3. Test runs `terraform validate` and `terraform plan`.
4. Deploy runs `terraform apply -auto-approve`.

## IAM and Permissions

CodeBuild does not use access keys. It receives short-lived AWS credentials from the IAM role attached to the CodeBuild project. AWS automatically assumes that role for each build container, so the Terraform CLI inside CodeBuild inherits the role's permissions without any static credentials.

The EC2 tier uses an instance profile instead of embedded secrets or access keys. The role includes Systems Manager and CloudWatch agent permissions for safer operations and log shipping.

## Namecheap DNS Mapping

Route 53 is intentionally not created here.

After Terraform finishes, take the ALB DNS name output and create a CNAME record in Namecheap:

- `app.example.com` -> `<ALB_DNS_NAME>`

If your apex domain is `example.com`, use a subdomain for the ALB target because CNAMEs are best suited to subdomains.

## Security Notes

- Instances run in private subnets with no public IPs.
- Security groups are separated by tier.
- The ALB is the only internet-facing component.
- Root volumes are encrypted.
- IMDSv2 is required.
- Deletion protection is enabled on the ALB by default.
- The database subnet route tables are isolated and do not receive a default internet route.

## Monitoring and Scaling

The stack includes:

- CloudWatch log groups for application and user-data logs
- CloudWatch alarms for in-service capacity, target 5xx errors, and unhealthy hosts
- ALB access logs to S3 when enabled
- ASG target tracking scaling on average CPU utilization
- detailed EC2 monitoring

## Troubleshooting

- If the ALB target group stays unhealthy, check `/var/log/user-data.log` and the application log group in CloudWatch.
- If Terraform backend initialization fails, verify the S3 bucket name, DynamoDB table name, and region in the backend config.
- If the pipeline does not start, confirm the CodeStar connection is authorized and the GitHub repository values are correct.
- If SSH is required, remember the instances are private; use a VPN, bastion host, or an approved corporate CIDR.

## Outputs

The root module exports:

- VPC ID
- public, private app, and private DB subnet IDs
- ALB DNS name
- application URL
- ASG name
- security group IDs
- target group ARN

## Notes on Production Hardening

This repository is intentionally opinionated toward enterprise operations, but you should still adapt IAM policies, alarm thresholds, and scaling policies to your account standards and workload profile before using it in production.
