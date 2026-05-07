#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="${ROOT_DIR}/bootstrap"

REGION="${REGION:-ap-south-1}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
PROJECT_NAME="${PROJECT_NAME:-enterprise-3tier}"
OWNER="${OWNER:-platform-team}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?Set GITHUB_REPOSITORY to owner/repo}"
ACM_CERTIFICATE_ARN="${ACM_CERTIFICATE_ARN:?Set ACM_CERTIFICATE_ARN to the ACM certificate ARN}"
CODESTAR_CONNECTION_ARN="${CODESTAR_CONNECTION_ARN:-}"
BACKEND_BUCKET="${BACKEND_BUCKET:-}"
BACKEND_LOCK_TABLE="${BACKEND_LOCK_TABLE:-}"
BACKEND_KEY="${BACKEND_KEY:-${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate}"

if [[ -z "${BACKEND_BUCKET}" || -z "${BACKEND_LOCK_TABLE}" ]]; then
  pushd "${BOOTSTRAP_DIR}" >/dev/null
  terraform init
  terraform apply -auto-approve \
    -var="region=${REGION}" \
    -var="environment=${ENVIRONMENT}" \
    -var="project_name=${PROJECT_NAME}" \
    -var="owner=${OWNER}"
  BACKEND_BUCKET="$(terraform output -raw state_bucket_name)"
  BACKEND_LOCK_TABLE="$(terraform output -raw lock_table_name)"
  popd >/dev/null
fi

pushd "${ROOT_DIR}" >/dev/null
terraform init \
  -backend-config="bucket=${BACKEND_BUCKET}" \
  -backend-config="key=${BACKEND_KEY}" \
  -backend-config="region=${REGION}" \
  -backend-config="dynamodb_table=${BACKEND_LOCK_TABLE}" \
  -backend-config="encrypt=true"

PLAN_FILE="tfplan.auto"
PLAN_ARGS=(
  -var="region=${REGION}"
  -var="environment=${ENVIRONMENT}"
  -var="project_name=${PROJECT_NAME}"
  -var="owner=${OWNER}"
  -var="github_repository=${GITHUB_REPOSITORY}"
  -var="acm_certificate_arn=${ACM_CERTIFICATE_ARN}"
)

if [[ -n "${CODESTAR_CONNECTION_ARN}" ]]; then
  PLAN_ARGS+=( -var="codestar_connection_arn=${CODESTAR_CONNECTION_ARN}" )
fi

terraform plan "${PLAN_ARGS[@]}" -out="${PLAN_FILE}"
terraform apply -auto-approve "${PLAN_FILE}"
popd >/dev/null

echo "Deployment complete."
echo "Backend bucket: ${BACKEND_BUCKET}"
echo "Lock table: ${BACKEND_LOCK_TABLE}"
