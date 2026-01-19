#!/usr/bin/env bash
set -euo pipefail

# Lambda request logger - logs all HTTP requests to S3.
# Creates: S3 bucket, IAM role, Lambda function, public function URL.

FUNCTION_NAME="request-logger"
ROLE_NAME="lambda-request-logger-role"
POLICY_NAME="lambda-request-logger-permissions"
REGION="${AWS_REGION:-us-east-1}"
BUCKET_NAME="${1:-skilltools-request-logs-$(date +%s)}"

echo "Setting up request logger..."
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"

# Create S3 bucket, or confirm it already exists.
aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"

# Create IAM role.
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' > /dev/null

# Attach permissions policy.
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"logs:CreateLogGroup\", \"logs:CreateLogStream\", \"logs:PutLogEvents\"],
        \"Resource\": \"arn:aws:logs:*:*:*\"
      },
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"s3:PutObject\"],
        \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\"
      }
    ]
  }"

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

# Create Lambda function code.
cat > /tmp/lambda_function.py << 'EOF'
import json, boto3, os
from datetime import datetime

s3 = boto3.client('s3')
BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    request_context = event.get('requestContext', {})
    http_info = request_context.get('http', {})

    log_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'request_id': context.aws_request_id,
        'raw_path': event.get('rawPath', ''),
        'raw_query_string': event.get('rawQueryString', ''),
        'requested_filename': event.get('rawPath', '').split('/')[-1] if event.get('rawPath') else 'unknown',
        'http_method': http_info.get('method', 'UNKNOWN'),
        'source_ip': http_info.get('sourceIp', 'unknown'),
        'user_agent': http_info.get('userAgent', 'unknown'),
        'headers': event.get('headers', {}),
        'query_parameters': event.get('queryStringParameters', {}),
        'body': event.get('body', '')
    }

    file_key = f"logs/{datetime.utcnow().strftime('%Y-%m-%d/%H')}/{context.aws_request_id}.json"
    s3.put_object(Bucket=BUCKET_NAME, Key=file_key, Body=json.dumps(log_entry, indent=2), ContentType='application/json')

    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'message': 'Logged', 'path': log_entry['raw_path'], 'headers_logged': len(log_entry['headers'])})
    }
EOF

(cd /tmp && zip -q function.zip lambda_function.py)

# Wait for IAM propagation.
echo "Waiting for IAM propagation..."
sleep 10

# Create Lambda function.
aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb:///tmp/function.zip \
  --environment "Variables={BUCKET_NAME=$BUCKET_NAME}" \
  --timeout 10 \
  --memory-size 128 > /dev/null

# Create function URL.
aws lambda create-function-url-config \
  --function-name "$FUNCTION_NAME" \
  --auth-type NONE > /dev/null

# Add public access permissions (both required since Oct 2025).
aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id FunctionURLAllowPublicAccess \
  --action lambda:InvokeFunctionUrl \
  --principal "*" \
  --function-url-auth-type NONE > /dev/null

aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id FunctionURLInvokeAllowPublicAccess \
  --action lambda:InvokeFunction \
  --principal "*" > /dev/null

FUNCTION_URL=$(aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --query 'FunctionUrl' --output text)

# Save config for other scripts.
cat > .env << EOF
BUCKET_NAME=$BUCKET_NAME
FUNCTION_URL=$FUNCTION_URL
REGION=$REGION
EOF

# Cleanup temp files.
rm -f /tmp/lambda_function.py /tmp/function.zip

echo ""
echo "Done!"
echo "Function URL: $FUNCTION_URL"
echo "Bucket: $BUCKET_NAME"
echo "Config saved to .env"
