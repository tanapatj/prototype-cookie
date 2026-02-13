# 🍪 ConsentManager

**White-labeled GDPR-compliant cookie consent management with BigQuery analytics.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)]()
[![Cost](https://img.shields.io/badge/Cost-~39%20THB%2Fmonth-success)]()

---

## ⚡ Quick Links

| For | Link | Description |
|-----|------|-------------|
| **🚀 Get Started** | [SETUP_GUIDE.md](./SETUP_GUIDE.md) | 3-step setup in 5 minutes |
| **👨‍💼 Admin Guide** | [ADMIN_GUIDE.md](./ADMIN_GUIDE.md) | Manage API keys & monitor costs |
| **💻 Integration** | [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) | Frontend integration & examples |
| **📊 BigQuery** | [BIGQUERY_GUIDE.md](./BIGQUERY_GUIDE.md) | Analytics & cost monitoring |

---

## 🎯 What Is This?

ConsentManager is a **white-labeled, production-ready** cookie consent system with:

✅ **GDPR/CCPA Compliant** - Block scripts until user consents  
✅ **Real-time Analytics** - Log all consent events to BigQuery  
✅ **API Key Authentication** - Secure domain whitelist  
✅ **Cost Optimized** - ~39 THB/month for 15M events  
✅ **Auto-Deletion** - 2-year data retention  
✅ **Web Portals** - Admin & customer registration UI  

---

## 🚀 Quick Start (5 Minutes)

### 1. Add to Your Website

```html
<!-- Load ConsentManager -->
<script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/consent-manager.js"></script>

<script>
// Initialize
window.ConsentManager = ConsentManager.run({
  categories: {
    necessary: { enabled: true, readOnly: true },
    analytics: {},
    marketing: {}
  },
  
  language: {
    default: 'en',
    translations: {
      en: {
        consentModal: {
          title: 'We use cookies',
          description: 'We use cookies to enhance your experience.'
        }
      }
    }
  }
});
</script>
```

### 2. Enable BigQuery Logging (Optional)

[Register for API key →](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html)

Then add:

```javascript
const BIGQUERY_API_KEY = 'your-api-key';
const BIGQUERY_LOG_URL = 'https://logconsentauth-pxoxh5sfqa-as.a.run.app';

async function logToBigQuery(eventType, eventData) {
  await fetch(BIGQUERY_LOG_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': BIGQUERY_API_KEY
    },
    body: JSON.stringify({
      event_type: eventType,
      cookie: eventData.cookie,
      pageUrl: window.location.href,
      version: '1.0.0'
    })
  });
}

// Add event handlers
window.ConsentManager = ConsentManager.run({
  // ... config ...
  onConsent: ({cookie}) => logToBigQuery('consent', {cookie}),
  onChange: ({cookie}) => logToBigQuery('change', {cookie})
});
```

**Done!** 🎉 Your consent is now tracked in BigQuery.

---

## 📦 What's Included

### Frontend Library
- **JavaScript:** `consent-manager.js` (minified, production-ready)
- **CSS:** Built-in themes (light, dark, auto)
- **Size:** ~15KB gzipped
- **CDN:** Hosted on Google Cloud Storage

### Backend (BigQuery Analytics)
- **Cloud Function:** Authenticated logging endpoint
- **BigQuery Dataset:** `consent_analytics`
- **Tables:**
  - `consent_events` (35+ columns with UTM tracking)
  - `api_keys` (authentication & domain whitelist)
- **Cost Dashboard:** Real-time cost monitoring
- **Auto-Deletion:** 2-year retention

### Web Portals
- **Admin Portal:** Generate & manage API keys
- **Customer Portal:** Public registration form

---

## 🌐 Live Demo & Portals

| Resource | URL |
|----------|-----|
| **Live Demo** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/ |
| **Admin Portal** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html |
| **Customer Registration** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html |

---

## 💰 Cost (Real Production Numbers)

At **15 million events/month**:

```
Storage:   ~11 THB/month
Streaming: ~28 THB/month
Queries:   FREE (< 1 TB tier)
──────────────────────────
Total:     ~39 THB/month ($1.05 USD)

Your usage: 0.78% of 5,000 THB budget
Status: ✅ 99% under budget
```

**Cost per 1M events:** ~2.6 THB (~$0.07 USD)

---

## 🏗️ Architecture

```
┌──────────────┐
│   Website    │
│  (Customer)  │
└──────┬───────┘
       │ X-API-Key header
       ↓
┌──────────────────┐
│  Cloud Function  │ ← Validates API key & domain
│ (logConsentAuth) │
└──────┬───────────┘
       │
       ↓
┌──────────────────┐
│    BigQuery      │
│ consent_events   │ ← Stores consent data
│ (37 columns)     │
└──────────────────┘

Daily at midnight:
└─→ Auto-delete data > 2 years old
```

---

## 🔐 Security Features

✅ **API Key Authentication** - Required for all logging  
✅ **Domain Whitelist** - Blocks unauthorized domains (supports wildcards)  
✅ **Rate Limiting** - Quota enforcement per client  
✅ **Usage Tracking** - Monitor events per API key  
✅ **IP Hashing** - GDPR-compliant IP logging (SHA-256)  
✅ **2-Year Retention** - Auto-deletion for compliance  

---

## 📊 Features

### Consent Management
- ✅ Multiple categories (necessary, analytics, marketing)
- ✅ Script blocking (data-category attribute)
- ✅ Revision management
- ✅ Auto-open on first visit
- ✅ Dark mode support
- ✅ Multi-language

### Analytics (BigQuery)
- ✅ Real-time event logging (<1 sec)
- ✅ UTM parameter tracking
- ✅ Google Ads (GCLID) & Facebook Ads (FBCLID)
- ✅ Device, browser, OS detection
- ✅ IP hashing + optional raw IP
- ✅ Thai/English action labels
- ✅ 13+ pre-built SQL queries

### Admin Features
- ✅ Web portal for API key generation
- ✅ Customer registration portal
- ✅ Cost monitoring dashboard
- ✅ Usage statistics per client
- ✅ CLI tool for automation

---

## 📚 Documentation

| Guide | Description | Size |
|-------|-------------|------|
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Complete setup in 3 steps | Quick |
| [ADMIN_GUIDE.md](./ADMIN_GUIDE.md) | Manage API keys, costs, security | Admin |
| [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) | Frontend integration examples | Developer |
| [BIGQUERY_GUIDE.md](./BIGQUERY_GUIDE.md) | Analytics, queries, cost monitoring | Data |

---

## 🧪 Testing

### Test Authenticated Logging:

```bash
curl -X POST https://logconsentauth-pxoxh5sfqa-as.a.run.app \
  -H "Content-Type: application/json" \
  -H "X-API-Key: demo-key-12345678-1234-1234-1234-123456789abc" \
  -d '{
    "event_type": "consent",
    "cookie": {"categories": ["necessary", "analytics"]},
    "acceptType": "custom",
    "pageUrl": "https://example.com",
    "version": "1.0.0"
  }'
```

**Expected:** `{"success": true, "client": "Demo Client"}`

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines.

---

## 📄 License

MIT License - See [LICENSE](./LICENSE) for details.

**Original Project:** [orestbida/cookieconsent](https://github.com/orestbida/cookieconsent)  
**White-labeled by:** Conicle AI  
**Date:** Feb 2026

---

## 🆘 Support

- 📖 **Documentation:** This repository
- 🐛 **Issues:** [GitHub Issues](https://github.com/tanapatj/prototype-cookie/issues)
- 📧 **Email:** admin@conicle.ai
- 🌐 **Live Demo:** [Try it now](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/)

---

## ✅ Production Ready Checklist

Before deploying:

- [ ] Schedule auto-deletion (see [SETUP_GUIDE.md](./SETUP_GUIDE.md))
- [ ] Generate production API key
- [ ] Update frontend with API key
- [ ] Test on staging environment
- [ ] Monitor costs in first month
- [ ] Set up budget alerts (optional)

---

## 🎯 Project Status

| Component | Status | URL/Location |
|-----------|--------|--------------|
| **Frontend Library** | ✅ Live | CDN on GCP |
| **Cloud Function** | ✅ Live | `logConsentAuth` (asia-southeast1) |
| **BigQuery Tables** | ✅ Live | `consent_analytics.*` |
| **Admin Portal** | ✅ Live | [admin.html](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html) |
| **Customer Portal** | ✅ Live | [register.html](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html) |
| **Cost Dashboard** | ✅ Live | BigQuery view |
| **Auto-Deletion** | ⏳ Ready | Need to schedule |

---

**Last Updated:** Feb 13, 2026  
**Version:** 1.0.0  
**Status:** 🚀 Production Ready  
**Monthly Cost:** ~39 THB (~$1.05 USD) for 15M events
