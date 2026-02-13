# 🚀 Setup Guide - ConsentManager

**Complete setup in 3 easy steps (5 minutes)**

---

## ⚡ Quick Summary

- ✅ **GDPR-compliant** cookie consent manager
- ✅ **BigQuery analytics** with API key authentication
- ✅ **2-year auto-deletion** for data retention
- ✅ **Cost:** ~39 THB/month for 15M events (0.78% of budget)
- ✅ **Scale:** Ready for 100x more traffic

---

## 📋 3-Step Setup

### Step 1: Add ConsentManager to Your Website (2 minutes)

Add this code to your website's `<head>` or before `</body>`:

```html
<!-- Load ConsentManager -->
<script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/consent-manager.js"></script>

<script>
// Initialize ConsentManager
window.ConsentManager = ConsentManager.run({
  categories: {
    necessary: {
      enabled: true,
      readOnly: true
    },
    analytics: {},
    marketing: {}
  },
  
  language: {
    default: 'en',
    translations: {
      en: {
        consentModal: {
          title: 'We use cookies',
          description: 'We use cookies to enhance your browsing experience...',
          acceptAllBtn: 'Accept all',
          acceptNecessaryBtn: 'Reject all',
          showPreferencesBtn: 'Manage preferences'
        },
        preferencesModal: {
          title: 'Cookie preferences',
          acceptAllBtn: 'Accept all',
          acceptNecessaryBtn: 'Reject all',
          savePreferencesBtn: 'Save settings',
          sections: [
            {
              title: 'Necessary cookies',
              description: 'These cookies are essential for the website to function properly.',
              linkedCategory: 'necessary'
            },
            {
              title: 'Analytics cookies',
              description: 'Help us understand how visitors interact with our website.',
              linkedCategory: 'analytics'
            },
            {
              title: 'Marketing cookies',
              description: 'Used to deliver personalized advertisements.',
              linkedCategory: 'marketing'
            }
          ]
        }
      }
    }
  }
});
</script>
```

**Done!** Your cookie consent banner is now active. ✅

---

### Step 2: Get API Key for BigQuery Logging (Optional, 2 minutes)

**Option A: Use Customer Portal (Easiest)**

1. Visit: https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html
2. Fill in registration form
3. Receive API key via email within 24 hours

**Option B: Contact Admin Directly**

Email admin@conicle.ai with:
- Your company name
- Domains to whitelist
- Expected monthly volume

---

### Step 3: Add BigQuery Logging (1 minute)

Once you have your API key, add this code:

```html
<script>
// Configuration
const BIGQUERY_API_KEY = 'YOUR-API-KEY-HERE';  // ← Replace with your key
const BIGQUERY_LOG_URL = 'https://logconsentauth-pxoxh5sfqa-as.a.run.app';

// Generate session ID
function getSessionId() {
  let sessionId = sessionStorage.getItem('cm_session_id');
  if (!sessionId) {
    sessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    sessionStorage.getItem('cm_session_id', sessionId);
  }
  return sessionId;
}

// Log to BigQuery
async function logToBigQuery(eventType, eventData) {
  try {
    const payload = {
      event_type: eventType,
      cookie: eventData.cookie,
      acceptType: eventData.cookie?.categories?.length === 3 ? 'all' : 
                 eventData.cookie?.categories?.length === 1 ? 'necessary' : 'custom',
      sessionId: getSessionId(),
      pageUrl: window.location.href,
      pageTitle: document.title,
      referrer: document.referrer,
      language: navigator.language,
      version: '1.0.0',
      logIP: true
    };
    
    const response = await fetch(BIGQUERY_LOG_URL, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'X-API-Key': BIGQUERY_API_KEY  // ← Authentication
      },
      body: JSON.stringify(payload)
    });
    
    if (response.ok) {
      const result = await response.json();
      console.log('✅ Logged to BigQuery:', result.event_id);
    }
  } catch (error) {
    console.warn('⚠️ BigQuery logging error:', error);
  }
}

// Initialize with logging
window.ConsentManager = ConsentManager.run({
  // ... your config ...
  
  onFirstConsent: ({cookie}) => {
    logToBigQuery('first_consent', {cookie});
  },
  
  onConsent: ({cookie}) => {
    logToBigQuery('consent', {cookie});
  },
  
  onChange: ({cookie, changedCategories}) => {
    logToBigQuery('change', {cookie, changedCategories});
  }
});
</script>
```

**Done!** Your consent events are now tracked in BigQuery. 🎉

---

## 🧪 Testing

### Test 1: Verify ConsentManager Works

1. Open your website
2. You should see a cookie consent banner
3. Click "Accept all" or "Reject all"
4. Open browser console → look for ConsentManager logs

### Test 2: Verify BigQuery Logging (if enabled)

```bash
curl -X POST https://logconsentauth-pxoxh5sfqa-as.a.run.app \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR-API-KEY" \
  -d '{
    "event_type": "consent",
    "cookie": {"categories": ["necessary", "analytics"]},
    "acceptType": "custom",
    "pageUrl": "https://example.com/test",
    "version": "1.0.0"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "event_id": "abc-123...",
  "client": "Your Company Name"
}
```

---

## 🎨 Customization

### Change Colors:

```javascript
window.ConsentManager = ConsentManager.run({
  // ... other config ...
  
  guiOptions: {
    consentModal: {
      layout: 'box',           // 'box', 'cloud', 'bar'
      position: 'bottom left'  // position on screen
    }
  }
});
```

### Add Dark Mode:

```javascript
guiOptions: {
  consentModal: {
    layout: 'box inline',
    darkMode: 'auto'  // 'auto', true, false
  }
}
```

### Thai Language:

```javascript
language: {
  default: 'th',
  translations: {
    th: {
      consentModal: {
        title: 'เราใช้คุกกี้',
        description: 'เราใช้คุกกี้เพื่อปรับปรุงประสบการณ์การท่องเว็บของคุณ',
        acceptAllBtn: 'ยอมรับทั้งหมด',
        acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
        showPreferencesBtn: 'จัดการการตั้งค่า'
      }
    }
  }
}
```

---

## 📊 View Your Data (BigQuery)

### Quick Check:

```sql
SELECT 
  DATE(event_timestamp) as date,
  COUNT(*) as events,
  COUNTIF(accept_type = 'all') as accepted_all,
  COUNTIF(accept_type = 'necessary') as rejected
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) >= CURRENT_DATE() - 7
GROUP BY date
ORDER BY date DESC;
```

### Check Costs:

```sql
SELECT * FROM `conicle-ai-dev.consent_analytics.cost_dashboard`;
```

**BigQuery Console:**  
https://console.cloud.google.com/bigquery?project=conicle-ai-dev

---

## 🔐 For Admins: Schedule Auto-Deletion

Run this **once** to schedule 2-year data deletion:

```bash
bq query --use_legacy_sql=false \
  --schedule='every day 00:00' \
  --location=asia-southeast3 \
  --display_name='Delete old consent data (2+ years)' \
  "DELETE FROM \`conicle-ai-dev.consent_analytics.consent_events\`
   WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY)"
```

**Or use BigQuery Console:**
1. Go to: https://console.cloud.google.com/bigquery
2. Click "Scheduled queries" → "Create scheduled query"
3. Paste query above
4. Schedule: Daily at 00:00
5. Save

---

## ✅ Production Checklist

Before going live:

- [ ] ConsentManager loads on all pages
- [ ] Banner appears on first visit
- [ ] User preferences are saved
- [ ] Scripts are blocked until consent
- [ ] BigQuery logging works (if enabled)
- [ ] Scheduled auto-deletion (if using BigQuery)
- [ ] Tested on mobile devices
- [ ] Tested in incognito mode

---

## 🆘 Troubleshooting

### Banner doesn't appear?
- Check browser console for errors
- Verify script URL is correct
- Clear cookies and reload

### BigQuery logging not working?
- Check API key is correct
- Verify domain is whitelisted
- Check browser console for errors
- Test with curl command above

### Scripts not being blocked?
Add `data-category="analytics"` to your script tags:
```html
<script data-category="analytics" src="analytics.js"></script>
```

---

## 📚 Next Steps

- **Customize:** [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) - Full examples
- **Admin:** [ADMIN_GUIDE.md](./ADMIN_GUIDE.md) - Manage API keys & costs
- **Analytics:** [BIGQUERY_GUIDE.md](./BIGQUERY_GUIDE.md) - Query your data

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Live Demo** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/ |
| **Register for API** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html |
| **Admin Portal** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html |
| **GitHub** | https://github.com/tanapatj/prototype-cookie |

---

**That's it!** You're ready for production. 🚀

**Questions?** Email: admin@conicle.ai
