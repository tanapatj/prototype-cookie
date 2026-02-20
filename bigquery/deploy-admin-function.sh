#!/bin/bash
# Deploy the Admin Key Manager Cloud Function
# This function handles: generate, list, revoke API keys
# Auth: Google ID Token (@conicle.com only)

set -e

PROJECT_ID="conicle-ai-dev"
REGION="asia-southeast1"
FUNCTION_NAME="adminKeyManager"
RUNTIME="nodejs20"

echo "🚀 Deploying ${FUNCTION_NAME} to GCP..."
echo "   Project: ${PROJECT_ID}"
echo "   Region:  ${REGION}"

gcloud functions deploy "${FUNCTION_NAME}" \
  --gen2 \
  --runtime="${RUNTIME}" \
  --region="${REGION}" \
  --source="./cloud-function-admin" \
  --entry-point="adminKeyManager" \
  --trigger-http \
  --allow-unauthenticated \
  --project="${PROJECT_ID}" \
  --memory="256MB" \
  --timeout="30s" \
  --min-instances=0 \
  --max-instances=5 \
  --set-env-vars="ALLOWED_ADMIN_DOMAIN=conicle.com,NODE_ENV=production"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Function URL:"
gcloud functions describe "${FUNCTION_NAME}" \
  --gen2 \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(serviceConfig.uri)"
