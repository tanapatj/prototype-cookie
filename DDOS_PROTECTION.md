# DDoS Protection Implementation

This document describes the multi-layered DDoS protection strategy implemented for ConsentManager.

## 🛡️ Protection Layers

### Layer 1: Application-Level Protection (✅ Implemented)

#### Per-IP Rate Limiting
- **Authenticated Endpoints**: 10 requests per 10 seconds per IP
- **Unauthenticated Endpoints**: 5 requests per 10 seconds per IP (stricter)
- **Ban Duration**: Temporary (sliding window)
- **Implementation**: In-memory store with automatic cleanup

```javascript
// Example from cloud-function-auth/index.js
const RATE_LIMIT_WINDOW = 10000; // 10 seconds
const RATE_LIMIT_MAX_REQUESTS = 10; // 10 requests per IP
```

#### Request Size Limits
- **Max Request Size**: 50KB (51,200 bytes)
- **Enforcement**: Before authentication and processing
- **Response**: HTTP 413 Payload Too Large

#### Content-Type Validation
- **Required**: `application/json`
- **Response**: HTTP 415 Unsupported Media Type if invalid

#### Timeout Protection
- **BigQuery Insert Timeout**: 5 seconds max
- **Implementation**: `Promise.race()` with timeout promise
- **Response**: HTTP 504 Gateway Timeout if exceeded

#### Enhanced Error Handling
- **Production Mode**: Generic error messages (no internal details leaked)
- **Development Mode**: Detailed error messages for debugging
- **Logging**: All errors logged with timestamps and client IP

### Layer 2: Infrastructure-Level Protection (🟡 Ready to Deploy)

#### Google Cloud Armor
Comprehensive WAF and DDoS protection at the network edge.

**Features:**
- **Rate Limiting**: 100 requests/minute per IP (Layer 7)
- **Ban Duration**: 10 minutes for rate limit violations
- **SQL Injection Protection**: OWASP ModSecurity Core Rule Set
- **XSS Protection**: OWASP XSS rules
- **Adaptive Protection**: ML-based DDoS detection
- **Geo-blocking**: Optional country-level blocking

**Deployment:**
```bash
cd bigquery
bash deploy-cloud-armor.sh
bash deploy-load-balancer.sh
```

**Cost:** ~$1.50/month for Cloud Armor + ~$18/month for Load Balancer

#### Architecture with Cloud Armor

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│  Cloud Armor     │ ◄── DDoS Protection
│  (WAF + Rate     │     - Rate limiting
│   Limiting)      │     - SQL injection
└──────┬───────────┘     - XSS protection
       │                  - Adaptive ML
       ▼
┌──────────────────┐
│ Cloud Load       │
│ Balancer         │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Serverless NEG   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Cloud Functions  │ ◄── Application-level
│                  │     rate limiting
└──────────────────┘
       │
       ▼
┌──────────────────┐
│    BigQuery      │
└──────────────────┘
```

## 📊 Protection Effectiveness

### Application-Level (Current)

| Attack Type | Protected | Details |
|-------------|-----------|---------|
| Volume-based flooding | ✅ Yes | Per-IP rate limiting prevents single-IP floods |
| Slowloris | ✅ Yes | Timeout protection (5s max) |
| Large payload attacks | ✅ Yes | 50KB request size limit |
| Application-layer (Layer 7) | ✅ Yes | Rate limiting + validation |
| Protocol-based (Layer 3-4) | ❌ No | Requires Cloud Armor |
| Distributed attacks (multiple IPs) | 🟡 Partial | Each IP individually rate-limited |

### Infrastructure-Level (with Cloud Armor)

| Attack Type | Protected | Details |
|-------------|-----------|---------|
| Volume-based flooding | ✅ Yes | Edge protection before reaching functions |
| Distributed attacks | ✅ Yes | ML-based detection across all sources |
| Protocol-based (SYN flood, etc.) | ✅ Yes | Network-level protection |
| Application-layer (Layer 7) | ✅ Yes | Combined with app-level limits |
| Botnets | ✅ Yes | Adaptive ML identifies patterns |
| SQL injection attempts | ✅ Yes | WAF rules block malicious payloads |
| XSS attempts | ✅ Yes | WAF rules sanitize inputs |

## 🚀 Deployment Options

### Option 1: Application-Level Only (Current)
**Status:** ✅ Already Deployed
**Cost:** $0/month (included in Cloud Functions pricing)
**Protection:** Good for small-medium attacks, single-IP floods
**Limitation:** Vulnerable to large distributed attacks

### Option 2: Application + Cloud Armor (Recommended)
**Status:** 🟡 Ready to deploy
**Cost:** ~$20/month additional
**Protection:** Enterprise-grade DDoS protection
**Best for:** Production environments, high-value targets

**Steps to deploy:**
1. Run `deploy-cloud-armor.sh` to create security policies
2. Run `deploy-load-balancer.sh` to set up load balancer
3. Create SSL certificate for your domain
4. Update DNS to point to load balancer IP

## 📈 Monitoring & Alerting

### Current Monitoring
- **Logs**: All rate limit violations logged to Cloud Logging
- **Metrics**: Available in GCP Console → Cloud Functions → Metrics

### Recommended Alerts (Set up in GCP)
1. **High Error Rate**: Alert if 4xx/5xx errors exceed 10% over 5 minutes
2. **Rate Limit Violations**: Alert if 429 responses exceed 100/minute
3. **Function Timeout**: Alert if 504 responses exceed 5/minute
4. **Unusual Traffic**: Alert if request volume increases 300% over baseline

### Example Alert Query (Cloud Logging)
```
resource.type="cloud_function"
severity>=WARNING
jsonPayload.message=~"Rate limit exceeded"
```

## 🧪 Testing DDoS Protection

### Test Application-Level Rate Limiting

```bash
# Test rate limiting (should get 429 after 10 requests)
for i in {1..15}; do
  curl -X POST https://YOUR-FUNCTION-URL \
    -H "Content-Type: application/json" \
    -H "X-API-Key: your-api-key" \
    -d '{"event_type":"consent_given","cookie":{"categories":["necessary"]}}' \
    -w "\nStatus: %{http_code}\n"
  sleep 0.5
done
```

Expected output:
- First 10 requests: `200 OK`
- Requests 11-15: `429 Too many requests`

### Test Request Size Limit

```bash
# Generate a large payload (>50KB)
python3 << EOF
import json
import requests

large_data = {
    "event_type": "consent_given",
    "cookie": {"categories": ["necessary"]},
    "dummy": "x" * 60000  # 60KB of data
}

response = requests.post(
    "https://YOUR-FUNCTION-URL",
    json=large_data,
    headers={"X-API-Key": "your-api-key"}
)

print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
EOF
```

Expected output: `413 Payload too large`

### Test Timeout Protection

```bash
# This would require simulating a slow BigQuery insert
# Typically tested with a load testing tool like Apache Bench or k6
```

## 📝 Best Practices

### Current Implementation
1. ✅ Rate limiting on all endpoints
2. ✅ Request size validation
3. ✅ Content-Type validation
4. ✅ Timeout protection
5. ✅ Enhanced error handling
6. ✅ IP extraction from proxy headers

### Recommended Enhancements
1. 🟡 Deploy Cloud Armor for infrastructure-level protection
2. ⚪ Implement request logging with anomaly detection
3. ⚪ Add CAPTCHA for suspicious traffic patterns
4. ⚪ Set up automated response playbooks for attacks
5. ⚪ Implement IP reputation checking (e.g., Project Shield)
6. ⚪ Add WebSocket rate limiting (if using real-time features)

## 🔧 Configuration

### Adjusting Rate Limits

**Authenticated endpoints** (`cloud-function-auth/index.js`):
```javascript
const RATE_LIMIT_WINDOW = 10000;        // Time window in ms
const RATE_LIMIT_MAX_REQUESTS = 10;     // Max requests per window
```

**Unauthenticated endpoints** (`cloud-function/index.js`):
```javascript
const RATE_LIMIT_WINDOW = 10000;        // Time window in ms
const RATE_LIMIT_MAX_REQUESTS = 5;      // Max requests per window (stricter)
```

### Adjusting Request Size Limit
```javascript
// In both cloud function files
const contentLength = parseInt(req.headers['content-length'] || '0', 10);
if (contentLength > 51200) {  // 50KB = 51200 bytes
```

### Adjusting Timeout
```javascript
// In both cloud function files
const timeoutPromise = new Promise((_, reject) =>
  setTimeout(() => reject(new Error('BigQuery insert timeout')), 5000)  // 5 seconds
);
```

## 💰 Cost Analysis

### Application-Level Protection
- **Cost**: $0/month (included in Cloud Functions)
- **Overhead**: ~1-2ms per request for rate limit check
- **Memory**: Minimal (in-memory store cleans up periodically)

### Cloud Armor Protection
- **Security Policy**: $0.50/month per policy
- **Rules**: $0.10/month per rule (we use 4 rules = $0.40)
- **Request Processing**: $0.60 per million requests
- **Cloud Load Balancer**: $18/month base + data processing
- **Total**: ~$20-25/month for small-medium traffic

### At Scale (Example: 1M requests/month)
- Application-level: $0 additional
- Cloud Armor: $20 (base) + $0.60 (processing) = ~$21/month
- **Protection Value**: Preventing a DDoS attack that could cost thousands in downtime/recovery

## 🆘 Incident Response

### If Under Attack

1. **Check Logs**
   ```bash
   gcloud logging read "resource.type=cloud_function AND severity>=WARNING" \
     --limit 50 \
     --format json
   ```

2. **Identify Attack Pattern**
   - Single IP? → Already rate-limited
   - Multiple IPs? → Deploy Cloud Armor immediately
   - Specific endpoint? → Consider disabling temporarily

3. **Emergency Measures**
   - **Immediate**: Lower rate limits in code and redeploy
   - **Quick**: Enable geo-blocking in Cloud Armor
   - **Nuclear**: Add IP allowlist, deny all others

4. **Post-Incident**
   - Review logs for attack signatures
   - Update rate limits if needed
   - Consider CDN (Cloudflare) for additional protection
   - File abuse report with originating ISPs

## 📚 Additional Resources

- [Google Cloud Armor Documentation](https://cloud.google.com/armor/docs)
- [Cloud Functions Security Best Practices](https://cloud.google.com/functions/docs/securing)
- [DDoS Protection Best Practices (GCP)](https://cloud.google.com/architecture/ddos-protection-best-practices)
- [OWASP DDoS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html)

---

**Status**: Application-level protection fully implemented ✅  
**Last Updated**: 2026-02-16  
**Next Review**: Before scaling to 100K+ requests/day
