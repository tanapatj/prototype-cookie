# Web Portals Guide - Admin & Customer Registration

## Portal Overview

### 1. Admin Portal
**URL:** https://storage.googleapis.com/consentmanager/admin.html

**Purpose:** API key generation and management interface

**Features:**
- ✅ Generate new API keys with web form
- ✅ View all API keys and their status
- ✅ Monitor usage statistics per client
- ✅ Copy API keys and integration code
- ✅ Dashboard with real-time stats

---

### 2. Customer Registration Portal
**URL:** https://storage.googleapis.com/consentmanager/register.html

**Purpose:** Self-service registration interface for API access requests

**Features:**
- ✅ Simple registration form
- ✅ Domain whitelist input with examples
- ✅ Request tracking with unique ID
- ✅ Auto-generates command for admin
- ✅ Professional UI/UX

---

## Operational Workflow

### Customer Registration Process:

```
1. Customer visits: 
   https://storage.googleapis.com/consentmanager/register.html

2. Customer fills form:
   - Company name
   - Contact info
   - Domains to whitelist
   - Expected volume
   
3. Customer submits
   ↓
4. Request ID generated (e.g., REQ-ABC123)
   ↓
5. System logs registration data to browser console
   ↓
6. Confirmation displayed: "Request submitted, API key within 24 hours"
```

### Admin API Key Generation Flow:

```
1. Admin opens:
   https://storage.googleapis.com/consentmanager/admin.html

2. Admin clicks "Generate API Key" tab

3. Admin fills form:
   - Client name
   - Domains (one per line)
   - Email
   - Quota (optional)
   - Expiration date (optional)
   
4. Admin clicks "Generate API Key"
   ↓
5. Portal generates:
   ✅ Unique API key (cm_xxxxx-xxxx-xxxx)
   ✅ Integration code
   ✅ SQL INSERT command
   
6. Admin copies SQL command
   ↓
7. Admin runs command in BigQuery Console
   ↓
8. API key is activated!
   ↓
9. Admin sends API key to customer via email
```

---

## 📋 Step-by-Step: Generate API Key for Customer

### Method 1: Using Admin Portal (Web UI) ✨

**Step 1:** Open Admin Portal
```
https://storage.googleapis.com/consentmanager/admin.html
```

**Step 2:** Fill in the form
- Client Name: `Acme Corporation`
- Domains: 
  ```
  acme.com
  *.acme.com
  app.acme.com
  ```
- Email: `tech@acme.com`
- Quota: `5000000` (5M events/month)

**Step 3:** Click "🔑 Generate API Key"

**Step 4:** Copy the SQL command shown (it will look like this):
```sql
bq query --use_legacy_sql=false "
INSERT INTO \`cookiemanager-488405.consent_analytics.api_keys\`
  (api_key, api_key_hash, client_name, client_email, allowed_domains, 
   is_active, monthly_quota, current_month_usage, created_at, created_by, expires_at, notes)
VALUES 
  (
    'cm_abc12345-def6-7890-abcd-ef1234567890',
    TO_HEX(SHA256('cm_abc12345-def6-7890-abcd-ef1234567890')),
    'Acme Corporation',
    'tech@acme.com',
    [\"acme.com\",\"*.acme.com\",\"app.acme.com\"],
    TRUE,
    5000000,
    0,
    CURRENT_TIMESTAMP(),
    'admin',
    NULL,
    NULL
  )
"
```

**Step 5:** Run the command in your terminal or BigQuery Console

**Step 6:** Copy the API key and send to customer via email

**Done!** ✅ Customer can now use their API key.

---

### Method 2: Using CLI Tool (Original) 

```bash
cd bigquery
node admin-generate-api-key.js \
  --client="Acme Corporation" \
  --domains="acme.com,*.acme.com" \
  --email="tech@acme.com" \
  --quota=5000000
```

---

## 📧 Email Template for Customers

When you generate an API key, send this email:

```
Subject: Your ConsentManager API Key 🔑

Hi [Customer Name],

Your ConsentManager API key is ready!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 YOUR API KEY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cm_abc12345-def6-7890-abcd-ef1234567890

⚠️ Keep this secure! Don't share publicly.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ APPROVED DOMAINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  • acme.com
  • *.acme.com
  • app.acme.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 QUICK START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add to your website:

<script src="https://storage.googleapis.com/consentmanager/consent-manager.js"></script>

<script>
const BIGQUERY_API_KEY = 'YOUR-API-KEY-HERE';
const BIGQUERY_LOG_URL = 'https://logconsentauth-rcpavhoe7a-as.a.run.app';

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

// Initialize
window.ConsentManager = ConsentManager.run({
  onConsent: ({cookie}) => logToBigQuery('consent', {cookie}),
  onChange: ({cookie}) => logToBigQuery('change', {cookie})
});
</script>

Full guide: https://github.com/tanapatj/prototype-cookie

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 PRICING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your quota: 5,000,000 events/month
Cost: ~13 THB/month (~$0.35 USD)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Questions? Reply to this email.

Best regards,
ConsentManager Team
```

---

## 🔗 Portal Links

| Portal | URL | Who Uses It |
|--------|-----|-------------|
| **Admin Portal** | https://storage.googleapis.com/consentmanager/admin.html | Your team (internal) |
| **Customer Portal** | https://storage.googleapis.com/consentmanager/register.html | Customers (public) |
| **Demo** | https://storage.googleapis.com/consentmanager/index.html | Demo/testing |

---

## 🔐 Security Recommendations

### Admin Portal:
⚠️ **Currently public!** Anyone with the URL can access.

**To secure it:**

**Option 1: Cloud Identity-Aware Proxy (IAP)**
```bash
# Enable IAP for the bucket (requires setup)
# Only allows authenticated users in your organization
```

**Option 2: Move to Cloud Run + Authentication**
```bash
# Deploy as a Cloud Run service with:
# - --allow-unauthenticated=false
# - Firebase Auth or Google Sign-In
```

**Option 3: Simple Password Protection** (Quick fix)
Add to `admin-portal/index.html`:
```javascript
// At the top of <script>
const ADMIN_PASSWORD = 'your-secure-password';
const entered = prompt('Enter admin password:');
if (entered !== ADMIN_PASSWORD) {
  document.body.innerHTML = '<h1>Access Denied</h1>';
  throw new Error('Unauthorized');
}
```

**Option 4: IP Whitelist** (Best for now)
```bash
# Only allow access from your office IP
# Configure in Cloud Storage bucket permissions
```

---

## 📊 Admin Portal Features

### Tab 1: Generate API Key
- Web form to generate keys
- Auto-generates UUID
- Creates SQL INSERT command
- Shows integration code
- Copy buttons for easy use

### Tab 2: Manage Keys
- View all API keys
- See status (active/inactive)
- Check usage statistics
- Enable/disable keys
- Direct link to BigQuery

### Tab 3: Usage Stats
- Monthly usage per client
- Quota tracking
- Cost estimates
- Performance metrics

---

## 🎨 Customer Portal Features

### Registration Form:
- Company name
- Contact person
- Email
- Domain whitelist
- Expected volume
- Use case description

### After Submission:
- Unique request ID
- Confirmation message
- Email notification promise
- Console logs full data

### Admin Notification:
The registration logs everything to browser console:
```javascript
{
  "requestId": "REQ-ABC123",
  "companyName": "Acme Corp",
  "email": "tech@acme.com",
  "domains": ["acme.com", "*.acme.com"],
  "timestamp": "2026-02-13T..."
}
```

Plus the exact command to generate their API key!

---

## 🔄 Workflow Integration

### Current (Manual):
```
Customer → Registration Form → Console Log → Admin sees → Admin generates key → Email to customer
```

### Future (Automated):
```
Customer → Registration Form → Backend API → Database → Auto-generate key → Auto-email
```

**To automate:**
1. Create a Cloud Function to receive form data
2. Store in Firestore or send to Slack/Email
3. Admin approves in Slack
4. Auto-generate and email API key

---

## 🧪 Testing

### Test Admin Portal:
1. Open: https://storage.googleapis.com/consentmanager/admin.html
2. Fill form with test data
3. Click "Generate API Key"
4. Copy SQL command
5. Run in BigQuery
6. Verify key works with curl

### Test Customer Portal:
1. Open: https://storage.googleapis.com/consentmanager/register.html
2. Fill registration form
3. Submit
4. Check browser console for logged data
5. Use the logged command to generate API key

---

## 📝 Customization

### Branding:
Edit these files to customize:
- `admin-portal/index.html` - Change colors, logo, text
- `customer-portal/index.html` - Change branding

### Email Template:
The customer portal includes an email template generator function.
Check console for copy-paste ready email.

### Features:
Add more tabs to admin portal:
- Cost analytics
- Client management
- Logs viewer
- Real-time dashboard

---

## 🎯 Quick Links

| Resource | Link |
|----------|------|
| **Customer Registration** | https://storage.googleapis.com/consentmanager/register.html |
| **Admin Portal** | https://storage.googleapis.com/consentmanager/admin.html |
| **BigQuery Console** | https://console.cloud.google.com/bigquery?project=cookiemanager-488405 |
| **Documentation** | https://github.com/tanapatj/prototype-cookie |

---

## ✅ Summary

**For Customers:**
1. Visit registration portal
2. Fill form with domains
3. Get request ID
4. Receive API key via email (24h)

**For Admins:**
1. Open admin portal
2. Fill form or use customer's info
3. Click generate
4. Copy SQL command
5. Run in BigQuery
6. Send API key to customer

**Both portals are live and ready to use!** 🚀

---

**Last Updated:** Feb 13, 2026  
**Status:** ✅ Live and Ready  
**Access:** Public (recommend securing admin portal)
