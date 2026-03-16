#!/bin/bash
# ==============================================================================
# Deploy ConsentManager Cloud Functions to PRODUCTION
# Project: cookiemanager-488405
# Bucket:  gs://consentmanager
# ==============================================================================
# Usage: bash bigquery/deploy-prod.sh
# Run from the repo root.
# ==============================================================================

set -e

PROJECT_ID="cookiemanager-488405"
REGION="asia-southeast1"
IP_SALT=$(openssl rand -hex 32)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  ConsentManager — Production Deploy"
echo "  Project : $PROJECT_ID"
echo "  Region  : $REGION"
echo "=========================================="
echo ""

gcloud config set project "$PROJECT_ID"

# ── 1. logConsentAuth (authenticated, API-key gated) ─────────────────────────
echo "▶  Deploying logConsentAuth ..."
gcloud functions deploy logConsentAuth \
  --gen2 \
  --runtime=nodejs20 \
  --region="$REGION" \
  --source="$SCRIPT_DIR/cloud-function-auth" \
  --entry-point=logConsent \
  --trigger-http \
  --allow-unauthenticated \
  --project="$PROJECT_ID" \
  --memory=256MB \
  --timeout=60s \
  --min-instances=1 \
  --max-instances=100 \
  --concurrency=80 \
  --cpu=1 \
  --set-env-vars="IP_SALT=${IP_SALT},NODE_ENV=production"

AUTH_URL=$(gcloud functions describe logConsentAuth \
  --gen2 --region="$REGION" --project="$PROJECT_ID" \
  --format="value(serviceConfig.uri)")
echo "   ✅ logConsentAuth → $AUTH_URL"
echo ""

# ── 2. adminKeyManager (Google OAuth / @conicle.com only) ─────────────────────
echo "▶  Deploying adminKeyManager ..."
gcloud functions deploy adminKeyManager \
  --gen2 \
  --runtime=nodejs20 \
  --region="$REGION" \
  --source="$SCRIPT_DIR/cloud-function-admin" \
  --entry-point=adminKeyManager \
  --trigger-http \
  --allow-unauthenticated \
  --project="$PROJECT_ID" \
  --memory=256MB \
  --timeout=30s \
  --min-instances=0 \
  --max-instances=5 \
  --set-env-vars="ALLOWED_ADMIN_DOMAIN=conicle.com,NODE_ENV=production"

ADMIN_URL=$(gcloud functions describe adminKeyManager \
  --gen2 --region="$REGION" --project="$PROJECT_ID" \
  --format="value(serviceConfig.uri)")
echo "   ✅ adminKeyManager → $ADMIN_URL"
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "=========================================="
echo "  ✅ All functions deployed!"
echo "=========================================="
echo ""
echo "  logConsentAuth : $AUTH_URL"
echo "  adminKeyManager: $ADMIN_URL"
echo ""
echo "  ⚠  Next: update these URLs in:"
echo "     - admin-portal/index.html"
echo "     - START_HERE.md"
echo ""
