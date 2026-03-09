#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="valentinweyer-com"
REGION="eu-central-1"
TEMPLATE_FILE="iac/cloudformation/amplify.yaml"
BRANCH_NAME="main"
POLL_INTERVAL=15

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: Required command '$1' is not installed or not in PATH."
    exit 1
  fi
}

get_stack_output() {
  local output_key="$1"
  aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query "Stacks[0].Outputs[?OutputKey=='${output_key}'].OutputValue" \
    --output text
}

echo "Running preflight checks..."

require_command aws

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Error: AWS CLI is not authenticated. Please run 'aws configure' or authenticate first."
  exit 1
fi

if [ -z "${GITHUB_ACCESS_TOKEN:-}" ]; then
  echo "Error: GITHUB_ACCESS_TOKEN is not set."
  exit 1
fi

if [ -z "${GITHUB_REPOSITORY_URL:-}" ]; then
  echo "Error: GITHUB_REPOSITORY_URL is not set."
  exit 1
fi

if [ ! -f "${TEMPLATE_FILE}" ]; then
  echo "Error: CloudFormation template '${TEMPLATE_FILE}' was not found."
  exit 1
fi

echo "Validating CloudFormation template..."
aws cloudformation validate-template \
  --template-body "file://${TEMPLATE_FILE}" \
  --region "${REGION}" >/dev/null

echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file "${TEMPLATE_FILE}" \
  --stack-name "${STACK_NAME}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubAccessToken="${GITHUB_ACCESS_TOKEN}" \
    GitHubRepositoryURL="${GITHUB_REPOSITORY_URL}" \
  --region "${REGION}"

echo "Reading CloudFormation outputs..."
APP_ID="$(get_stack_output "AmplifyAppId")"
DEFAULT_DOMAIN="$(get_stack_output "AmplifyDefaultDomain")"
PRODUCTION_URL="$(get_stack_output "ProductionURL")"

if [ -z "${APP_ID}" ] || [ "${APP_ID}" = "None" ]; then
  echo "Error: Could not retrieve Amplify App ID from stack outputs."
  exit 1
fi

if [ -z "${DEFAULT_DOMAIN}" ] || [ "${DEFAULT_DOMAIN}" = "None" ]; then
  echo "Error: Could not retrieve Amplify default domain from stack outputs."
  exit 1
fi

if [ -z "${PRODUCTION_URL}" ] || [ "${PRODUCTION_URL}" = "None" ]; then
  PRODUCTION_URL="https://${BRANCH_NAME}.${DEFAULT_DOMAIN}"
fi

echo "Amplify App ID: ${APP_ID}"
echo "Amplify Default Domain: ${DEFAULT_DOMAIN}"
echo "Production URL: ${PRODUCTION_URL}"

echo "Triggering Amplify deployment for branch '${BRANCH_NAME}'..."
JOB_ID="$(aws amplify start-job \
  --app-id "${APP_ID}" \
  --branch-name "${BRANCH_NAME}" \
  --job-type RELEASE \
  --region "${REGION}" \
  --query 'jobSummary.jobId' \
  --output text)"

if [ -z "${JOB_ID}" ] || [ "${JOB_ID}" = "None" ]; then
  echo "Error: Failed to start Amplify job."
  exit 1
fi

echo "Amplify deployment started."
echo "Job ID: ${JOB_ID}"
echo "Waiting for build to finish..."

while true; do
  JOB_STATUS="$(aws amplify get-job \
    --app-id "${APP_ID}" \
    --branch-name "${BRANCH_NAME}" \
    --job-id "${JOB_ID}" \
    --region "${REGION}" \
    --query 'job.summary.status' \
    --output text)"

  case "${JOB_STATUS}" in
    SUCCEED)
      echo "Amplify build completed successfully."
      echo "Website URL: ${PRODUCTION_URL}"
      exit 0
      ;;
    FAILED|CANCELLED)
      echo "Amplify build ended with status: ${JOB_STATUS}"
      echo "Website URL: ${PRODUCTION_URL}"
      echo "You can inspect the job with:"
      echo "aws amplify get-job --app-id ${APP_ID} --branch-name ${BRANCH_NAME} --job-id ${JOB_ID} --region ${REGION}"
      exit 1
      ;;
    PENDING|PROVISIONING|RUNNING)
      echo "Current status: ${JOB_STATUS}. Checking again in ${POLL_INTERVAL}s..."
      sleep "${POLL_INTERVAL}"
      ;;
    *)
      echo "Current status: ${JOB_STATUS}. Checking again in ${POLL_INTERVAL}s..."
      sleep "${POLL_INTERVAL}"
      ;;
  esac
done