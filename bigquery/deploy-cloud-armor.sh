#!/bin/bash
# ==============================================================================
# Deploy Google Cloud Armor - DDoS Protection for ConsentManager
# ==============================================================================
# This script sets up Cloud Armor security policies to protect against DDoS attacks
# 
# Prerequisites:
# - gcloud CLI installed and authenticated
# - Project: conicle-ai-dev (or update PROJECT_ID below)
# - Required IAM roles: Compute Security Admin
#
# Usage:
#   bash deploy-cloud-armor.sh
# ==============================================================================

set -e  # Exit on error

PROJECT_ID="conicle-ai-dev"
POLICY_NAME="consentmanager-ddos-protection"

echo "=========================================="
echo "Cloud Armor DDoS Protection Setup"
echo "=========================================="
echo ""
echo "Project: $PROJECT_ID"
echo "Policy: $POLICY_NAME"
echo ""

# Set project
gcloud config set project $PROJECT_ID

# ==============================================================================
# Step 1: Create Security Policy
# ==============================================================================
echo "Step 1: Creating Cloud Armor security policy..."

if gcloud compute security-policies describe $POLICY_NAME 2>/dev/null; then
    echo "⚠️  Policy already exists. Skipping creation."
else
    gcloud compute security-policies create $POLICY_NAME \
        --description "DDoS protection for ConsentManager Cloud Functions" \
        --type CLOUD_ARMOR
    
    echo "✅ Security policy created"
fi

# ==============================================================================
# Step 2: Add Rate Limiting Rule (Layer 7)
# ==============================================================================
echo ""
echo "Step 2: Adding rate limiting rule..."

# Rule: 100 requests per minute per IP
# If exceeded, ban for 10 minutes
gcloud compute security-policies rules create 1000 \
    --security-policy $POLICY_NAME \
    --expression "true" \
    --action "rate-based-ban" \
    --rate-limit-threshold-count 100 \
    --rate-limit-threshold-interval-sec 60 \
    --ban-duration-sec 600 \
    --conform-action "allow" \
    --exceed-action "deny-429" \
    --enforce-on-key "IP" || echo "⚠️  Rule 1000 already exists"

echo "✅ Rate limiting configured: 100 req/min per IP"

# ==============================================================================
# Step 3: Add Geo-blocking Rule (Optional)
# ==============================================================================
echo ""
echo "Step 3: Adding geo-blocking rule (optional)..."

# Example: Block traffic from high-risk countries
# Uncomment and modify the list as needed
# gcloud compute security-policies rules create 2000 \
#     --security-policy $POLICY_NAME \
#     --expression "origin.region_code in ['CN', 'RU', 'KP']" \
#     --action "deny-403" \
#     --description "Block high-risk countries" || echo "⚠️  Rule 2000 already exists"

echo "ℹ️  Geo-blocking rule skipped (uncomment in script if needed)"

# ==============================================================================
# Step 4: Add SQL Injection & XSS Protection
# ==============================================================================
echo ""
echo "Step 4: Enabling preconfigured WAF rules..."

# Add OWASP ModSecurity Core Rule Set
gcloud compute security-policies rules create 3000 \
    --security-policy $POLICY_NAME \
    --expression "evaluatePreconfiguredExpr('sqli-v33-stable')" \
    --action "deny-403" \
    --description "SQL injection protection" || echo "⚠️  Rule 3000 already exists"

gcloud compute security-policies rules create 3100 \
    --security-policy $POLICY_NAME \
    --expression "evaluatePreconfiguredExpr('xss-v33-stable')" \
    --action "deny-403" \
    --description "XSS protection" || echo "⚠️  Rule 3100 already exists"

echo "✅ WAF rules enabled (SQLi, XSS)"

# ==============================================================================
# Step 5: Enable Adaptive Protection (ML-based DDoS detection)
# ==============================================================================
echo ""
echo "Step 5: Enabling Adaptive Protection (ML-based DDoS detection)..."

gcloud compute security-policies update $POLICY_NAME \
    --enable-layer7-ddos-defense \
    --layer7-ddos-defense-rule-visibility=STANDARD

echo "✅ Adaptive Protection enabled"

# ==============================================================================
# Step 6: Display Summary
# ==============================================================================
echo ""
echo "=========================================="
echo "✅ Cloud Armor Setup Complete!"
echo "=========================================="
echo ""
echo "Security Policy: $POLICY_NAME"
echo ""
echo "Rules configured:"
echo "  - Rate limiting: 100 requests/min per IP"
echo "  - Ban duration: 10 minutes"
echo "  - SQL injection protection"
echo "  - XSS protection"
echo "  - Adaptive Protection (ML-based)"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo ""
echo "This security policy needs to be attached to a backend service."
echo "Cloud Functions don't support Cloud Armor directly."
echo ""
echo "You have two options:"
echo ""
echo "Option 1: Deploy API Gateway (recommended)"
echo "  - See: deploy-api-gateway.sh"
echo ""
echo "Option 2: Deploy Cloud Load Balancer + Serverless NEG"
echo "  - See: deploy-load-balancer.sh"
echo ""
echo "Cost: ~\$1.50/month for Cloud Armor policy + rules"
echo ""
echo "=========================================="
