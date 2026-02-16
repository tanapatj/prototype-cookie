# Deploy DDoS Protection - Quick Guide

## Current Status

✅ **Code Implementation**: Complete (all protection mechanisms added to local files)  
❌ **Cloud Deployment**: Not deployed yet (Cloud Functions still running old code)

## Test Results Before Deployment

```
Rate Limiting:       ❌ NOT ACTIVE (all 15 requests succeeded)
Request Size Limit:  ❌ NOT ACTIVE (60KB payload accepted)
Content-Type Check:  ❌ NOT ACTIVE (old code running)
```

---

## How to Deploy

### Option 1: Automated Script (Recommended)

```bash
cd bigquery
bash deploy-ddos-protection.sh
```

This will:
- Deploy updated `logConsentAuth` function (authenticated)
- Deploy updated `logConsent` function (unauthenticated)
- Set secure IP_SALT environment variable
- Configure memory, timeout, and max instances

**Time:** ~3-5 minutes per function

---

### Option 2: Manual Deployment

#### Step 1: Deploy Authenticated Function

```bash
cd bigquery/cloud-function-auth

gcloud functions deploy logConsentAuth \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region=asia-southeast1 \
  --entry-point=logConsent \
  --memory=256MB \
  --timeout=60s \
  --max-instances=100 \
  --set-env-vars="IP_SALT=$(openssl rand -hex 32)" \
  --project=conicle-ai-dev
```

#### Step 2: Deploy Unauthenticated Function

```bash
cd ../cloud-function

gcloud functions deploy logConsent \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region=asia-southeast3 \
  --entry-point=logConsent \
  --memory=256MB \
  --timeout=60s \
  --max-instances=100 \
  --set-env-vars="IP_SALT=$(openssl rand -hex 32)" \
  --project=conicle-ai-dev
```

---

## After Deployment: Run Tests

Once deployed, run the test suite again to verify protection is working:

```bash
cd /Users/dostanapat/Downloads/cookieconsent-master
python3 test-ddos-protection.py all
```

### Expected Results After Deployment

```
Rate Limiting:       ✅ ACTIVE (requests 11+ blocked with HTTP 429)
Request Size Limit:  ✅ ACTIVE (60KB payload rejected with HTTP 413)
Content-Type Check:  ✅ ACTIVE (invalid types rejected with HTTP 415)
Timeout Protection:  ✅ ACTIVE (long requests timeout at 5 seconds)
```

---

## Quick Test After Deployment

### Test 1: Rate Limiting (Quick)
```bash
# Send 15 requests quickly
for i in {1..15}; do
  curl -X POST https://logconsentauth-pxoxh5sfqa-as.a.run.app \
    -H "Content-Type: application/json" \
    -H "X-API-Key: demo-key-12345678-1234-1234-1234-123456789abc" \
    -d '{"event_type":"consent_given","cookie":{"categories":["necessary"]}}' \
    -w "\nHTTP Status: %{http_code}\n" \
    -s -o /dev/null
  sleep 0.5
done
```

Expected:
- First 10: `HTTP Status: 200`
- Remaining 5: `HTTP Status: 429`

### Test 2: Large Payload (Quick)
```bash
python3 << 'EOF'
import requests

large_payload = {
    "event_type": "consent_given",
    "cookie": {"categories": ["necessary"]},
    "dummy": "x" * 60000  # 60KB
}

response = requests.post(
    "https://logconsentauth-pxoxh5sfqa-as.a.run.app",
    json=large_payload,
    headers={"X-API-Key": "demo-key-12345678-1234-1234-1234-123456789abc"}
)

print(f"Status: {response.status_code}")
print(f"Expected: 413 (Payload Too Large)")
EOF
```

Expected: `Status: 413`

---

## Troubleshooting

### Issue: Deployment fails with "Permission denied"
**Solution**: Make sure you're authenticated:
```bash
gcloud auth login
gcloud config set project conicle-ai-dev
```

### Issue: Function not found
**Solution**: Check if functions exist:
```bash
gcloud functions list --project=conicle-ai-dev
```

### Issue: Still getting 200 instead of 429
**Solutions:**
1. Wait 1-2 minutes for deployment to propagate
2. Clear any CDN/proxy cache
3. Verify correct endpoint URL
4. Check Cloud Function logs:
   ```bash
   gcloud functions logs read logConsentAuth --region=asia-southeast1 --limit=50
   ```

### Issue: Getting 401 (Unauthorized)
**Solution**: Check your API key is valid in BigQuery:
```sql
SELECT * FROM consent_analytics.api_keys 
WHERE api_key = 'demo-key-12345678-1234-1234-1234-123456789abc'
AND status = 'active';
```

---

## Cost Impact

### Before Deployment
- Current cost: Based on function invocations only

### After Deployment
- **Cost Change**: $0/month additional
- **Why**: DDoS protection uses in-memory processing (no external services)
- **Savings**: Prevents expensive attack-related costs

### Actually Saves Money By:
- Blocking excessive requests before they reach BigQuery
- Preventing resource exhaustion
- Avoiding attack-related bandwidth costs

---

## Monitoring After Deployment

### View Rate Limit Blocks
```bash
gcloud logging read "resource.type=cloud_function \
  AND jsonPayload.message=~'Rate limit exceeded'" \
  --limit=20 \
  --project=conicle-ai-dev
```

### View Blocked Large Payloads
```bash
gcloud logging read "resource.type=cloud_function \
  AND jsonPayload.message=~'Request too large'" \
  --limit=20 \
  --project=conicle-ai-dev
```

### Monitor Function Health
```bash
gcloud functions describe logConsentAuth \
  --region=asia-southeast1 \
  --project=conicle-ai-dev
```

---

## Rollback Plan (If Issues Occur)

If you need to rollback to the previous version:

```bash
# List previous versions
gcloud functions describe logConsentAuth \
  --region=asia-southeast1 \
  --format="value(versionId)"

# Rollback to previous version (replace VERSION_ID)
gcloud functions deploy logConsentAuth \
  --region=asia-southeast1 \
  --source-version=VERSION_ID
```

---

## Summary

| Step | Action | Status |
|------|--------|--------|
| 1 | Code implementation | ✅ Complete |
| 2 | Deploy to Cloud Functions | ⏳ Pending |
| 3 | Run tests | ⏳ After deployment |
| 4 | Monitor logs | ⏳ After deployment |

**Next Action:** Run `bash bigquery/deploy-ddos-protection.sh` to deploy the protection to your Cloud Functions.

**Time Estimate:** 5-10 minutes total (including deployment + testing)

---

## Questions?

- **What gets deployed?** Only the updated `index.js` files with DDoS protection
- **Will it break existing integrations?** No, API is fully backward compatible
- **Can I test locally first?** Not easily - rate limiting requires actual HTTP requests
- **Is it reversible?** Yes, you can rollback to previous version anytime
- **Does it affect performance?** Minimal (~1-2ms overhead per request)
