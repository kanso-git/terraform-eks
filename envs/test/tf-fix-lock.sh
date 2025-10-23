#!/bin/bash
# ==========================================================
# Terraform Lock Fix Script (Auto-detect + Force Cleanup)
# ==========================================================
# Usage:
#   chmod +x tf-fix-lock.sh
#   ./tf-fix-lock.sh
# ==========================================================

DYNAMO_TABLE="terraform-locks"
REGION="eu-central-2"

echo "🔍 Scanning DynamoDB table '$DYNAMO_TABLE' in region '$REGION' for any Terraform locks..."
LOCK_ITEMS=$(aws dynamodb scan \
  --table-name "$DYNAMO_TABLE" \
  --region "$REGION" \
  --query 'Items[*].LockID.S' \
  --output text 2>/dev/null)

if [ -z "$LOCK_ITEMS" ]; then
  echo "✅ No locks found in DynamoDB table '$DYNAMO_TABLE'."
  exit 0
fi

echo ""
echo "🔒 Found the following lock(s):"
echo "$LOCK_ITEMS"
echo ""

for LOCK_ID in $LOCK_ITEMS; do
  echo "🧹 Attempting to delete lock: $LOCK_ID"
  aws dynamodb delete-item \
    --table-name "$DYNAMO_TABLE" \
    --region "$REGION" \
    --key "{\"LockID\": {\"S\": \"$LOCK_ID\"}}" \
    >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "✅ Successfully deleted lock: $LOCK_ID"
  else
    echo "❌ Failed to delete lock: $LOCK_ID"
  fi
done

echo ""
echo "🪄 Rechecking for leftover locks..."
REMAINING=$(aws dynamodb scan \
  --table-name "$DYNAMO_TABLE" \
  --region "$REGION" \
  --query 'Items[*].LockID.S' \
  --output text 2>/dev/null)

if [ -z "$REMAINING" ]; then
  echo "✅ All Terraform locks removed successfully!"
  echo ""
  echo "You can now safely run:"
  echo "   terraform plan -var-file=\"test.tfvars\""
  echo "   terraform apply -var-file=\"test.tfvars\""
  echo "   terraform destroy -var-file=\"test.tfvars\""
else
  echo "⚠️ Still locked items remain:"
  echo "$REMAINING"
  echo "Try running again or check the DynamoDB console manually."
fi
