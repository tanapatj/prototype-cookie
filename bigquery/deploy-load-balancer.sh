#!/bin/bash
# ==============================================================================
# Deploy Cloud Load Balancer with Cloud Armor for Cloud Functions
# ==============================================================================
# This script creates a Cloud Load Balancer in front of Cloud Functions
# and attaches Cloud Armor security policies for DDoS protection.
#
# Architecture:
#   Internet → Cloud Load Balancer → Serverless NEG → Cloud Function
#                      ↓
#                 Cloud Armor
#                (DDoS Protection)
#
# Prerequisites:
# - Run deploy-cloud-armor.sh first
# - gcloud CLI authenticated
# - Project: conicle-ai-dev
#
# Usage:
#   bash deploy-load-balancer.sh
# ==============================================================================

set -e

PROJECT_ID="conicle-ai-dev"
REGION="asia-southeast1"
POLICY_NAME="consentmanager-ddos-protection"

# Cloud Function names
FUNCTION_NAME_AUTH="logConsentAuth"
FUNCTION_NAME_UNAUTH="logConsent"

# Backend names
BACKEND_AUTH="consentmanager-backend-auth"
BACKEND_UNAUTH="consentmanager-backend-unauth"

# Serverless NEG names
NEG_AUTH="consentmanager-neg-auth"
NEG_UNAUTH="consentmanager-neg-unauth"

# URL Map and target proxy
URL_MAP="consentmanager-url-map"
HTTP_PROXY="consentmanager-http-proxy"
HTTPS_PROXY="consentmanager-https-proxy"

# Forwarding rules
FORWARDING_RULE_HTTP="consentmanager-http"
FORWARDING_RULE_HTTPS="consentmanager-https"

# IP address
STATIC_IP="consentmanager-ip"

echo "=========================================="
echo "Cloud Load Balancer + Cloud Armor Setup"
echo "=========================================="
echo ""

gcloud config set project $PROJECT_ID

# ==============================================================================
# Step 1: Reserve Static IP
# ==============================================================================
echo "Step 1: Reserving static IP..."

if gcloud compute addresses describe $STATIC_IP --global 2>/dev/null; then
    echo "✅ Static IP already exists"
    IP_ADDRESS=$(gcloud compute addresses describe $STATIC_IP --global --format="get(address)")
else
    gcloud compute addresses create $STATIC_IP --global
    IP_ADDRESS=$(gcloud compute addresses describe $STATIC_IP --global --format="get(address)")
    echo "✅ Static IP created: $IP_ADDRESS"
fi

# ==============================================================================
# Step 2: Create Serverless NEGs (Network Endpoint Groups)
# ==============================================================================
echo ""
echo "Step 2: Creating Serverless NEGs..."

# NEG for authenticated function
if gcloud compute network-endpoint-groups describe $NEG_AUTH --region=$REGION 2>/dev/null; then
    echo "✅ NEG $NEG_AUTH already exists"
else
    gcloud compute network-endpoint-groups create $NEG_AUTH \
        --region=$REGION \
        --network-endpoint-type=SERVERLESS \
        --cloud-function-name=$FUNCTION_NAME_AUTH
    echo "✅ Created NEG: $NEG_AUTH"
fi

# NEG for unauthenticated function
if gcloud compute network-endpoint-groups describe $NEG_UNAUTH --region=$REGION 2>/dev/null; then
    echo "✅ NEG $NEG_UNAUTH already exists"
else
    gcloud compute network-endpoint-groups create $NEG_UNAUTH \
        --region=$REGION \
        --network-endpoint-type=SERVERLESS \
        --cloud-function-name=$FUNCTION_NAME_UNAUTH
    echo "✅ Created NEG: $NEG_UNAUTH"
fi

# ==============================================================================
# Step 3: Create Backend Services
# ==============================================================================
echo ""
echo "Step 3: Creating backend services..."

# Backend for authenticated function
if gcloud compute backend-services describe $BACKEND_AUTH --global 2>/dev/null; then
    echo "✅ Backend $BACKEND_AUTH already exists"
else
    gcloud compute backend-services create $BACKEND_AUTH \
        --global \
        --load-balancing-scheme=EXTERNAL_MANAGED \
        --protocol=HTTPS
    
    gcloud compute backend-services add-backend $BACKEND_AUTH \
        --global \
        --network-endpoint-group=$NEG_AUTH \
        --network-endpoint-group-region=$REGION
    
    echo "✅ Created backend: $BACKEND_AUTH"
fi

# Backend for unauthenticated function
if gcloud compute backend-services describe $BACKEND_UNAUTH --global 2>/dev/null; then
    echo "✅ Backend $BACKEND_UNAUTH already exists"
else
    gcloud compute backend-services create $BACKEND_UNAUTH \
        --global \
        --load-balancing-scheme=EXTERNAL_MANAGED \
        --protocol=HTTPS
    
    gcloud compute backend-services add-backend $BACKEND_UNAUTH \
        --global \
        --network-endpoint-group=$NEG_UNAUTH \
        --network-endpoint-group-region=$REGION
    
    echo "✅ Created backend: $BACKEND_UNAUTH"
fi

# ==============================================================================
# Step 4: Attach Cloud Armor to Backends
# ==============================================================================
echo ""
echo "Step 4: Attaching Cloud Armor policy..."

gcloud compute backend-services update $BACKEND_AUTH \
    --global \
    --security-policy=$POLICY_NAME

gcloud compute backend-services update $BACKEND_UNAUTH \
    --global \
    --security-policy=$POLICY_NAME

echo "✅ Cloud Armor attached to backends"

# ==============================================================================
# Step 5: Create URL Map
# ==============================================================================
echo ""
echo "Step 5: Creating URL map..."

if gcloud compute url-maps describe $URL_MAP 2>/dev/null; then
    echo "✅ URL map already exists"
else
    gcloud compute url-maps create $URL_MAP \
        --default-service=$BACKEND_AUTH
    
    # Add path matcher for routing
    gcloud compute url-maps add-path-matcher $URL_MAP \
        --path-matcher-name=consent-paths \
        --default-service=$BACKEND_AUTH \
        --path-rules="/auth=backend-auth,/log=backend-unauth"
    
    echo "✅ URL map created"
fi

# ==============================================================================
# Step 6: Create Target HTTPS Proxy
# ==============================================================================
echo ""
echo "Step 6: Creating target HTTPS proxy..."

if gcloud compute target-https-proxies describe $HTTPS_PROXY 2>/dev/null; then
    echo "✅ HTTPS proxy already exists"
else
    echo "⚠️  You need to create an SSL certificate first!"
    echo ""
    echo "Option 1 - Google-managed certificate (recommended):"
    echo "  gcloud compute ssl-certificates create consentmanager-cert \\"
    echo "    --domains=api.conicle.ai \\"
    echo "    --global"
    echo ""
    echo "Option 2 - Upload your own:"
    echo "  gcloud compute ssl-certificates create consentmanager-cert \\"
    echo "    --certificate=cert.pem \\"
    echo "    --private-key=key.pem \\"
    echo "    --global"
    echo ""
    echo "Then run this command:"
    echo "  gcloud compute target-https-proxies create $HTTPS_PROXY \\"
    echo "    --url-map=$URL_MAP \\"
    echo "    --ssl-certificates=consentmanager-cert"
    echo ""
fi

# ==============================================================================
# Step 7: Create Forwarding Rules
# ==============================================================================
echo ""
echo "Step 7: Creating forwarding rules..."

# HTTPS forwarding rule
if gcloud compute forwarding-rules describe $FORWARDING_RULE_HTTPS --global 2>/dev/null; then
    echo "✅ HTTPS forwarding rule already exists"
else
    echo "ℹ️  Create after HTTPS proxy is ready:"
    echo "  gcloud compute forwarding-rules create $FORWARDING_RULE_HTTPS \\"
    echo "    --global \\"
    echo "    --target-https-proxy=$HTTPS_PROXY \\"
    echo "    --address=$STATIC_IP \\"
    echo "    --ports=443"
fi

# HTTP redirect (optional)
echo ""
echo "ℹ️  Optionally, create HTTP → HTTPS redirect:"
echo "  gcloud compute url-maps create http-redirect-map \\"
echo "    --default-url-redirect-code=301 \\"
echo "    --default-url-redirect-https-redirect"
echo ""
echo "  gcloud compute target-http-proxies create http-redirect-proxy \\"
echo "    --url-map=http-redirect-map"
echo ""
echo "  gcloud compute forwarding-rules create http-redirect-rule \\"
echo "    --global \\"
echo "    --target-http-proxy=http-redirect-proxy \\"
echo "    --address=$STATIC_IP \\"
echo "    --ports=80"

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "=========================================="
echo "✅ Load Balancer Setup Complete!"
echo "=========================================="
echo ""
echo "Static IP: $IP_ADDRESS"
echo ""
echo "Next steps:"
echo "  1. Create SSL certificate (see above)"
echo "  2. Create HTTPS proxy and forwarding rule"
echo "  3. Point your domain to: $IP_ADDRESS"
echo "  4. Update DNS: api.conicle.ai → $IP_ADDRESS"
echo ""
echo "New endpoints will be:"
echo "  https://api.conicle.ai/auth  → Authenticated function"
echo "  https://api.conicle.ai/log   → Unauthenticated function"
echo ""
echo "Cost estimate: ~\$18-25/month"
echo "  - Cloud Load Balancer: ~\$18/month"
echo "  - Cloud Armor: ~\$1.50/month"
echo "  - Data processing: Variable"
echo ""
echo "=========================================="
