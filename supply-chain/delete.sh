#!/usr/bin/env bash
set -euo pipefail

# Delete all resources created by setup.sh.

FUNCTION_NAME="request-logger"
ROLE_NAME="lambda-request-logger-role"
POLICY_NAME="lambda-request-logger-permissions"

# Load bucket name from .env or use argument.
if [[ -f .env ]]; then
  source .env
fi
BUCKET_NAME="${1:-${BUCKET_NAME:-}}"

if [[ -z "$BUCKET_NAME" ]]; then
  echo "Usage: ./delete.sh <bucket-name>"
  echo "Or create .env with BUCKET_NAME=..."
  exit 1
fi

echo "Deleting request logger..."
echo "Bucket: $BUCKET_NAME"

# Delete Lambda function URL and function.
aws lambda delete-function-url-config --function-name "$FUNCTION_NAME" 2>/dev/null || true
aws lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null || true

# Delete IAM role and policy.
aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" 2>/dev/null || true
aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || true

# Empty and delete S3 bucket.
aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true
aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null || true

# Delete CloudWatch log group.
aws logs delete-log-group --log-group-name "/aws/lambda/$FUNCTION_NAME" 2>/dev/null || true

# Cleanup local files.
rm -f .env

echo "Done!"
