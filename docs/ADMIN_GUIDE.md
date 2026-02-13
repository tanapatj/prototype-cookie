# 👨‍💼 Admin Guide - ConsentManager

**Complete guide for managing API keys, monitoring costs, and system administration.**

---

## 🎯 Admin Dashboard

**Access the admin portal:**
```
https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html
```

**Features:**
- ✅ Generate API keys with web form (no CLI needed!)
- ✅ View all active API keys
- ✅ Monitor usage statistics per client
- ✅ Check cost dashboard
- ✅ Copy integration code

---

## 🔑 Generate API Key for Customer

### Method 1: Web Portal (Recommended) ✨

1. **Open Admin Portal:**  
   https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html

2. **Click "Generate API Key" tab**

3. **Fill in the form:**
   - Client Name: `Customer Company Name`
   - Domains (one per line):
     ```
     customer.com
     *.customer.com
     app.customer.com
     ```
   - Email: `tech@customer.com`
   - Monthly Quota: `5000000` (5M events/month, or leave blank for unlimited)
   - Expiration: Optional (e.g., `2027-12-31`)
   - Notes: `Production key for Customer X`

4. **Click "🔑 Generate API Key"**

5. **Copy the SQL command** shown (looks like this):
   ```sql
   bq query --use_legacy_sql=false "
   INSERT INTO \`conicle-ai-dev.consent_analytics.api_keys\` (...) VALUES (...)
   "
   ```

6. **Run the command** in your terminal or [BigQuery Console](https://console.cloud.google.com/bigquery?project=conicle-ai-dev)

7. **Copy the API key and send to customer** via email

**Done!** ✅

---

### Method 2: CLI Tool

```bash
cd bigquery

# Install dependencies (first time only)
npm install @google-cloud/bigquery uuid

# Generate API key
node admin-generate-api-key.js \
  --client="Customer Company" \
  --domains="customer.com,*.customer.com" \
  --email="tech@customer.com" \
  --quota=5000000 \
  --expires="2027-12-31" \
  --notes="Production key"
```

**Output:**
```
✅ API Key Generated Successfully!

🔑 API Key: cm_abc12345-def6-7890-abcd-ef1234567890
👤 Client: Customer Company
🌐 Allowed Domains:
   - customer.com
   - *.customer.com
📊 Monthly Quota: 5,000,000
```

---

## 📧 Email Template for Customers

When sending API keys, use this template:

```
Subject: Your ConsentManager API Key 🔑

Hi [Customer Name],

Your ConsentManager API key is ready!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 YOUR API KEY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cm_abc12345-def6-7890-abcd-ef1234567890

⚠️ Keep this secure! Don't share publicly or commit to git.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ APPROVED DOMAINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  • customer.com
  • *.customer.com
  • app.customer.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 INTEGRATION (5 MINUTES)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add this to your website:

const BIGQUERY_API_KEY = 'cm_abc12345-def6-7890-abcd-ef1234567890';
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

Full setup guide:
https://github.com/tanapatj/prototype-cookie/blob/main/docs/SETUP_GUIDE.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 YOUR PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Quota: 5,000,000 events/month
Cost: ~13 THB/month (~$0.35 USD)
Price per 1M events: ~2.6 THB (~$0.07 USD)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Questions? Reply to this email.

Best regards,
ConsentManager Team
```

---

## 📊 Monitor Usage & Costs

### Check All API Keys:

```sql
SELECT 
  client_name,
  api_key,
  allowed_domains,
  is_active,
  current_month_usage,
  monthly_quota,
  created_at
FROM `conicle-ai-dev.consent_analytics.api_keys`
WHERE is_active = TRUE
ORDER BY created_at DESC;
```

### Check Usage This Month:

```sql
SELECT 
  k.client_name,
  k.api_key,
  COUNT(e.event_id) as events_this_month,
  k.monthly_quota,
  ROUND(COUNT(e.event_id) * 100.0 / k.monthly_quota, 2) as percent_used,
  ROUND(COUNT(e.event_id) / 1000000.0 * 2.6, 2) as cost_thb
FROM `conicle-ai-dev.consent_analytics.api_keys` k
LEFT JOIN `conicle-ai-dev.consent_analytics.consent_events` e 
  ON k.api_key = e.api_key
  AND DATE(e.event_timestamp) >= DATE_TRUNC(CURRENT_DATE(), MONTH)
WHERE k.is_active = TRUE
GROUP BY k.client_name, k.api_key, k.monthly_quota
ORDER BY events_this_month DESC;
```

### Check Cost Dashboard:

```sql
SELECT * FROM `conicle-ai-dev.consent_analytics.cost_dashboard`;
```

**Output:**
```
Total Records: 15,000,000
Monthly Cost: 39 THB
Budget Remaining: 4,961 THB
Status: ✅ Under Budget (99%)
```

---

## 🔐 Manage API Keys

### Disable an API Key:

```sql
UPDATE `conicle-ai-dev.consent_analytics.api_keys`
SET is_active = FALSE,
    updated_at = CURRENT_TIMESTAMP()
WHERE api_key = 'cm_KEY-TO-DISABLE';
```

### Re-enable an API Key:

```sql
UPDATE `conicle-ai-dev.consent_analytics.api_keys`
SET is_active = TRUE,
    updated_at = CURRENT_TIMESTAMP()
WHERE api_key = 'cm_KEY-TO-ENABLE';
```

### Update Domain Whitelist:

```sql
UPDATE `conicle-ai-dev.consent_analytics.api_keys`
SET allowed_domains = ['newdomain.com', '*.newdomain.com', 'app.newdomain.com'],
    updated_at = CURRENT_TIMESTAMP()
WHERE api_key = 'cm_KEY-TO-UPDATE';
```

### Update Quota:

```sql
UPDATE `conicle-ai-dev.consent_analytics.api_keys`
SET monthly_quota = 10000000,  -- 10M events
    updated_at = CURRENT_TIMESTAMP()
WHERE api_key = 'cm_KEY-TO-UPDATE';
```

### Delete an API Key (Permanent):

```sql
DELETE FROM `conicle-ai-dev.consent_analytics.api_keys`
WHERE api_key = 'cm_KEY-TO-DELETE';
```

---

## 📈 Customer Registration Workflow

When customers register via the portal:

1. **Customer visits:**  
   https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html

2. **Customer fills form** and submits

3. **System generates Request ID** (e.g., `REQ-ABC123`)

4. **Registration logged to console** with full details

5. **Admin sees request** and copies the generated command

6. **Admin generates API key** using web portal or CLI

7. **Admin emails API key** to customer (use template above)

8. **Customer integrates** following the setup guide

**Done!** ✅

---

## 💰 Cost Monitoring

### Real-Time Cost Check:

**Via Web Portal:**
1. Open admin portal
2. Click "Usage Stats" tab
3. View costs per client

**Via BigQuery:**
```sql
SELECT 
  total_records,
  projected_monthly_events,
  total_monthly_cost_thb,
  budget_remaining_thb,
  CASE 
    WHEN total_monthly_cost_thb < 5000 THEN '✅ Under Budget'
    ELSE '⚠️ Over Budget'
  END as status
FROM `conicle-ai-dev.consent_analytics.cost_dashboard`;
```

### Set Budget Alert:

```bash
gcloud billing budgets create \
  --billing-account=YOUR-BILLING-ACCOUNT-ID \
  --display-name="ConsentManager Monthly Budget" \
  --budget-amount=5000THB \
  --threshold-rule=percent=80 \
  --threshold-rule=percent=100
```

---

## 🗑️ Data Retention (2-Year Auto-Deletion)

### Check if Scheduled:

```bash
bq ls --transfer_config --transfer_location=asia-southeast3
```

### Schedule Auto-Deletion (if not done):

```bash
bq query --use_legacy_sql=false \
  --schedule='every day 00:00' \
  --location=asia-southeast3 \
  --display_name='Delete old consent data (2+ years)' \
  "DELETE FROM \`conicle-ai-dev.consent_analytics.consent_events\`
   WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY)"
```

### Check Old Data:

```sql
SELECT 
  COUNT(*) as records_to_delete,
  MIN(event_timestamp) as oldest_record,
  MAX(event_timestamp) as newest_old_record
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);
```

---

## 🔒 Security Best Practices

### For Admin Portal:

⚠️ **Current Status:** Admin portal is public (anyone with URL can access)

**Recommended: Add Password Protection**

Edit `admin-portal/index.html` and add at the top of `<script>`:

```javascript
// Simple password protection
const ADMIN_PASSWORD = 'your-secure-password-here';
const entered = prompt('Enter admin password:');
if (entered !== ADMIN_PASSWORD) {
  document.body.innerHTML = '<h1>❌ Access Denied</h1>';
  throw new Error('Unauthorized');
}
```

**Or better: Move to Cloud Run with IAP**
- Deploy as Cloud Run service
- Enable Identity-Aware Proxy
- Only allow authenticated users in your organization

### For API Keys:

- ✅ **Never share** API keys publicly
- ✅ **Use environment variables** in production
- ✅ **Rotate keys** periodically (every 6-12 months)
- ✅ **Monitor usage** for suspicious activity
- ✅ **Set quotas** to prevent abuse
- ✅ **Disable unused keys** immediately

---

## 📊 Monthly Admin Tasks

### Week 1:
- [ ] Review cost dashboard
- [ ] Check usage per client
- [ ] Verify budget alerts are set

### Week 2:
- [ ] Process new registration requests
- [ ] Generate API keys for approved clients
- [ ] Send welcome emails

### Week 3:
- [ ] Review quota usage
- [ ] Identify clients near limits
- [ ] Send upgrade offers if needed

### Week 4:
- [ ] Monthly cost report
- [ ] Check for old data (should be auto-deleted)
- [ ] Review security logs

---

## 🧪 Testing

### Test API Key Generation:

1. Open admin portal
2. Generate test API key
3. Copy SQL command
4. Run in BigQuery
5. Verify key appears in api_keys table

### Test API Key Authentication:

```bash
# Valid key (should work)
curl -X POST https://logconsentauth-pxoxh5sfqa-as.a.run.app \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR-VALID-KEY" \
  -d '{"event_type": "consent", "cookie": {}, "version": "1.0.0"}'

# Invalid key (should fail)
curl -X POST https://logconsentauth-pxoxh5sfqa-as.a.run.app \
  -H "Content-Type: application/json" \
  -H "X-API-Key: invalid-key" \
  -d '{"event_type": "consent", "cookie": {}, "version": "1.0.0"}'
```

---

## 🆘 Troubleshooting

### Customer can't log events:
1. Check API key is active: `SELECT * FROM api_keys WHERE api_key = 'KEY'`
2. Verify domain is whitelisted
3. Check quota hasn't been exceeded
4. Test with curl command above

### Costs higher than expected:
1. Check cost dashboard
2. Review usage per client
3. Look for unusual spikes
4. Check if auto-deletion is running

### API key not working after generation:
1. Verify SQL command ran successfully
2. Check BigQuery job history
3. Confirm key exists in api_keys table
4. Wait 1-2 minutes for cache to clear

---

## 📚 Additional Resources

- **Setup Guide:** [SETUP_GUIDE.md](./SETUP_GUIDE.md)
- **Integration Guide:** [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)
- **BigQuery Guide:** [BIGQUERY_GUIDE.md](./BIGQUERY_GUIDE.md)
- **GitHub:** https://github.com/tanapatj/prototype-cookie

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Admin Portal** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html |
| **Customer Portal** | https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html |
| **BigQuery Console** | https://console.cloud.google.com/bigquery?project=conicle-ai-dev |
| **Cloud Functions** | https://console.cloud.google.com/functions?project=conicle-ai-dev |
| **Cost Dashboard** | Run: `SELECT * FROM cost_dashboard` |

---

**Questions?** Email: admin@conicle.ai

**Last Updated:** Feb 13, 2026
