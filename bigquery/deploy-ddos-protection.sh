#!/bin/bash
# ==============================================================================
# Deploy Updated Cloud Functions with DDoS Protection
# ==============================================================================
# This script redeploys the Cloud Functions with the new DDoS protection code
#
# Prerequisites:
# - gcloud CLI installed and authenticated
# - Functions already exist and need to be updated
# - Node.js dependencies (package.json) in function directories
#
# Usage:
#   bash deploy-ddos-protection.sh
# ==============================================================================

set -e

PROJECT_ID="conicle-ai-dev"
REGION_AUTH="asia-southeast1"
REGION_UNAUTH="asia-southeast3"

echo "=========================================="
echo "Deploy DDoS Protection Updates"
echo "=========================================="
echo ""
echo "Project: $PROJECT_ID"
echo ""

gcloud config set project $PROJECT_ID

# ==============================================================================
# Deploy Authenticated Function (with DDoS protection)
# ==============================================================================
echo "Step 1: Deploying authenticated function..."
echo "  Function: logConsentAuth"
echo "  Region: $REGION_AUTH"
echo "  Location: cloud-function-auth/"
echo ""

cd cloud-function-auth

echo "Checking package.json..."
if [ ! -f "package.json" ]; then
    echo "⚠️  package.json not found. Creating..."
    cat > package.json <<'EOF'
{
  "name": "log-consent-auth",
  "version": "2.0.0",
  "description": "Authenticated consent logging with DDoS protection",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/bigquery": "^7.0.0",
    "uuid": "^9.0.0"
  },
  "engines": {
    "node": "20"
  }
}
EOF
fi

echo ""
echo "Deploying..."
gcloud functions deploy logConsentAuth \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region=$REGION_AUTH \
  --entry-point=logConsent \
  --memory=256MB \
  --timeout=60s \
  --max-instances=100 \
  --set-env-vars="IP_SALT=$(openssl rand -hex 32)" \
  --quiet

echo ""
echo "✅ Authenticated function deployed"
echo ""

cd ..

# ==============================================================================
# Deploy Unauthenticated Function (with DDoS protection)
# ==============================================================================
echo "Step 2: Deploying unauthenticated function..."
echo "  Function: logConsent"
echo "  Region: $REGION_UNAUTH"
echo "  Location: cloud-function/"
echo ""

cd cloud-function

echo "Checking package.json..."
if [ ! -f "package.json" ]; then
    echo "⚠️  package.json not found. Creating..."
    cat > package.json <<'EOF'
{
  "name": "log-consent",
  "version": "2.0.0",
  "description": "Consent logging with DDoS protection",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/bigquery": "^7.0.0",
    "uuid": "^9.0.0"
  },
  "engines": {
    "node": "20"
  }
}
EOF
fi

echo ""
echo "Deploying..."
gcloud functions deploy logConsent \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region=$REGION_UNAUTH \
  --entry-point=logConsent \
  --memory=256MB \
  --timeout=60s \
  --max-instances=100 \
  --set-env-vars="IP_SALT=$(openssl rand -hex 32)" \
  --quiet

echo ""
echo "✅ Unauthenticated function deployed"
echo ""

cd ..

# ==============================================================================
# Summary
# ==============================================================================
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Both Cloud Functions have been updated with:"
echo "  ✅ Per-IP rate limiting"
echo "  ✅ Request size validation (50KB max)"
echo "  ✅ Content-Type validation"
echo "  ✅ Timeout protection (5 seconds)"
echo "  ✅ Enhanced error handling"
echo ""
echo "Function URLs:"
AUTH_URL=$(gcloud functions describe logConsentAuth --region=$REGION_AUTH --format="value(httpsTrigger.url)")
UNAUTH_URL=$(gcloud functions describe logConsent --region=$REGION_UNAUTH --format="value(httpsTrigger.url)")
echo "  Auth:   $AUTH_URL"
echo "  Unauth: $UNAUTH_URL"
echo ""
echo "Next step: Run tests to verify protection is working"
echo "  cd .."
echo "  python3 test-ddos-protection.py all"
echo ""
echo "=========================================="
