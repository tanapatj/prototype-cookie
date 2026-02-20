# ConsentManager — Complete User Guide

**Version:** 1.0.0 | **Built by:** Conicle AI Data Engineering Team

> This document covers the **complete end-to-end workflow** — from a customer requesting access, to their consent banner going live and data appearing in BigQuery.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Step 1 — Customer Registers Their Domain](#step-1--customer-registers-their-domain)
3. [Step 2 — Admin Reviews & Generates API Key](#step-2--admin-reviews--generates-api-key)
4. [Step 3 — Customer Integrates ConsentManager](#step-3--customer-integrates-consentmanager)
5. [Step 4 — Events Flow to BigQuery](#step-4--events-flow-to-bigquery)
6. [Step 5 — Admin Monitors Usage & Manages Keys](#step-5--admin-monitors-usage--manages-keys)
7. [Quick Reference (URLs & Contacts)](#quick-reference)
8. [FAQ](#faq)

---

## System Overview

```
Customer's Website
       │
       │  1. Loads ConsentManager from CDN
       │  2. User clicks Accept / Reject
       │  3. Consent event sent to Cloud Function
       ↓
  Cloud Function (Asia-Southeast1)
       │  Validates API Key + Domain
       ↓
  BigQuery (consent_analytics)
       │  Stores every consent event
       ↓
  Admin Portal
       Generates keys · Monitors usage · Revokes keys
```

**Roles:**

| Role | Who | Tools |
|------|-----|-------|
| **Admin** | Conicle team (`@conicle.com`) | Admin Portal |
| **Customer** | Client's developer or IT team | Customer Portal → their own website |
| **End-User** | Visitor on the customer's website | Consent banner |

---

## Step 1 — Customer Registers Their Domain

The customer tells Conicle which domain(s) they want to use ConsentManager on.

### Option A: Customer Portal (Self-Service)

> **URL:** https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/customer.html

1. Customer opens the Customer Portal
2. Fills in the form:
   - **Company name**
   - **Website domain(s)** (e.g., `mycompany.com`, `*.mycompany.com`)
   - **Contact email**
   - **Expected monthly events** (for quota planning)
3. Clicks **"Submit Request"**
4. Customer receives a **Request ID** (e.g., `REQ-1234567`)
5. Conicle admin is notified to review the request

### Option B: Direct Request (Email)

Customer emails **tanapatj@conicle.com** with:
- Company name
- Domain(s) to whitelist
- Contact email
- Estimated events/month

### What happens next?

The admin receives the request and proceeds to **Step 2**.

---

## Step 2 — Admin Reviews & Generates API Key

> **Admin Portal:** https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html  
> **Requires:** `@conicle.com` Google account

### 2.1 Sign In

1. Open the Admin Portal
2. Click **"Sign in with Google"**
3. Use your `@conicle.com` account — other accounts are blocked

### 2.2 Generate the API Key

1. Go to the **🔑 Generate Key** tab
2. Fill in the form:

| Field | Example | Notes |
|-------|---------|-------|
| Client Name | `Acme Corp` | Will appear in BigQuery |
| Contact Email | `dev@acme.com` | Optional, for communication |
| Allowed Domains | `acme.com` / `*.acme.com` | One per line. `*` = all subdomains |
| Monthly Quota | `500000` | Leave blank = unlimited |
| Expiration Date | `2027-12-31` | Leave blank = never expires |
| Notes | `Trial account` | Internal only, not shown to customer |

3. Click **"🔑 Generate & Save API Key"**

### 2.3 What happens automatically

- ✅ A cryptographically secure API key is generated (`cm_xxxxxxxx...`)
- ✅ Key is saved directly to BigQuery — **no manual SQL needed**
- ✅ Domain whitelist is enforced immediately

### 2.4 Send to Customer

Copy the generated **API Key** and **Integration Code** shown on screen, then send to the customer via email.

**Example email:**

```
Subject: Your ConsentManager API Key

Hi [Customer Name],

Your ConsentManager API key is ready:

API Key: cm_a1b2c3d4e5f6...

Integration guide: see attached code below.
For help, email tanapatj@conicle.com
```

---

## Step 3 — Customer Integrates ConsentManager

The customer's developer adds ConsentManager to their website.

### 3.1 Minimum Setup (No Analytics — Free)

Add these 3 lines to every HTML page. **No API key needed.**

```html
<!DOCTYPE html>
<html>
<head>
    <!-- Step 1: Add CSS in <head> -->
    <link rel="stylesheet"
          href="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css">
</head>
<body>

    <!-- Your website content here -->

    <!-- Step 2: Add JS before </body> -->
    <script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"></script>

    <!-- Step 3: Initialize -->
    <script>
    ConsentManager.run({
        categories: {
            necessary: { readOnly: true, enabled: true },
            analytics: {},
            marketing: {}
        },
        language: {
            default: 'en',
            translations: {
                en: {
                    consentModal: {
                        title: 'We use cookies',
                        description: 'This website uses cookies to improve your browsing experience.',
                        acceptAllBtn: 'Accept all',
                        acceptNecessaryBtn: 'Reject all',
                        showPreferencesBtn: 'Manage preferences'
                    },
                    preferencesModal: {
                        title: 'Cookie Preferences',
                        acceptAllBtn: 'Accept all',
                        acceptNecessaryBtn: 'Reject all',
                        savePreferencesBtn: 'Save preferences',
                        closeIconLabel: 'Close',
                        sections: [
                            { title: 'Strictly Necessary', linkedCategory: 'necessary' },
                            { title: 'Analytics Cookies', linkedCategory: 'analytics' },
                            { title: 'Marketing Cookies', linkedCategory: 'marketing' }
                        ]
                    }
                }
            }
        }
    });
    </script>
</body>
</html>
```

The consent banner appears automatically. User preferences are stored in the browser cookie (`cm_cookie`). **This alone is GDPR/PDPA compliant.**

---

### 3.2 Block Tracking Scripts (GDPR Requirement)

Tracking scripts (Google Analytics, Facebook Pixel, etc.) **must not run until the user consents**.

**Before — NOT compliant ❌**
```html
<script>
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX');  // Runs immediately without consent
</script>
```

**After — Compliant ✅**
```html
<script data-category="analytics" type="text/plain">
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX');  <!-- Only runs after user accepts analytics -->
</script>
```

**Rule:** Add `data-category="analytics"` and `type="text/plain"` to any tracking script. ConsentManager unblocks it only after the user gives consent for that category.

---

### 3.3 Add BigQuery Analytics Logging (Optional, Requires API Key)

To stream consent events to BigQuery, add an event listener after your `ConsentManager.run()` call:

```html
<script>
ConsentManager.run({ /* ... your config ... */ });

// BigQuery logging (requires API key from Conicle admin)
const CM_LOG_URL = 'https://logconsentauth-pxoxh5sfqa-as.a.run.app';
const CM_API_KEY = 'cm_your_api_key_here'; // Replace with your actual API key

function logConsentEvent(eventName, detail) {
    fetch(CM_LOG_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-API-Key': CM_API_KEY
        },
        body: JSON.stringify({
            event_type: eventName,
            cookie: detail.cookie,
            acceptType: detail.cookie?.acceptType,
            pageUrl: window.location.href,
            pageTitle: document.title,
            referrer: document.referrer,
            language: navigator.language,
            version: '1.0.0'
        })
    }).catch(() => {}); // Non-blocking — consent still works if logging fails
}

window.addEventListener('cm:onFirstConsent', ({ detail }) => logConsentEvent('first_consent', detail));
window.addEventListener('cm:onConsent',      ({ detail }) => logConsentEvent('consent', detail));
window.addEventListener('cm:onChange',       ({ detail }) => logConsentEvent('change', detail));
</script>
```

> ⚠️ **Security note:** Avoid hardcoding the API key in client-side HTML when possible. For higher security, have your backend server inject the key, or use a server-side proxy endpoint.

---

### 3.4 Thai Language Support

```javascript
ConsentManager.run({
    categories: {
        necessary: { readOnly: true, enabled: true },
        analytics: {},
        marketing: {}
    },
    language: {
        default: 'th',
        translations: {
            th: {
                consentModal: {
                    title: 'เราใช้คุกกี้',
                    description: 'เว็บไซต์นี้ใช้คุกกี้เพื่อปรับปรุงประสบการณ์การใช้งานของคุณ',
                    acceptAllBtn: 'ยอมรับทั้งหมด',
                    acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
                    showPreferencesBtn: 'จัดการการตั้งค่า'
                },
                preferencesModal: {
                    title: 'ตั้งค่าคุกกี้',
                    acceptAllBtn: 'ยอมรับทั้งหมด',
                    acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
                    savePreferencesBtn: 'บันทึกการตั้งค่า',
                    closeIconLabel: 'ปิด',
                    sections: [
                        { title: 'คุกกี้ที่จำเป็น', linkedCategory: 'necessary' },
                        { title: 'คุกกี้วิเคราะห์', linkedCategory: 'analytics' },
                        { title: 'คุกกี้การตลาด', linkedCategory: 'marketing' }
                    ]
                }
            }
        }
    }
});
```

---

## Step 4 — Events Flow to BigQuery

Once the customer integrates the logging code, consent events automatically appear in BigQuery.

### What Gets Recorded

Every time a user interacts with the consent banner, one row is written to `consent_analytics.consent_events` with:

| Column | Example | Description |
|--------|---------|-------------|
| `event_type` | `first_consent` | Type of event |
| `accept_type` | `all` / `necessary` / `custom` | What the user chose |
| `client_name` | `Acme Corp` | Which customer's site |
| `page_url` | `https://acme.com/` | Page where consent happened |
| `device_type` | `mobile` | desktop / mobile / tablet |
| `browser_name` | `Chrome` | Browser |
| `ip_hash` | `sha256(ip+salt)` | Hashed for PDPA compliance |
| `event_timestamp` | `2026-02-20 08:00:00` | When it happened |

### View in BigQuery

1. Open [BigQuery Console](https://console.cloud.google.com/bigquery?project=conicle-ai-dev)
2. Navigate to `conicle-ai-dev` → `consent_analytics` → `consent_events`
3. Run a quick check:

```sql
SELECT
  client_name,
  accept_type,
  COUNT(*) AS total,
  DATE(event_timestamp) AS date
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) = CURRENT_DATE()
GROUP BY client_name, accept_type, date
ORDER BY total DESC;
```

More query templates are in `bigquery/example-queries.sql`.

---

## Step 5 — Admin Monitors Usage & Manages Keys

### 5.1 View Active Keys & Usage

1. Open Admin Portal → **📋 Manage Keys** tab
2. See all clients with:
   - API key (masked for security)
   - Active / Revoked status
   - Monthly usage vs. quota (with progress bar)
   - Expiration date

### 5.2 Revoke a Key

If a customer's contract ends, they misuse the key, or you need to force a rotation:

1. Admin Portal → **📋 Manage Keys** tab
2. Find the client
3. Click **"🚫 Revoke"**
4. Confirm in the dialog

The key is deactivated **immediately** — subsequent requests from that key return HTTP 401.

### 5.3 Quota Management

If a customer exceeds their monthly quota:
- The Cloud Function returns HTTP 429 (quota exceeded)
- Events stop logging until the next month or quota is raised
- To raise quota: generate a new key with a higher quota and send to the customer

### 5.4 Data Retention

Consent events are automatically deleted after **2 years** (PDPA/GDPR compliance).  
Retention policy is defined in `bigquery/auto-delete-old-data.sql`.

---

## Quick Reference

### URLs

| Resource | URL |
|----------|-----|
| **Live Demo** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/index.html |
| **Admin Portal** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html |
| **Customer Portal** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/customer.html |
| **GitHub** | https://github.com/tanapatj/prototype-cookie |
| **BigQuery Console** | https://console.cloud.google.com/bigquery?project=conicle-ai-dev |

### CDN Assets (for customer websites)

| Asset | URL |
|-------|-----|
| JavaScript (UMD) | `https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js` |
| JavaScript (ESM) | `https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.esm.js` |
| CSS | `https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css` |

### Cloud Functions

| Function | URL | Purpose |
|----------|-----|---------|
| `logConsentAuth` | `https://logconsentauth-pxoxh5sfqa-as.a.run.app` | Log consent events (authenticated) |
| `adminKeyManager` | `https://adminkeymanager-pxoxh5sfqa-as.a.run.app` | Admin: generate / list / revoke keys |

### Contact

- **Team:** AI Tech Capabilities @ Conicle
- **Email:** tanapatj@conicle.com

---

## FAQ

**Q: Do customers need a backend server?**  
A: No. The consent banner works entirely client-side. Only BigQuery logging requires an API key.

**Q: What if a customer's website has multiple domains?**  
A: Add all domains when generating the key (one per line, wildcards supported: `*.example.com`).

**Q: Can a customer use the same key on multiple websites?**  
A: Yes, if all their domains are added to the whitelist for that key.

**Q: Is it GDPR/PDPA compliant?**  
A: Yes. IP addresses are hashed (SHA-256 + salt), data retention is 2 years, and users have full control over their consent choices.

**Q: How much does it cost?**  
A: ~$1/month for up to 15M events. See the Cost section in `Readme.md`.

**Q: What happens when a key expires?**  
A: The Cloud Function returns HTTP 401. Events stop logging. Generate a new key and send it to the customer.

**Q: Can I customize the banner appearance?**  
A: Yes. See the [Live Demo](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/index.html) for the interactive style configurator, or read `FRONTEND_IMPLEMENTATION_GUIDE.md`.

**Q: How do I add Google Analytics in a compliant way?**  
A: See `GOOGLE_ANALYTICS_INTEGRATION.md` for a complete guide.

---

## Document Index

| Document | Purpose |
|----------|---------|
| `START_HERE.md` | **This file** — complete operational guide |
| `Readme.md` | Technical overview and API reference |
| `FRONTEND_IMPLEMENTATION_GUIDE.md` | Full frontend integration guide |
| `PENTEST_REPORT.md` | Security assessment (19 findings) |
| `SECURITY_DISCUSSION.md` | Ongoing security analysis & roadmap |
| `DDOS_PROTECTION.md` | DDoS protection implementation details |
| `DEVSECOPS_RECOMMENDATIONS.md` | Security improvement recommendations |
| `bigquery/deployment-guide.md` | BigQuery infrastructure setup |
| `bigquery/example-queries.sql` | Ready-to-use analytics SQL queries |
| `docs/` | Full API documentation |
