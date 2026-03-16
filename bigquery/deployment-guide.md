# BigQuery Consent Logging - Deployment Guide

## 🎯 Overview

This guide will help you set up real-time consent logging to BigQuery.

**Architecture:**
```
Website → ConsentManager → Cloud Function → BigQuery
         (user clicks)    (logs event)     (stores data)
```

**What gets logged:**
- ✅ Consent events (accept/reject)
- ✅ Categories accepted/rejected
- ✅ IP address (hashed for privacy)
- ✅ Browser/device info
- ✅ Page URL, referrer
- ✅ Timestamps

---

## 📋 Prerequisites

- GCP Project: `cookiemanager-488405` ✅
- `gcloud` CLI authenticated ✅
- Billing enabled on your GCP project

---

## 🚀 Step-by-Step Deployment

### Step 1: Create BigQuery Dataset

```bash
# Create dataset
gcloud config set project cookiemanager-488405

bq mk --dataset \
  --location=asia-southeast3 \
  --description="Consent analytics data" \
  consent_analytics
```

### Step 2: Create BigQuery Table

```bash
# Create table with schema
bq mk --table \
  cookiemanager-488405:consent_analytics.consent_events \
  bigquery/schema.sql
```

**Or run the SQL directly:**
```bash
bq query --use_legacy_sql=false < bigquery/schema.sql
```

### Step 3: Deploy Cloud Function

```bash
cd bigquery/cloud-function

# Install dependencies (optional, gcloud will do this)
npm install

# Deploy function
gcloud functions deploy logConsent \
  --gen2 \
  --runtime=nodejs20 \
  --region=asia-southeast3 \
  --source=. \
  --entry-point=logConsent \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars IP_SALT=your-secret-salt-here \
  --max-instances=10 \
  --memory=256MB \
  --timeout=60s \
  --project=cookiemanager-488405
```

**Important:** Replace `your-secret-salt-here` with a random string for IP hashing.

### Step 4: Get Cloud Function URL

```bash
gcloud functions describe logConsent \
  --region=asia-southeast3 \
  --project=cookiemanager-488405 \
  --format="value(serviceConfig.uri)"
```

**Example output:**
```
https://logconsent-abc123-uc.a.run.app
```

**Save this URL!** You'll need it in the next step.

---

## 🔧 Update Your Website

### Option A: Full Logging (Recommended)

Add this to your ConsentManager initialization:

```html
<script src="https://storage.googleapis.com/consentmanager/v1.0.0/consent-manager.umd.js"></script>

<script>
// Your Cloud Function URL
const CONSENT_LOG_URL = 'https://YOUR-FUNCTION-URL.a.run.app';

// Optional: Get current user ID if logged in
function getCurrentUserId() {
    // Return user ID if user is logged in, null otherwise
    return null; // Or: return window.currentUser?.id;
}

// Optional: Generate anonymous session ID
function getSessionId() {
    let sessionId = sessionStorage.getItem('consent_session_id');
    if (!sessionId) {
        sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        sessionStorage.setItem('consent_session_id', sessionId);
    }
    return sessionId;
}

// Log consent event to BigQuery
async function logConsentEvent(eventType, eventData) {
    try {
        const payload = {
            event_type: eventType,
            cookie: eventData.cookie,
            acceptType: eventData.cookie?.categories?.length === 3 ? 'all' : 
                       eventData.cookie?.categories?.length === 1 ? 'necessary' : 'custom',
            rejectedCategories: [],
            changedCategories: eventData.changedCategories || [],
            rejectedServices: eventData.rejectedServices || {},
            
            // User info
            sessionId: getSessionId(),
            userId: getCurrentUserId(),
            
            // Page context
            pageUrl: window.location.href,
            pageTitle: document.title,
            referrer: document.referrer,
            language: navigator.language,
            
            // Metadata
            version: '1.0.0',
            
            // Privacy: Set to true only if you have legal basis to log raw IP
            logIP: false  // Hashed IP is always logged
        };
        
        await fetch(CONSENT_LOG_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        
        console.log('✅ Consent logged to BigQuery');
    } catch (error) {
        console.warn('Failed to log consent:', error);
        // Don't block user experience if logging fails
    }
}

// Initialize ConsentManager with logging
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
                    description: 'We use cookies to improve your experience.',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject all',
                    showPreferencesBtn: 'Manage preferences'
                }
            }
        }
    },
    
    // Log first-time consent
    onFirstConsent: function(event) {
        logConsentEvent('first_consent', event);
    },
    
    // Log all consent events
    onConsent: function(event) {
        logConsentEvent('consent', event);
    },
    
    // Log preference changes
    onChange: function(event) {
        logConsentEvent('change', event);
    }
});
</script>
```

### Option B: Minimal Logging (Less Invasive)

```javascript
// Simpler version - only log accept/reject without page context
onConsent: function(event) {
    fetch(CONSENT_LOG_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            event_type: 'consent',
            cookie: event.cookie,
            sessionId: getSessionId(),
            version: '1.0.0',
            logIP: false
        })
    }).catch(err => console.warn('Log failed:', err));
}
```

---

## 📊 Query Your Data

### Check if data is flowing:

```sql
SELECT 
    COUNT(*) as total_events,
    event_type,
    accept_type
FROM `cookiemanager-488405.consent_analytics.consent_events`
WHERE DATE(event_timestamp) = CURRENT_DATE()
GROUP BY event_type, accept_type
ORDER BY total_events DESC;
```

### Acceptance rate by category:

```sql
WITH consent_events AS (
  SELECT 
    event_timestamp,
    accept_type,
    accepted_categories
  FROM `cookiemanager-488405.consent_analytics.consent_events`
  WHERE event_type = 'consent'
    AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
)
SELECT 
  accept_type,
  COUNT(*) as total_consents,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM consent_events
GROUP BY accept_type
ORDER BY total_consents DESC;
```

### Top countries accepting analytics:

```sql
SELECT 
  country_code,
  COUNT(*) as users,
  COUNTIF('analytics' IN UNNEST(accepted_categories)) as accepted_analytics,
  ROUND(COUNTIF('analytics' IN UNNEST(accepted_categories)) * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `cookiemanager-488405.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND country_code IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY country_code
HAVING users > 10
ORDER BY users DESC
LIMIT 20;
```

### Browser/device breakdown:

```sql
SELECT 
  device_type,
  browser_name,
  COUNT(*) as users,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `cookiemanager-488405.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY device_type, browser_name
ORDER BY users DESC;
```

---

## 💰 Cost Estimate

### BigQuery Storage:
- **First 10 GB/month:** FREE
- **After 10 GB:** $0.02/GB/month
- **Estimated:** 1,000 events/day = ~0.5 MB/day = ~15 MB/month
- **Cost:** FREE (well under 10 GB)

### BigQuery Queries:
- **First 1 TB/month:** FREE
- **After 1 TB:** $5/TB
- **Estimated:** Dashboard queries ~10 GB/month
- **Cost:** FREE

### Cloud Function:
- **First 2M invocations:** FREE
- **After 2M:** $0.40/million
- **Estimated:** 1,000 events/day = ~30k/month
- **Cost:** FREE

**Total Estimated Cost: $0-2/month** 🎉

---

## 🔒 Privacy & GDPR Compliance

### What we're doing right:

✅ **IP Address Hashing:** All IPs are SHA-256 hashed by default  
✅ **Anonymous by Default:** No user ID logged unless explicitly set  
✅ **Session-based:** Uses anonymous session IDs  
✅ **Opt-in:** Raw IP only logged if `logIP: true` (default: false)  
✅ **Transparent:** User knows they're being tracked (consent banner)

### Recommendations:

1. **Update Privacy Policy:** Mention that you log consent events for analytics
2. **Data Retention:** Set up automatic deletion after 2 years:
   ```sql
   -- Run monthly
   DELETE FROM `cookiemanager-488405.consent_analytics.consent_events`
   WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);
   ```
3. **User Rights:** Provide a way for users to request deletion of their data

---

## 🐛 Troubleshooting

### Function not receiving data:

```bash
# Check function logs
gcloud functions logs read logConsent \
  --region=asia-southeast3 \
  --limit=50 \
  --project=cookiemanager-488405
```

### Test function manually:

```bash
curl -X POST https://YOUR-FUNCTION-URL.a.run.app \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "consent",
    "cookie": {
      "categories": ["necessary", "analytics"],
      "consentId": "test-123",
      "consentTimestamp": "2026-02-12T07:00:00Z"
    },
    "pageUrl": "https://test.com",
    "version": "1.0.0"
  }'
```

### Check BigQuery table:

```bash
# List recent rows
bq query --use_legacy_sql=false \
  'SELECT * FROM `cookiemanager-488405.consent_analytics.consent_events` ORDER BY event_timestamp DESC LIMIT 10'
```

---

## 📈 Next Steps

After deployment:

1. ✅ Wait 24 hours for data to accumulate
2. ✅ Create a Looker Studio dashboard (connect to BigQuery)
3. ✅ Set up scheduled queries for daily reports
4. ✅ Add alerting for unusual patterns (e.g., sudden drop in acceptance rate)

---

## 🎯 Summary

**What you get:**
- Real-time consent logging to BigQuery
- Analytics on acceptance rates
- Device/browser/country breakdowns
- GDPR-compliant (hashed IPs, anonymous by default)
- Costs ~$0-2/month

**Time to deploy:** ~15 minutes

**Ready to start?** Follow Step 1 above! 🚀
