# Security Discussion & Comprehensive Risk Analysis
## ConsentManager Platform

**Date:** February 16, 2026  
**Classification:** Internal Security Review  
**Reviewer:** Security Analysis Team

---

## Table of Contents

1. [Architecture & Data Flow Analysis](#1-architecture--data-flow-analysis)
2. [Threat Model](#2-threat-model)
3. [Comprehensive Security Findings](#3-comprehensive-security-findings)
4. [Risk Assessment & Impact Analysis](#4-risk-assessment--impact-analysis)
5. [Prioritization Matrix](#5-prioritization-matrix)
6. [Remediation Roadmap](#6-remediation-roadmap)

---

## 1. Architecture & Data Flow Analysis

### 1.1 System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                             │
│  ┌────────────────┐    ┌──────────────┐   ┌─────────────────┐  │
│  │ Demo Site      │    │ Admin Portal │   │ Customer Portal │  │
│  │ (index.html)   │    │ (HTML/JS)    │   │ (HTML/JS)       │  │
│  └────────┬───────┘    └──────┬───────┘   └────────┬────────┘  │
│           │ Hardcoded         │ No Auth           │ No Backend  │
│           │ API Key           │ SQL Injection     │ Client-only │
└───────────┼───────────────────┼───────────────────┼─────────────┘
            │                   │                   │
            ↓                   ↓                   ↓
┌───────────────────────────────────────────────────────────────────┐
│                    GCP CLOUD STORAGE (CDN)                         │
│  • consent-manager.js (v1.0.0)                                     │
│  • consent-manager.css                                             │
│  • demo/admin/customer portal HTML files                           │
│  📍 Region: asia-southeast3 (Bangkok)                              │
│  ⚠️  Public read access (required for CDN)                         │
└───────────────────────────────────────────────────────────────────┘
            │
            ↓ (POST with X-API-Key header)
┌───────────────────────────────────────────────────────────────────┐
│                    CLOUD FUNCTIONS                                 │
│  ┌────────────────────────────┬──────────────────────────────┐   │
│  │ logConsentAuth             │ logConsent                   │   │
│  │ (Authenticated)            │ (Unauthenticated, DEPRECATED)│   │
│  │ asia-southeast1            │ asia-southeast2              │   │
│  │                            │                              │   │
│  │ • API Key validation       │ • CORS restricted            │   │
│  │ • Domain whitelist check   │ • Rate limiting (5 req/10s)  │   │
│  │ • Rate limiting (10/10s)   │ • Request size limit (50KB)  │   │
│  │ • Request size limit       │                              │   │
│  │ • Content-Type validation  │                              │   │
│  │ • Timeout protection (5s)  │                              │   │
│  │ • IP hashing (SHA-256)     │                              │   │
│  └────────────┬───────────────┴──────────────┬───────────────┘   │
│               │                               │                    │
└───────────────┼───────────────────────────────┼────────────────────┘
                │                               │
                ↓                               ↓
┌───────────────────────────────────────────────────────────────────┐
│                         BIGQUERY                                   │
│  Dataset: consent_analytics                                        │
│  ┌──────────────────────┬────────────────────────────────────┐   │
│  │ consent_events       │ api_keys                           │   │
│  │ (37 columns)         │ (API keys + domain whitelist)      │   │
│  │ • Partitioned by day │ • Plain-text API keys stored       │   │
│  │ • IP address + hash  │ • Monthly quota tracking           │   │
│  │ • User agent data    │ • Domain whitelist (regex)         │   │
│  │ • UTM parameters     │                                    │   │
│  │ • Consent choices    │                                    │   │
│  └──────────────────────┴────────────────────────────────────┘   │
│  📍 Region: asia-southeast3                                        │
│  🔒 Access: GCP Service Account only                               │
└───────────────────────────────────────────────────────────────────┘
```

### 1.2 Data Flow Scenarios

#### Scenario A: User Visits Website with ConsentManager

```
1. Browser → GCS CDN: Load consent-manager.js + CSS
2. Browser: Display consent modal
3. User: Clicks "Accept All"
4. Browser → Cloud Function (Auth): POST with X-API-Key header
   {
     "event_type": "consent",
     "cookie": {"categories": ["necessary", "analytics", "marketing"]},
     "pageUrl": "https://example.com",
     "acceptType": "all"
   }
5. Cloud Function: Validate API key → Check domain whitelist → Insert BigQuery
6. Cloud Function → Browser: 200 OK
```

**Security Issues in This Flow:**
- ⚠️ API key sent from browser (exposed in Network tab)
- ⚠️ No TLS certificate pinning (MITM possible)
- ⚠️ IP address logged (privacy concern)
- ⚠️ User-Agent fingerprinting (tracking)

#### Scenario B: Admin Generates API Key

```
1. Admin opens admin-portal/index.html (from GCS CDN or locally)
2. Admin fills form: client name, domains, email, quota
3. Browser generates UUID using Math.random()
4. Browser displays SQL INSERT statement
5. Admin manually copies SQL and runs in BigQuery console
6. BigQuery: Insert into api_keys table (plain-text API key)
```

**Security Issues in This Flow:**
- 🔴 CRITICAL: Admin portal has SQL injection vulnerability
- 🔴 CRITICAL: No authentication on admin portal (anyone can access)
- 🟠 HIGH: Weak random number generation (Math.random())
- 🟠 HIGH: API keys stored in plain-text in BigQuery
- 🟡 MEDIUM: Manual SQL execution (human error risk)
- 🟡 MEDIUM: No audit logging of who generated keys

#### Scenario C: Customer Registers Domain

```
1. Customer opens customer-portal/index.html
2. Customer fills form: company name, domain, email
3. Browser generates request ID (Math.random())
4. Browser displays "Request submitted" (fake, no backend)
5. Data is lost (not sent anywhere)
```

**Security Issues in This Flow:**
- 🟡 MEDIUM: No actual backend (misleading UX)
- 🟡 MEDIUM: No email notification to admin
- 🟢 LOW: Request ID collision possible
- ℹ️ INFO: False sense of security for customers

---

## 2. Threat Model

### 2.1 Threat Actors

| Actor | Motivation | Capability | Target |
|-------|------------|------------|--------|
| **Malicious Website Owner** | Pollute analytics, exhaust quota | Low-Medium | API key extraction from demo site |
| **Competitor/Pentester** | Intelligence gathering, sabotage | Medium-High | Admin portal SQL injection, API abuse |
| **Script Kiddie** | Mischief, defacement | Low | XSS in portals, DDoS on Cloud Functions |
| **Insider Threat** | Data exfiltration, sabotage | High | Direct BigQuery access, API key generation |
| **Privacy Regulator (PDPA/GDPR)** | Compliance enforcement | High | IP logging, data retention, consent validity |
| **Ransomware Group** | Financial extortion | High | Data destruction via SQL injection |

### 2.2 Attack Scenarios

#### Attack 1: API Key Extraction & Quota Exhaustion

```
Attacker → View demo site source code → Extract API key
Attacker → Script: Send 1M fake consent events via Cloud Function
Result: Quota exhausted, legitimate customers denied service
CVSS: 7.5 (HIGH) - Availability Impact
```

#### Attack 2: Admin Portal Takeover

```
Attacker → Access admin-portal/index.html (no auth)
Attacker → Inject SQL in "Client Name": '); DROP TABLE api_keys; --
Admin → Copies SQL → Runs in BigQuery
Result: All API keys deleted, system unavailable
CVSS: 9.1 (CRITICAL) - Integrity + Availability Impact
```

#### Attack 3: CORS Bypass & Data Injection

```
Attacker → Create malicious site: evil.com
Attacker → evil.com sends POST to logConsentAuth with stolen API key
Cloud Function → Validates API key ✓ (key is valid)
Cloud Function → Checks domain whitelist (evil.com not in list) ✗
Result: Request blocked (BUT: CORS preflight exposes API existence)
CVSS: 5.3 (MEDIUM) - Information Disclosure
```

#### Attack 4: Cryptographic Weakness Exploitation

```
Attacker → Observes API key format: cm_xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
Attacker → Reverse-engineers Math.random() seed (time-based)
Attacker → Generates candidate keys
Attacker → Brute-forces against Cloud Function (rate limit: 10/10s)
Result: 10 attempts per 10s = 86,400 attempts/day = possible key discovery
CVSS: 6.5 (MEDIUM) - Cryptanalysis Feasibility
```

#### Attack 5: Privacy Violation (PDPA Non-Compliance)

```
User → Gives consent on website
Cloud Function → Logs raw IP address to BigQuery
Regulator → Audits BigQuery: Finds IP + User-Agent + Geolocation
Regulator → Issues fine: IP is personally identifiable information
Result: 100M THB fine (4% of revenue), reputational damage
CVSS: 7.0 (HIGH) - Regulatory + Business Impact
```

---

## 3. Comprehensive Security Findings

### 3.1 From Previous Pentest (Status Update)

| ID | Severity | Issue | Status | Notes |
|----|----------|-------|--------|-------|
| PT-001 | 🔴 CRITICAL | API Key Hardcoded in Demo Site | **OPEN** | Still in demo-live/index.html |
| PT-002 | 🔴 CRITICAL | SQL Injection in Admin Portal | **OPEN** | String concatenation, no sanitization |
| PT-003 | 🟠 HIGH | XSS via innerHTML in Demo Site | **OPEN** | Event logger uses unsanitized data |
| PT-004 | 🟠 HIGH | XSS in Admin Portal | **OPEN** | API key display, client list |
| PT-005 | 🟠 HIGH | Open CORS on Unauthenticated Function | **REMEDIATED** | Restricted to known domains |
| PT-006 | 🟠 HIGH | CORS Before Auth Check | **REMEDIATED** | Now validates before CORS |
| PT-007 | 🟠 HIGH | IP Hashing Bug (Operator Precedence) | **REMEDIATED** | Fixed to: `ip + (salt \|\| 'default')` |
| PT-008 | 🟡 MEDIUM | Weak Random (Math.random() for API keys) | **OPEN** | Should use crypto.randomBytes() |
| PT-009 | 🟡 MEDIUM | API Key in Request Body Accepted | **OPEN** | Header-only enforcement missing |
| PT-010 | 🟡 MEDIUM | Hardcoded IP Salt | **PARTIAL** | Now uses env var, but fallback weak |
| PT-011 | 🟡 MEDIUM | ReDoS in Domain Regex | **OPEN** | Wildcard `.*` can be exploited |
| PT-012 | 🟡 MEDIUM | --allow-unauthenticated Flag | **ACCEPTED** | Required for public API |
| PT-013 | 🟡 MEDIUM | Script Injection via loadScript | **OPEN** | Selector-based exploit possible |
| PT-014 | 🟢 LOW | Missing Security Headers | **OPEN** | No CSP, X-Frame-Options, etc. |
| PT-015 | 🟢 LOW | Cloud Function URL Exposed | **ACCEPTED** | Public endpoint by design |
| PT-016 | 🟢 LOW | No Rate Limiting (Unauthenticated) | **REMEDIATED** | Now 5 req/10s per IP |
| PT-017 | ℹ️ INFO | Customer Portal Has No Backend | **OPEN** | Misleading UX |
| PT-018 | ℹ️ INFO | Debug Logging in Production | **OPEN** | Console.log() everywhere |
| PT-019 | ℹ️ INFO | Raw IP Logging by Default | **OPEN** | Privacy concern for PDPA |

**Summary:**
- **Open Critical:** 2
- **Open High:** 2
- **Open Medium:** 5
- **Open Low:** 2
- **Total Open:** 11

### 3.2 NEW Security Issues Discovered

#### NEW-001: No Authentication on Admin Portal

| Field | Detail |
|-------|--------|
| **Severity** | 🔴 **CRITICAL** |
| **CVSS 3.1** | 9.3 (Critical) |
| **CWE** | CWE-306: Missing Authentication |
| **Component** | `admin-portal/index.html` |

**Description:**

The Admin Portal is hosted on public GCS CDN with no authentication whatsoever. Anyone with the URL can:
- Generate API keys
- View SQL commands with sensitive configuration
- Access quota and usage information

**Impact:**
- Unauthorized API key generation
- Quota exhaustion attacks
- Competitive intelligence gathering
- Preparation for SQL injection attacks

**Remediation:**
1. Move admin portal behind Google Identity-Aware Proxy (IAP)
2. Implement OAuth 2.0 authentication
3. Add RBAC: only designated admins can generate keys
4. Log all admin actions to Cloud Audit Logs

**CVSS Vector:** `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`

---

#### NEW-002: API Keys Stored in Plain-Text in BigQuery

| Field | Detail |
|-------|--------|
| **Severity** | 🔴 **CRITICAL** |
| **CVSS 3.1** | 8.2 (High) |
| **CWE** | CWE-257: Storing Passwords in a Recoverable Format |
| **Component** | `bigquery/api-keys-schema.sql`, `cloud-function-auth/index.js` |

**Description:**

The `api_keys` table stores API keys in plain-text:

```sql
CREATE TABLE api_keys (
  api_key STRING NOT NULL,  -- Plain-text!
  api_key_hash STRING NOT NULL,
  ...
)
```

Cloud Function queries by plain-text API key:

```javascript
WHERE api_key = @apiKey  -- Comparing plain-text
```

**Impact:**
- Any user with BigQuery read access can extract all API keys
- Insider threat: Data analysts can steal keys
- If BigQuery is compromised (breach, misconfiguration), all keys leaked
- No key rotation protection

**Remediation:**
1. Store **only** the hash (`api_key_hash`) in BigQuery
2. Hash incoming API key and compare hashes:
   ```javascript
   WHERE api_key_hash = SHA256(@apiKey)
   ```
3. Never log or display the plain-text key after generation
4. Implement key rotation mechanism

**CVSS Vector:** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N`

---

#### NEW-003: No API Key Rotation Mechanism

| Field | Detail |
|-------|--------|
| **Severity** | 🟠 **HIGH** |
| **CVSS 3.1** | 7.4 (High) |
| **CWE** | CWE-324: Use of a Key Past its Expiration Date |
| **Component** | Overall architecture |

**Description:**

Once an API key is generated, there is no mechanism to:
- Rotate keys (generate new, deprecate old)
- Revoke keys immediately (only `is_active` flag, requires manual BigQuery update)
- Notify clients of key expiration
- Enforce key lifecycle policies

**Impact:**
- If a key is leaked, it remains valid indefinitely (or until manual revocation)
- No defense against long-term key compromise
- Difficult to comply with security audits (key rotation every 90 days)

**Remediation:**
1. Add key versioning: primary key + backup key
2. Implement auto-rotation: generate new key, notify client, deprecate old key after grace period
3. Add `rotated_at` and `previous_key_hash` columns
4. Build admin portal feature: "Rotate Key" button
5. Implement automated alerts: keys expiring in 7 days

---

#### NEW-004: Insufficient Logging & Monitoring

| Field | Detail |
|-------|--------|
| **Severity** | 🟠 **HIGH** |
| **CVSS 3.1** | 7.1 (High) |
| **CWE** | CWE-778: Insufficient Logging |
| **Component** | Cloud Functions, BigQuery |

**Description:**

Current logging gaps:
- No audit log of who generated API keys (only `created_by: process.env.USER`)
- No logging of failed authentication attempts (no IDS)
- No alerting on anomalous patterns (e.g., sudden spike in consent events)
- No integrity checks on BigQuery data (SQL injection could delete logs)
- No tamper-evident logging (attacker could delete Cloud Function logs)

**Impact:**
- Delayed detection of security incidents
- Insufficient forensic evidence for incident response
- Regulatory non-compliance (PDPA requires audit trails)
- Inability to detect insider threats

**Remediation:**
1. Enable Google Cloud Audit Logs for all admin actions
2. Stream Cloud Function logs to Cloud Logging with retention policy
3. Implement SIEM integration (e.g., Chronicle, Splunk)
4. Add anomaly detection: alert if consent rate > 3x baseline
5. Log failed auth attempts with IP, timestamp, attempted key
6. Create dashboard: failed auth rate, quota usage, error rate

---

#### NEW-005: No Input Validation on Domain Whitelist

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 **MEDIUM** |
| **CVSS 3.1** | 6.5 (Medium) |
| **CWE** | CWE-20: Improper Input Validation |
| **Component** | `cloud-function-auth/index.js` (lines 124-131) |

**Description:**

The domain whitelist validation uses regex without sanitization:

```javascript
const regex = new RegExp('^' + pattern.replace(/\*/g, '.*').replace(/\./g, '\\.') + '$');
```

This is vulnerable to:
1. **ReDoS (Regular Expression Denial of Service):**
   - Pattern like `**********...********` causes exponential backtracking
2. **Bypass via subdomain:**
   - Whitelist: `*.example.com`
   - Attacker uses: `evil.example.com.attacker.com` (may match depending on implementation)

**Impact:**
- DoS on Cloud Function via CPU exhaustion
- Potential domain whitelist bypass
- Slow response times during regex evaluation

**Remediation:**
1. Sanitize patterns: limit wildcards to 1 per domain
2. Use simpler string matching instead of regex for wildcards
3. Add timeout to regex evaluation (1ms max)
4. Pre-compile regex patterns at startup, cache them
5. Validate domain format: only alphanumeric + dots + hyphens

---

#### NEW-006: Missing Security Headers on HTML Pages

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 **MEDIUM** |
| **CVSS 3.1** | 5.9 (Medium) |
| **CWE** | CWE-16: Configuration |
| **Component** | All HTML files (demo, admin, customer portals) |

**Description:**

GCS-hosted HTML files lack HTTP security headers:
- No `Content-Security-Policy` (XSS defense)
- No `X-Frame-Options` (clickjacking defense)
- No `X-Content-Type-Options: nosniff`
- No `Referrer-Policy`
- No `Permissions-Policy`

**Impact:**
- XSS attacks easier to exploit (no CSP)
- Clickjacking possible (admin portal in iframe)
- MIME-type confusion attacks
- Referrer leakage (API keys in URL params could leak)

**Remediation:**

Add metadata to GCS objects:

```bash
gsutil setmeta -h "Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://www.gstatic.com; style-src 'self' 'unsafe-inline';" \
  -h "X-Frame-Options: DENY" \
  -h "X-Content-Type-Options: nosniff" \
  -h "Referrer-Policy: strict-origin-when-cross-origin" \
  gs://consentmanager/*.html
```

Or use Cloud Load Balancer with header injection.

---

#### NEW-007: No Encryption of Sensitive Data in Transit (Within GCP)

| Field | Detail |
|-------|--------|
| **Severity** | 🟢 **LOW** |
| **CVSS 3.1** | 4.3 (Medium) |
| **CWE** | CWE-319: Cleartext Transmission of Sensitive Information |
| **Component** | Cloud Function → BigQuery communication |

**Description:**

While external traffic (Browser → Cloud Function) is HTTPS, internal traffic (Cloud Function → BigQuery) uses Google's internal network. By default, this is encrypted, but:
- No enforcement of mTLS
- No certificate pinning
- Relies on GCP's default security

**Impact:**
- Theoretical MITM on GCP internal network (low likelihood, but possible with compromised GCP account)
- Regulatory compliance requirement for financial/healthcare sectors

**Remediation:**
1. Enable VPC Service Controls for BigQuery
2. Use Private Google Access for Cloud Functions
3. Enforce mTLS for all internal API calls (using GCP Workload Identity)
4. Document encryption-at-rest and in-transit in security policy

---

#### NEW-008: Lack of Disaster Recovery & Backup Strategy

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 **MEDIUM** |
| **CVSS 3.1** | 6.0 (Medium) |
| **CWE** | CWE-404: Improper Resource Shutdown or Release |
| **Component** | BigQuery, Cloud Storage |

**Description:**

No documented backup/restore procedures:
- BigQuery tables have no snapshots or backups
- API keys table could be deleted via SQL injection (PT-002)
- consent_events table has 2-year retention, but no intermediate backups
- GCS bucket has no versioning enabled

**Impact:**
- Data loss in case of SQL injection attack
- Unable to recover from accidental deletion
- Ransomware attack could destroy all data

**Remediation:**
1. Enable BigQuery table snapshots (daily)
2. Enable GCS bucket versioning
3. Set up automated exports to Cloud Storage (encrypted)
4. Create disaster recovery playbook
5. Test restore procedure quarterly

---

#### NEW-009: Privacy Violation - Excessive Data Collection

| Field | Detail |
|-------|--------|
| **Severity** | 🟠 **HIGH** |
| **CVSS 3.1** | 7.2 (High) - Regulatory Impact |
| **CWE** | CWE-359: Exposure of Private Personal Information |
| **Component** | Cloud Functions, BigQuery schema |

**Description:**

ConsentManager collects and stores:
- Raw IP addresses (PII under GDPR/PDPA)
- Full User-Agent strings (device fingerprinting)
- Page URLs (may contain sensitive query parameters, e.g., tokens)
- Referrer (may contain sensitive data)
- UTM parameters (tracking IDs)

This violates data minimization principles:
- **GDPR Article 5(1)(c):** Data minimization
- **PDPA (Thailand) Section 7:** Necessity and proportionality

**Impact:**
- Regulatory fines: up to €20M or 4% of revenue (GDPR), 100M THB (PDPA)
- User trust erosion
- Legal liability for data breach

**Remediation:**
1. **Stop logging raw IP addresses** - use hash only
2. **Truncate User-Agent:** store only browser + OS, not full string
3. **Sanitize URLs:** remove query parameters before logging
4. **Remove UTM parameters from storage:** track campaigns separately
5. **Add consent logging:** record user consent for analytics (meta-consent)
6. **Implement data subject access request (DSAR) API:** users can request deletion

---

#### NEW-010: No Security Testing in CI/CD Pipeline

| Field | Detail |
|-------|--------|
| **Severity** | 🟡 **MEDIUM** |
| **CVSS 3.1** | 5.5 (Medium) |
| **CWE** | CWE-1104: Use of Unmaintained Third-Party Components |
| **Component** | Development process |

**Description:**

No automated security checks:
- No SAST (Static Application Security Testing)
- No dependency scanning (npm audit not enforced)
- No secrets scanning (pre-commit hooks)
- No security unit tests

**Remediation:**
1. Add GitHub Actions workflow:
   - `npm audit --audit-level=high` (fail on HIGH+)
   - SAST: Semgrep, CodeQL
   - Secrets scanning: Gitleaks, TruffleHog
2. Pre-commit hooks: lint, format, audit
3. Security test cases in Jest suite

---

## 4. Risk Assessment & Impact Analysis

### 4.1 Risk Matrix

| Finding | Likelihood | Impact | Risk Score | Business Impact |
|---------|-----------|--------|------------|-----------------|
| **NEW-001:** No Auth on Admin Portal | **HIGH** | **CRITICAL** | **9.3** | Unauthorized API key generation → service disruption |
| **NEW-002:** Plain-text API Keys in DB | **MEDIUM** | **CRITICAL** | **8.2** | Mass key leakage → customer trust loss |
| **PT-001:** Hardcoded API Key | **HIGH** | **HIGH** | **9.1** | Quota exhaustion → $1000s in BigQuery costs |
| **PT-002:** SQL Injection | **MEDIUM** | **CRITICAL** | **8.6** | Data destruction → business continuity loss |
| **NEW-009:** Privacy Violation (PDPA) | **HIGH** | **HIGH** | **7.2** | Regulatory fine 100M THB + reputational damage |
| **NEW-003:** No Key Rotation | **MEDIUM** | **HIGH** | **7.4** | Long-term compromise undetected |
| **NEW-004:** Insufficient Logging | **HIGH** | **MEDIUM** | **7.1** | Slow incident response → extended breach |
| **PT-003:** XSS in Demo Site | **MEDIUM** | **HIGH** | **7.1** | Session hijacking → fake consent data |
| **NEW-005:** Domain Validation ReDoS | **LOW** | **HIGH** | **6.5** | Cloud Function DoS → service outage |
| **PT-008:** Weak Random for Keys | **LOW** | **HIGH** | **6.5** | Key prediction → unauthorized access |
| **NEW-008:** No Disaster Recovery | **LOW** | **HIGH** | **6.0** | Data loss → business continuity |
| **NEW-006:** Missing Security Headers | **MEDIUM** | **MEDIUM** | **5.9** | Easier exploitation of XSS |
| **NEW-010:** No Security in CI/CD | **MEDIUM** | **MEDIUM** | **5.5** | Vulnerable dependencies deployed |

### 4.2 Impact Analysis

#### Financial Impact

| Scenario | Probability | Cost (THB) | Expected Loss |
|----------|-------------|------------|---------------|
| PDPA fine (NEW-009 + PT-019) | 15% | 100,000,000 | 15,000,000 |
| BigQuery quota abuse (PT-001) | 40% | 500,000 | 200,000 |
| Customer churn (data breach) | 25% | 2,000,000 | 500,000 |
| Incident response costs | 60% | 300,000 | 180,000 |
| **TOTAL EXPECTED ANNUAL LOSS** | | | **15,880,000 THB** |

#### Reputational Impact

- **Brand damage:** "Conicle AI's consent manager violated PDPA" headlines
- **Customer trust:** Enterprises won't adopt product with known vulnerabilities
- **Competitive disadvantage:** Cookiebot/OneTrust will highlight security in marketing

#### Operational Impact

- **Incident response:** 2-4 weeks engineer time per breach
- **Legal costs:** 1M+ THB for PDPA litigation
- **Remediation costs:** 500K+ THB for security hardening

---

## 5. Prioritization Matrix

### 5.1 Remediation Priority (by Risk Score)

| Priority | Findings | Effort | Timeline |
|----------|----------|--------|----------|
| **P0 (Critical - Immediate)** | NEW-001, PT-001, PT-002, NEW-002 | 2-3 weeks | Week 1-3 |
| **P1 (High - 1 Month)** | NEW-009, NEW-003, NEW-004, PT-003 | 3-4 weeks | Week 4-7 |
| **P2 (Medium - 2 Months)** | NEW-005, PT-008, NEW-008, NEW-006 | 4-5 weeks | Week 8-12 |
| **P3 (Low - 3 Months)** | NEW-010, NEW-007, PT-014, PT-017 | 2-3 weeks | Week 13-15 |

### 5.2 Recommended Immediate Actions (This Week)

#### 1. **Rotate Demo API Key** (PT-001)
   - **Time:** 1 hour
   - **Action:** Generate new key, update demo site to fetch key from server-side endpoint
   - **Risk Reduction:** Prevents quota exhaustion attacks

#### 2. **Add Authentication to Admin Portal** (NEW-001)
   - **Time:** 1 day
   - **Action:** Implement Cloud Identity-Aware Proxy on GCS bucket
   - **Risk Reduction:** Prevents unauthorized API key generation

#### 3. **Fix SQL Injection** (PT-002)
   - **Time:** 4 hours
   - **Action:** Use parameterized queries, add input sanitization
   - **Risk Reduction:** Prevents data destruction

#### 4. **Stop Raw IP Logging** (NEW-009)
   - **Time:** 2 hours
   - **Action:** Set `logIP: false` by default, document in Readme
   - **Risk Reduction:** PDPA compliance

---

## 6. Remediation Roadmap

### Phase 1: Critical Fixes (Week 1-3)

#### Week 1: Authentication & API Key Security

**Day 1-2: Admin Portal Authentication**
- [ ] Set up Google Identity-Aware Proxy on GCS bucket
- [ ] Create Google Group: `consent-manager-admins@conicle.com`
- [ ] Test access control: only group members can access admin portal
- [ ] Document authentication setup in `PORTALS_GUIDE.md`

**Day 3-4: API Key Storage Security**
- [ ] Create migration script: hash all existing API keys
- [ ] Update BigQuery schema: remove `api_key` column, keep only `api_key_hash`
- [ ] Update Cloud Function: hash incoming key before query
- [ ] Test API key validation with hashed keys
- [ ] Rotate all existing keys

**Day 5: Demo Site API Key Protection**
- [ ] Create server-side proxy endpoint (Cloud Function) to inject API key
- [ ] Update demo site to call proxy instead of direct Cloud Function
- [ ] Remove hardcoded key from demo-live/index.html
- [ ] Deploy and test

#### Week 2: SQL Injection & XSS Fixes

**Day 1-2: SQL Injection Remediation**
- [ ] Refactor admin portal to use BigQuery parameterized queries
- [ ] Add input validation: allowlist for client names (alphanumeric + spaces)
- [ ] Add CSP header to admin portal
- [ ] Security test: attempt SQL injection payloads

**Day 3-4: XSS Fixes**
- [ ] Audit all `innerHTML` usage (demo, admin, customer portals)
- [ ] Replace with `textContent` or DOMPurify sanitization
- [ ] Add CSP headers to all HTML pages
- [ ] Security test: attempt XSS payloads

**Day 5: Logging & Monitoring**
- [ ] Enable Cloud Audit Logs for BigQuery
- [ ] Create Cloud Function log sink to Cloud Logging
- [ ] Set up alert policy: failed auth rate > 10/min

#### Week 3: Privacy Compliance

**Day 1-2: PDPA Compliance - Data Minimization**
- [ ] Update Cloud Functions: remove raw IP logging (`ip_address: null`)
- [ ] Truncate User-Agent: store only `browser_name` + `os_name`
- [ ] Add URL sanitization: remove query parameters from `page_url`
- [ ] Update BigQuery schema documentation

**Day 3: Privacy Policy Updates**
- [ ] Update Readme.md: document what data is collected
- [ ] Create `PRIVACY_POLICY.md` for end-users
- [ ] Add consent banner text template (meta-consent)

**Day 4-5: Testing & Documentation**
- [ ] Run full pentest re-check
- [ ] Update `PENTEST_REPORT.md` with remediation status
- [ ] Create security changelog
- [ ] Conduct team training on new security controls

### Phase 2: High-Priority Hardening (Week 4-7)

- [ ] Implement API key rotation mechanism
- [ ] Build anomaly detection dashboard
- [ ] Add security headers via Cloud Load Balancer
- [ ] Create disaster recovery playbook
- [ ] Fix weak random number generation (use `crypto.randomBytes`)
- [ ] Implement ReDoS protection in domain validation

### Phase 3: Medium-Priority Improvements (Week 8-12)

- [ ] Add backup/restore procedures
- [ ] Enable BigQuery table snapshots
- [ ] Set up SIEM integration
- [ ] Implement DSAR (data subject access request) API
- [ ] Create security testing suite

### Phase 4: Operational Excellence (Week 13-15)

- [ ] Add security scanning to CI/CD
- [ ] Create security runbook for on-call engineers
- [ ] Conduct tabletop exercise (breach simulation)
- [ ] Obtain security certification (ISO 27001 or SOC 2)

---

## 7. Conclusion & Recommendations

### Summary

ConsentManager has **21 security findings** (11 from previous pentest + 10 new):
- **4 Critical** (require immediate action)
- **6 High** (require action within 1 month)
- **7 Medium** (require action within 2 months)
- **4 Low/Info** (nice-to-have improvements)

### Key Recommendations

1. **Prioritize Critical Fixes:** Focus on NEW-001, PT-001, PT-002, NEW-002 this week
2. **Implement Defense in Depth:** Multiple layers (auth, validation, monitoring, encryption)
3. **Privacy by Design:** PDPA compliance should be default, not optional
4. **Automate Security:** CI/CD scanning, automated testing, alerting
5. **Continuous Monitoring:** Security is not a one-time fix

### Decision Points

| Question | Option A | Option B | Recommendation |
|----------|----------|----------|----------------|
| **Admin Portal** | Keep as static HTML + add IAP | Rebuild as full app with backend | **Option A** (faster, good enough) |
| **API Keys** | Hash in BigQuery | Move to Secret Manager | **Option A** (simpler, sufficient) |
| **Demo Site** | Add server-side proxy | Remove BigQuery integration | **Option A** (maintains demo value) |
| **Rate Limiting** | Application-level (current) | Add Cloud Armor | **Both** (multi-layer defense) |
| **Logging** | Current + SIEM | Splunk/Chronicle | **Current + SIEM** (cost-effective) |

---

**Next Steps:**

1. Review this document with CEO and technical team
2. Approve remediation budget and timeline
3. Assign owners for each phase
4. Begin Phase 1 (Critical Fixes) immediately
5. Schedule weekly security review meetings

---

**Document Control:**

- Version: 1.0
- Last Updated: February 16, 2026
- Owner: Security Team
- Classification: Internal - Confidential
- Next Review: March 16, 2026
