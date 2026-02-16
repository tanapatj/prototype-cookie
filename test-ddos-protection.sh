#!/bin/bash
# ==============================================================================
# DDoS Protection Test Script
# ==============================================================================
# This script tests the rate limiting protection by sending multiple requests
# to the Cloud Function and observing when rate limiting kicks in.
#
# Expected behavior:
# - First 10 requests: HTTP 200 (success)
# - Requests 11+: HTTP 429 (rate limit exceeded)
# ==============================================================================

# Configuration
ENDPOINT="https://logconsentauth-pxoxh5sfqa-as.a.run.app"
API_KEY="demo-key-12345678-1234-1234-1234-123456789abc"  # Replace with your actual API key
NUM_REQUESTS=15
DELAY=0.5  # seconds between requests

echo "=========================================="
echo "DDoS Protection Test"
echo "=========================================="
echo ""
echo "Endpoint: $ENDPOINT"
echo "Number of requests: $NUM_REQUESTS"
echo "Delay between requests: ${DELAY}s"
echo ""
echo "Expected behavior:"
echo "  - Requests 1-10: ✅ HTTP 200 (success)"
echo "  - Requests 11+:  ❌ HTTP 429 (rate limited)"
echo ""
echo "=========================================="
echo ""

# Request payload
PAYLOAD='{
  "event_type": "consent_given",
  "cookie": {
    "categories": ["necessary", "analytics"],
    "services": []
  },
  "pageUrl": "https://test.example.com/ddos-test",
  "pageTitle": "DDoS Protection Test"
}'

# Counters
SUCCESS_COUNT=0
RATE_LIMITED_COUNT=0
ERROR_COUNT=0

echo "Starting test..."
echo ""

# Send requests
for i in $(seq 1 $NUM_REQUESTS); do
  printf "Request %2d: " "$i"
  
  # Make request and capture status code
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "$PAYLOAD")
  
  # Print result with color
  case $HTTP_CODE in
    200)
      echo "✅ HTTP $HTTP_CODE - Success"
      ((SUCCESS_COUNT++))
      ;;
    429)
      echo "🛡️  HTTP $HTTP_CODE - Rate Limited (PROTECTION WORKING!)"
      ((RATE_LIMITED_COUNT++))
      ;;
    *)
      echo "❌ HTTP $HTTP_CODE - Error"
      ((ERROR_COUNT++))
      ;;
  esac
  
  # Wait before next request (except for the last one)
  if [ $i -lt $NUM_REQUESTS ]; then
    sleep $DELAY
  fi
done

# Summary
echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo ""
echo "Total requests sent: $NUM_REQUESTS"
echo "  ✅ Successful (200): $SUCCESS_COUNT"
echo "  🛡️  Rate limited (429): $RATE_LIMITED_COUNT"
echo "  ❌ Errors: $ERROR_COUNT"
echo ""

# Evaluate results
if [ $RATE_LIMITED_COUNT -gt 0 ] && [ $SUCCESS_COUNT -le 10 ]; then
  echo "✅ DDoS PROTECTION IS WORKING!"
  echo ""
  echo "The rate limiter successfully blocked requests after"
  echo "the threshold was exceeded (10 requests per 10 seconds)."
  exit 0
else
  echo "⚠️  WARNING: Rate limiting may not be working as expected"
  echo ""
  echo "Expected behavior:"
  echo "  - Up to 10 successful requests"
  echo "  - Remaining requests should be rate limited (429)"
  echo ""
  echo "Actual results:"
  echo "  - $SUCCESS_COUNT successful"
  echo "  - $RATE_LIMITED_COUNT rate limited"
  exit 1
fi
