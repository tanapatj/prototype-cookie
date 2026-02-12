# BigQuery Consent Logging

Real-time consent event logging to Google BigQuery for analytics and compliance.

## 📁 What's in this folder

| File | Description |
|------|-------------|
| `schema.sql` | BigQuery table schema (columns, partitioning, clustering) |
| `deployment-guide.md` | **START HERE** - Complete deployment instructions |
| `example-queries.sql` | 12 ready-to-use SQL queries for analytics |
| `example-integration.html` | Working HTML example with BigQuery logging |
| `cloud-function/` | Node.js Cloud Function code for logging endpoint |

## 🚀 Quick Start

### 1. Deploy (15 minutes)

Follow the step-by-step guide in **`deployment-guide.md`**

**Summary:**
```bash
# Create BigQuery table
bq mk --dataset consent_analytics
bq mk --table consent_analytics.consent_events schema.sql

# Deploy Cloud Function
cd cloud-function
gcloud functions deploy logConsent \
  --runtime=nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region=asia-southeast3
```

### 2. Integrate (5 minutes)

Add to your website (see `example-integration.html` for full code):

```javascript
ConsentManager.run({
    // ... your config ...
    
    onConsent: async function(event) {
        await fetch('https://YOUR-FUNCTION-URL.a.run.app', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                event_type: 'consent',
                cookie: event.cookie,
                pageUrl: window.location.href,
                version: '1.0.0'
            })
        });
    }
});
```

### 3. Query (1 minute)

Run queries from `example-queries.sql`:

```sql
-- Today's acceptance rate
SELECT 
  accept_type,
  COUNT(*) as total,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) = CURRENT_DATE()
GROUP BY accept_type;
```

## 📊 What Gets Logged

### ✅ Logged by default:
- Event type (consent, change, first_consent)
- Accepted/rejected categories
- **Hashed IP address** (SHA-256)
- Browser, OS, device type
- Page URL, referrer
- Timestamp, session ID

### ❌ NOT logged (privacy-first):
- Raw IP address (unless explicitly enabled)
- User ID (unless user is logged in and you set it)
- Personal information

**Result:** GDPR compliant by default! ✅

## 💰 Cost

**Estimated for 1,000 consents/day:**
- BigQuery storage: FREE (< 10 GB/month)
- BigQuery queries: FREE (< 1 TB/month)
- Cloud Function: FREE (< 2M invocations/month)

**Total: $0-2/month** 🎉

## 📈 What You Can Analyze

With the included queries (`example-queries.sql`), you can answer:

1. **Acceptance Rates**
   - How many users accept all vs reject all?
   - Which categories are most accepted?
   - Trends over time

2. **User Behavior**
   - Do users change their preferences?
   - How long before they change their mind?
   - First-time vs returning user patterns

3. **Device/Browser**
   - Do mobile users accept more/less?
   - Chrome vs Safari acceptance rates
   - Device-specific patterns

4. **Geography**
   - Which countries have highest acceptance?
   - Regional compliance patterns

5. **Page Context**
   - Which pages show the banner most?
   - Does landing page affect acceptance?

## 🔒 Privacy & GDPR

### What we do right:

✅ **IP Hashing:** All IPs hashed with SHA-256  
✅ **Anonymous:** No user ID by default  
✅ **Minimal:** Only log what's necessary  
✅ **Transparent:** Users know they're tracked (consent banner)  
✅ **Retention:** Automatic cleanup after 2 years (optional query included)

### Recommendations:

1. **Update Privacy Policy:** Mention consent logging
2. **Data Retention:** Run cleanup query monthly
3. **User Rights:** Provide way to request data deletion

## 🐛 Troubleshooting

### Function not receiving data?

```bash
# Check logs
gcloud functions logs read logConsent --limit=50

# Test manually
curl -X POST https://YOUR-URL.a.run.app \
  -H "Content-Type: application/json" \
  -d '{"event_type": "consent", "cookie": {"categories": ["necessary"]}, "version": "1.0.0"}'
```

### No data in BigQuery?

```bash
# Check table exists
bq show consent_analytics.consent_events

# Check recent data
bq query 'SELECT COUNT(*) FROM `conicle-ai-dev.consent_analytics.consent_events` WHERE DATE(event_timestamp) = CURRENT_DATE()'
```

## 📚 More Info

- Full deployment guide: **`deployment-guide.md`**
- Example queries: **`example-queries.sql`**
- Working HTML example: **`example-integration.html`**
- Cloud Function code: **`cloud-function/index.js`**

## 🎯 Need Help?

1. Check **`deployment-guide.md`** - Has troubleshooting section
2. Test with **`example-integration.html`** - See logs in real-time
3. Run queries from **`example-queries.sql`** - Verify data flow

---

**Ready to deploy?** Start with `deployment-guide.md` 🚀
