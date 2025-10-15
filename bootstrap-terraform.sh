#!/usr/bin/env bash
# ==========================================================
# 🏗️ Terraform EKS Bootstrap Script
# Author: experts-lab.com
# Description:
#   This script prepares the Terraform backend for your EKS
#   infrastructure by creating:
#     - An S3 bucket to store remote Terraform state
#     - A DynamoDB table for state locking
#   Run this script ONCE per AWS account / region.
# ==========================================================

set -euo pipefail

# -------------------------------
# 🔧 Configuration (edit as needed)
# -------------------------------
AWS_REGION="eu-central-2"  # Zurich
BUCKET_NAME="experts-lab-terraform-states"
DYNAMO_TABLE="terraform-locks"
PROFILE="${AWS_PROFILE:-default}"

# -------------------------------
# 🧭 Display context
# -------------------------------
echo "🔹 AWS Profile : ${PROFILE}"
echo "🔹 AWS Region  : ${AWS_REGION}"
echo "🔹 S3 Bucket   : ${BUCKET_NAME}"
echo "🔹 Dynamo Table: ${DYNAMO_TABLE}"
echo "--------------------------------------------------------"

# -------------------------------
# 🪣 Create S3 Bucket (idempotent)
# -------------------------------
if aws s3api head-bucket --bucket "$BUCKET_NAME" --profile "$PROFILE" 2>/dev/null; then
  echo "✅ S3 bucket already exists: $BUCKET_NAME"
else
  echo "🪣 Creating S3 bucket: $BUCKET_NAME ..."
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" \
    --profile "$PROFILE"
  echo "✅ S3 bucket created."
fi

# Enable versioning for state history
echo "🔄 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --profile "$PROFILE"
echo "✅ Versioning enabled."

# -------------------------------
# 🔐 Create DynamoDB Table (idempotent)
# -------------------------------
if aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --profile "$PROFILE" >/dev/null 2>&1; then
  echo "✅ DynamoDB table already exists: $DYNAMO_TABLE"
else
  echo "🔐 Creating DynamoDB table: $DYNAMO_TABLE ..."
  aws dynamodb create-table \
    --table-name "$DYNAMO_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" \
    --profile "$PROFILE"
  echo "✅ DynamoDB table created."
fi

# -------------------------------
# ✅ Final confirmation
# -------------------------------
echo ""
echo "🎉 Terraform backend is ready!"
echo "   • S3 Bucket  : $BUCKET_NAME"
echo "   • DynamoDB   : $DYNAMO_TABLE"
echo "   • AWS Region : $AWS_REGION"
echo ""
echo "Next steps:"
echo "  cd envs/dev && terraform init -reconfigure"
echo "--------------------------------------------------------"
