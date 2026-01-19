#!/usr/bin/env bash
set -euo pipefail

# Update existing Lambda function code.

FUNCTION_NAME="request-logger"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Package the function.
(cd /tmp && cp "$SCRIPT_DIR/lambda_function.py" . && zip -q function.zip lambda_function.py)

# Update the function code.
aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb:///tmp/function.zip \
  --query 'LastModified' \
  --output text

# Cleanup.
rm -f /tmp/lambda_function.py /tmp/function.zip

echo "Updated $FUNCTION_NAME"
