# DevSecOps Security Recommendations

## ConsentManager - Security Hardening Roadmap

**Assessment Date:** February 16, 2026  
**Based On:** OWASP Top 10:2025, GCP Best Practices, DevSecOps Pipeline Standards  
**Current Status:** 7/7 Critical/High findings remediated (see PENTEST_REPORT.md)

---

## Table of Contents

1. [OWASP Top 10:2025 Assessment](#owasp-top-10-2025-assessment)
2. [DDoS Protection Strategy](#ddos-protection-strategy)
3. [DevSecOps Pipeline Improvements](#devsecops-pipeline-improvements)
4. [Dependency Security](#dependency-security)
5. [Infrastructure Hardening](#infrastructure-hardening)
6. [Monitoring & Incident Response](#monitoring--incident-response)
7. [Implementation Priority Matrix](#implementation-priority-matrix)

---

## OWASP Top 10:2025 Assessment

### Current Status vs OWASP Top 10:2025

| # | OWASP Category | Status | Notes |
|---|---|---|---|
| **1** | **Broken Access Control** | ⚠️ PARTIAL | API key + domain whitelist implemented; needs rate limiting per IP |
| **2** | **Security Misconfiguration** | ⚠️ PARTIAL | Missing security headers (CSP, HSTS); Cloud Function allows unauthenticated access |
| **3** | **Software Supply Chain Failures** | ❌ NOT IMPLEMENTED | No SBOM, no dependency scanning, no automated vulnerability checks |
| **4** | **Cryptographic Failures** | ⚠️ PARTIAL | IP hashing uses SHA-256 but with weak salt management; no TLS cert pinning |
| **5** | **Injection** | ✅ REMEDIATED | SQL injection and XSS vulnerabilities fixed in PT-002, PT-003, PT-004 |
| **6** | **Insecure Design** | ⚠️ PARTIAL | API keys in client-side code (even if server-injected); no defense in depth |
| **7** | **Authentication Failures** | ⚠️ PARTIAL | API key auth implemented but no MFA, no session management, no brute-force protection |
| **8** | **Software/Data Integrity Failures** | ❌ NOT IMPLEMENTED | No Subresource Integrity (SRI), no CI/CD pipeline signing, no artifact verification |
| **9** | **Security Logging/Alerting Failures** | ⚠️ PARTIAL | BigQuery logging exists but no alerting, no anomaly detection, no SIEM integration |
| **10** | **Mishandling of Exceptional Conditions** | ⚠️ PARTIAL | Error messages leak internal details (PT-006 partially fixed); no structured error handling |

**Overall Score:** 1/10 fully compliant, 7/10 partially compliant, 2/10 not implemented

---

## DDoS Protection Strategy

### Current Vulnerabilities

| Attack Vector | Current State | Risk Level |
|---|---|---|
| **HTTP Flood on Cloud Function** | No rate limiting | HIGH |
| **Amplification via CDN** | No request throttling | MEDIUM |
| **API Key Exhaustion** | Monthly quota only, no per-second limit | MEDIUM |
| **Slowloris/Slow POST** | No timeout enforcement | LOW (GCP handles) |

### Recommended Protections

#### 1. Deploy Google Cloud Armor (Priority: HIGH)

**Implementation:**

```bash
# Create Cloud Armor security policy
gcloud compute security-policies create consent-manager-policy \
    --description "DDoS protection for ConsentManager"

# Add rate limiting rule (100 requests per minute per IP)
gcloud compute security-policies rules create 1000 \
    --security-policy consent-manager-policy \
    --expression "true" \
    --action "rate-based-ban" \
    --rate-limit-threshold-count 100 \
    --rate-limit-threshold-interval-sec 60 \
    --ban-duration-sec 600 \
    --conform-action "allow"

# Enable adaptive protection (ML-based DDoS detection)
gcloud compute security-policies update consent-manager-policy \
    --enable-layer7-ddos-defense \
    --layer7-ddos-defense-rule-visibility=STANDARD
```

**Deploy in front of Cloud Function via API Gateway or Cloud Load Balancer.**

**Cost:** ~$0.50/policy + $0.75/million requests (negligible for your traffic)

#### 2. Implement Per-IP Rate Limiting in Cloud Function

Add to `bigquery/cloud-function-auth/index.js`:

```javascript
const rateLimit = new Map(); // IP -> {count, resetTime}

function checkRateLimit(ip) {
  const now = Date.now();
  const limit = 10; // requests per window
  const window = 10000; // 10 seconds
  
  if (!rateLimit.has(ip)) {
    rateLimit.set(ip, {count: 1, resetTime: now + window});
    return true;
  }
  
  const record = rateLimit.get(ip);
  if (now > record.resetTime) {
    record.count = 1;
    record.resetTime = now + window;
    return true;
  }
  
  if (record.count >= limit) {
    return false; // Rate limit exceeded
  }
  
  record.count++;
  return true;
}

// In main handler:
const clientIP = req.headers['x-forwarded-for']?.split(',')[0]?.trim();
if (!checkRateLimit(clientIP)) {
  return res.status(429).json({error: 'Rate limit exceeded'});
}
```

#### 3. CDN-Level Protection

**Enable Cloud CDN with Cloud Armor:**

```bash
# Create backend bucket for Cloud Storage
gcloud compute backend-buckets create consent-manager-cdn \
    --gcs-bucket-name=consent-manager-cdn-tanapatj-jkt \
    --enable-cdn

# Attach Cloud Armor policy
gcloud compute backend-buckets update consent-manager-cdn \
    --security-policy=consent-manager-policy
```

#### 4. Set Request Size Limits

Add to Cloud Function:

```javascript
// Limit payload size to 10KB
if (req.headers['content-length'] > 10240) {
  return res.status(413).json({error: 'Payload too large'});
}
```

---

## DevSecOps Pipeline Improvements

### 1. Automated Security Scanning (Priority: CRITICAL)

#### A. Dependency Vulnerability Scanning

**Add to `.github/workflows/security.yml`:**

```yaml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run npm audit
        run: npm audit --audit-level=moderate
      
      - name: Snyk Security Scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
      
      - name: Generate SBOM
        run: |
          npm install -g @cyclonedx/cyclonedx-npm
          cyclonedx-npm --output-file sbom.json
      
      - name: Upload SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.json

  sast-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Semgrep SAST
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/owasp-top-ten
            p/javascript
      
      - name: ESLint Security Plugin
        run: |
          npm install eslint-plugin-security
          npx eslint --plugin security --rule 'security/*: error' src/

  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: TruffleHog Secret Scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
```

#### B. Container/Infrastructure Scanning

```yaml
  infrastructure-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Checkov IaC Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: bigquery/
          framework: terraform,cloudformation,kubernetes
```

### 2. Pre-Commit Hooks (Priority: HIGH)

**Install Husky + lint-staged:**

```bash
npm install --save-dev husky lint-staged
npx husky install
```

**Add to `package.json`:**

```json
{
  "lint-staged": {
    "*.js": [
      "eslint --fix --plugin security",
      "npm audit"
    ],
    "*.{json,md}": [
      "prettier --write"
    ]
  },
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged && npm run test",
      "pre-push": "npm audit --audit-level=high"
    }
  }
}
```

### 3. Signed Commits & Artifact Verification (Priority: MEDIUM)

**Enforce GPG signing:**

```bash
# Configure Git to require signed commits
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_GPG_KEY_ID

# GitHub branch protection: Require signed commits
```

**Sign build artifacts:**

```yaml
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        run: npm run build
      
      - name: Sign artifacts
        run: |
          gpg --armor --detach-sign dist/consent-manager.umd.js
          sha256sum dist/* > dist/checksums.txt
      
      - name: Generate provenance
        uses: actions/attest-build-provenance@v1
        with:
          subject-path: 'dist/*'
```

### 4. Dependency Pinning & Lock File Integrity

**Add to CI:**

```yaml
  - name: Verify lock file integrity
    run: |
      npm ci --ignore-scripts
      git diff --exit-code package-lock.json
```

**Use exact versions in `package.json`:**

```json
{
  "dependencies": {
    "@google-cloud/bigquery": "7.3.0",  // No ^ or ~
    "uuid": "9.0.1"
  }
}
```

---

## Dependency Security

### Current Dependencies Audit

Run this now:

```bash
cd /Users/dostanapat/Downloads/cookieconsent-master
npm audit
npm outdated
```

### Recommendations

#### 1. Automated Dependency Updates

**Add Dependabot config (`.github/dependabot.yml`):**

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "tanapatj"
    labels:
      - "dependencies"
      - "security"
    commit-message:
      prefix: "chore(deps)"
    
  - package-ecosystem: "npm"
    directory: "/bigquery/cloud-function-auth"
    schedule:
      interval: "weekly"
```

#### 2. Subresource Integrity (SRI) for CDN

**Add to all HTML files:**

```html
<!-- Generate hash: openssl dgst -sha384 -binary consent-manager.umd.js | openssl base64 -A -->
<script 
  src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"
  integrity="sha384-HASH_HERE"
  crossorigin="anonymous">
</script>
```

#### 3. npm Package Security

If you publish to npm, add:

```json
{
  "publishConfig": {
    "access": "public",
    "provenance": true
  }
}
```

---

## Infrastructure Hardening

### 1. Security Headers (Priority: HIGH)

**Add to all HTML pages via meta tags or Cloud Storage metadata:**

```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' https://storage.googleapis.com;
  style-src 'self' 'unsafe-inline';
  img-src 'self' data:;
  connect-src 'self' https://logconsentauth-pxoxh5sfqa-as.a.run.app;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
">
<meta http-equiv="X-Frame-Options" content="DENY">
<meta http-equiv="X-Content-Type-Options" content="nosniff">
<meta http-equiv="Referrer-Policy" content="strict-origin-when-cross-origin">
<meta http-equiv="Permissions-Policy" content="geolocation=(), microphone=(), camera=()">
```

**Or set via Cloud Storage bucket metadata:**

```bash
gsutil setmeta -h "x-goog-meta-x-frame-options:DENY" \
  -h "x-goog-meta-x-content-type-options:nosniff" \
  gs://consent-manager-cdn-tanapatj-jkt/**/*.html
```

### 2. Secrets Management (Priority: CRITICAL)

**Move IP_SALT to GCP Secret Manager:**

```bash
# Create secret
echo -n "$(openssl rand -hex 32)" | gcloud secrets create ip-hash-salt \
    --data-file=- \
    --replication-policy="automatic"

# Grant Cloud Function access
gcloud secrets add-iam-policy-binding ip-hash-salt \
    --member="serviceAccount:YOUR_FUNCTION_SA@PROJECT.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

**Update Cloud Function to read from Secret Manager:**

```javascript
const {SecretManagerServiceClient} = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();

async function getIPSalt() {
  const [version] = await client.accessSecretVersion({
    name: 'projects/PROJECT_ID/secrets/ip-hash-salt/versions/latest',
  });
  return version.payload.data.toString();
}

// Use in hashIP function
const salt = await getIPSalt();
```

### 3. API Gateway (Priority: HIGH)

Deploy Cloud Functions behind API Gateway for:
- Centralized authentication
- Rate limiting
- Request/response transformation
- API versioning
- Better monitoring

```bash
gcloud api-gateway api-configs create consent-logger-config \
    --api=consent-logger \
    --openapi-spec=openapi.yaml \
    --backend-auth-service-account=YOUR_SA@PROJECT.iam.gserviceaccount.com
```

### 4. Private Cloud Functions

Change Cloud Function to require authentication:

```bash
gcloud functions deploy logConsentAuth \
    --no-allow-unauthenticated \
    --ingress-settings=internal-and-gclb
```

Then use API Gateway or Cloud Load Balancer as the public entry point.

---

## Monitoring & Incident Response

### 1. Security Logging (Priority: HIGH)

**Enable Cloud Audit Logs:**

```bash
gcloud logging sinks create consent-security-logs \
    bigquery.googleapis.com/projects/PROJECT_ID/datasets/security_logs \
    --log-filter='
      resource.type="cloud_function"
      OR resource.type="gcs_bucket"
      OR protoPayload.authenticationInfo.principalEmail!=""
    '
```

**Log security events in Cloud Function:**

```javascript
const {Logging} = require('@google-cloud/logging');
const logging = new Logging();
const log = logging.log('consent-security');

function logSecurityEvent(event, severity, metadata) {
  const entry = log.entry({
    severity: severity,
    resource: {type: 'cloud_function'},
  }, {
    event: event,
    timestamp: new Date().toISOString(),
    ...metadata
  });
  
  log.write(entry);
}

// Usage:
if (!validation.valid) {
  logSecurityEvent('AUTH_FAILURE', 'WARNING', {
    apiKey: apiKey.substring(0, 8) + '...',
    origin: origin,
    reason: validation.error,
    ip: clientIP
  });
}
```

### 2. Alerting (Priority: HIGH)

**Create alert policies in GCP:**

```bash
# Alert on high rate of 401 errors
gcloud alpha monitoring policies create \
    --notification-channels=YOUR_CHANNEL_ID \
    --display-name="High Auth Failure Rate" \
    --condition-display-name="401 rate > 100/min" \
    --condition-threshold-value=100 \
    --condition-threshold-duration=60s
```

**Alert on anomalies:**

```bash
# Alert on unusual traffic patterns
gcloud alpha monitoring policies create \
    --notification-channels=YOUR_CHANNEL_ID \
    --display-name="Unusual Traffic Volume" \
    --condition-anomaly-detection
```

### 3. SIEM Integration (Priority: MEDIUM)

Export logs to a SIEM (Splunk, Elastic, Chronicle):

```bash
gcloud logging sinks create siem-export \
    pubsub.googleapis.com/projects/PROJECT_ID/topics/security-events \
    --log-filter='severity>=WARNING'
```

### 4. Incident Response Runbook

Create `INCIDENT_RESPONSE.md`:

```markdown
## Incident Response Procedures

### DDoS Attack
1. Enable Cloud Armor adaptive protection
2. Lower rate limits temporarily
3. Review logs for attack patterns
4. Block malicious IPs via Cloud Armor rules

### API Key Compromise
1. Disable compromised key in BigQuery: `UPDATE api_keys SET is_active=FALSE WHERE api_key='...'`
2. Notify affected client
3. Generate new key
4. Review logs for unauthorized usage

### Data Breach
1. Isolate affected systems
2. Preserve logs and evidence
3. Notify security team and legal
4. Follow GDPR breach notification (72 hours)
```

---

## Implementation Priority Matrix

### Phase 1: Immediate (Week 1-2) - CRITICAL

| Task | Effort | Impact | Owner |
|---|---|---|---|
| Deploy Cloud Armor with rate limiting | Medium | High | DevOps |
| Add security headers to all HTML | Low | Medium | Frontend |
| Set up GitHub Actions security scanning | Medium | High | DevOps |
| Move IP_SALT to Secret Manager | Low | High | Backend |
| Implement per-IP rate limiting in Cloud Function | Medium | High | Backend |
| Add SRI hashes to CDN scripts | Low | Medium | Frontend |

### Phase 2: Short-term (Month 1) - HIGH

| Task | Effort | Impact | Owner |
|---|---|---|---|
| Deploy API Gateway in front of Cloud Function | High | High | DevOps |
| Set up Dependabot for automated updates | Low | Medium | DevOps |
| Configure Cloud Audit Logs and alerting | Medium | High | DevOps |
| Implement structured security logging | Medium | Medium | Backend |
| Add pre-commit hooks (Husky) | Low | Medium | DevOps |
| Create incident response runbook | Low | High | Security |

### Phase 3: Medium-term (Month 2-3) - MEDIUM

| Task | Effort | Impact | Owner |
|---|---|---|---|
| Integrate with SIEM | High | Medium | DevOps |
| Implement signed commits enforcement | Low | Medium | DevOps |
| Deploy private Cloud Functions + Load Balancer | High | Medium | DevOps |
| Add artifact signing to CI/CD | Medium | Medium | DevOps |
| Implement TLS certificate pinning | Medium | Low | Backend |
| Set up automated penetration testing | High | High | Security |

### Phase 4: Long-term (Ongoing) - MAINTENANCE

| Task | Frequency | Owner |
|---|---|---|
| Review and rotate API keys | Quarterly | Security |
| Update dependencies | Weekly (automated) | DevOps |
| Security audit | Annually | Security |
| Penetration testing | Bi-annually | External |
| Review access logs for anomalies | Weekly | Security |
| Update threat model | Quarterly | Security |

---

## Cost Impact

| Security Measure | Monthly Cost | Annual Cost |
|---|---|---|
| Cloud Armor (1 policy + 15M requests) | ~$1.25 | ~$15 |
| API Gateway | ~$0.50 | ~$6 |
| Secret Manager (1 secret) | $0.06 | $0.72 |
| Cloud Audit Logs (moderate volume) | ~$0.50 | ~$6 |
| Snyk/Dependabot | $0 (free tier) | $0 |
| GitHub Actions (2000 min/month) | $0 (free tier) | $0 |
| **Total Additional Cost** | **~$2.31/month** | **~$28/year** |

**Current budget:** 5,000 THB/month (~$140)  
**Current usage:** 39 THB/month (~$1)  
**After security hardening:** ~42 THB/month (~$3.31)  
**Still 99% under budget** ✅

---

## Compliance Impact

| Regulation | Current Status | After Implementation |
|---|---|---|
| **GDPR** | Partial | Full compliance |
| **Thailand PDPA** | Partial | Full compliance |
| **ISO 27001** | Not assessed | Aligned |
| **SOC 2 Type II** | Not applicable | Ready for audit |
| **PCI DSS** (if applicable) | Not compliant | Closer to compliance |

---

## Next Steps

1. **Review this document** with security and DevOps teams
2. **Prioritize Phase 1 tasks** and assign owners
3. **Set up GitHub Actions** security scanning this week
4. **Deploy Cloud Armor** for DDoS protection
5. **Schedule monthly security review meetings**

---

## References

- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)
- [Google Cloud Armor Best Practices](https://cloud.google.com/armor/docs/best-practices)
- [OWASP CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
- [Node.js Security Best Practices 2026](https://thedecipherist.com/articles/nodejs-backend-best-practices/)
- [GitHub Supply Chain Security](https://docs.github.com/en/code-security/supply-chain-security)

---

**Document Version:** 1.0  
**Last Updated:** February 16, 2026  
**Next Review:** May 16, 2026
