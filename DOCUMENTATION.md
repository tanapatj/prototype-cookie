# 📚 ConsentManager Documentation

**Complete documentation for ConsentManager - GDPR-compliant cookie consent with BigQuery analytics.**

---

## 🚀 Quick Navigation

### For Everyone:
- **[README.md](./README.md)** - Project overview & quick start

### For Developers:
- **[docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md)** - Complete setup (5 minutes)
- **[docs/INTEGRATION_GUIDE.md](./bigquery/deployment-guide.md)** - Frontend examples (GA, FB Pixel, etc.)

### For Admins:
- **[docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md)** - Manage API keys & monitor costs
- **[docs/BIGQUERY_GUIDE.md](./bigquery/deployment-guide.md)** - BigQuery queries & analytics

### For Contributing:
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Development guidelines

---

## 📖 Documentation Structure

```
/
├── README.md                      ⭐ START HERE
├── DOCUMENTATION.md               📚 This file (navigation)
├── CONTRIBUTING.md                🤝 Development guide
│
├── docs/
│   ├── SETUP_GUIDE.md            🚀 3-step setup
│   ├── ADMIN_GUIDE.md            👨‍💼 Admin tasks & API keys
│   └── archive/                   📦 Old documentation (reference)
│
├── bigquery/
│   ├── deployment-guide.md        📊 BigQuery setup & queries
│   ├── example-queries.sql        💾 13+ ready-to-use queries
│   ├── cost-monitoring.sql        💰 Cost dashboard
│   ├── admin-generate-api-key.js  🔑 CLI tool
│   └── ...
│
├── admin-portal/
│   └── index.html                 🌐 Web UI for API key management
│
└── customer-portal/
    └── index.html                 📝 Public registration form
```

---

## 🎯 Quick Start By Role

### I'm a **Frontend Developer**
1. Read: [README.md](./README.md)
2. Follow: [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md)
3. Customize: [bigquery/deployment-guide.md](./bigquery/deployment-guide.md) (search for "Integration")

### I'm an **Admin / CTO**
1. Read: [README.md](./README.md)
2. Generate API keys: [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md)
3. Monitor costs: [bigquery/cost-monitoring.sql](./bigquery/cost-monitoring.sql)

### I'm a **Customer**
1. Register: https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html
2. Receive API key via email
3. Follow setup: [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md)

### I'm a **Data Analyst**
1. Access BigQuery: https://console.cloud.google.com/bigquery?project=conicle-ai-dev
2. Run queries: [bigquery/example-queries.sql](./bigquery/example-queries.sql)
3. View dashboard: `SELECT * FROM cost_dashboard`

---

## 🌐 Web Resources

| Resource | URL | Description |
|----------|-----|-------------|
| **Live Demo** | [demo](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/) | Try ConsentManager |
| **Admin Portal** | [admin.html](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html) | Generate API keys |
| **Customer Portal** | [register.html](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html) | Request access |
| **BigQuery Console** | [BigQuery](https://console.cloud.google.com/bigquery?project=conicle-ai-dev) | View your data |
| **GitHub Repo** | [GitHub](https://github.com/tanapatj/prototype-cookie) | Source code |

---

## 📋 Common Tasks

### Setup ConsentManager on my website:
→ [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md) (Step 1)

### Get an API key:
→ [Register here](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/register.html) or [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md) (Step 2)

### Enable BigQuery logging:
→ [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md) (Step 3)

### Generate API key for customer:
→ [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) (Generate API Key section)

### Check costs:
→ [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) (Monitor Usage & Costs section)

### Query consent data:
→ [bigquery/example-queries.sql](./bigquery/example-queries.sql)

### Add Google Analytics:
→ [bigquery/deployment-guide.md](./bigquery/deployment-guide.md) (search for "Google Analytics")

### Add Thai language:
→ [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md) (Customization section)

### Schedule auto-deletion:
→ [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) (Data Retention section)

---

## 🆘 Troubleshooting

### Banner not showing?
→ [docs/SETUP_GUIDE.md](./docs/SETUP_GUIDE.md) (Troubleshooting section)

### BigQuery not logging?
→ [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) (Troubleshooting section)

### Cost too high?
→ [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) (Cost Monitoring section)

### API key not working?
→ [docs/ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) (Manage API Keys section)

---

## 📊 Key Files

### Configuration:
- `admin-portal/index.html` - Admin web UI
- `customer-portal/index.html` - Registration web UI
- `bigquery/cloud-function-auth/index.js` - Authentication logic

### Database:
- `bigquery/api-keys-schema.sql` - API keys table
- `bigquery/schema.sql` - Main events table
- `bigquery/cost-monitoring.sql` - Cost dashboard

### Scripts:
- `bigquery/admin-generate-api-key.js` - CLI tool
- `bigquery/auto-delete-old-data.sql` - 2-year deletion
- `bigquery/example-queries.sql` - Analytics queries

---

## ✅ Documentation Checklist

Before going to production:

- [ ] Read README.md
- [ ] Complete SETUP_GUIDE.md (all 3 steps)
- [ ] Test on staging environment
- [ ] Admin: Generate production API key
- [ ] Admin: Schedule auto-deletion
- [ ] Admin: Set up cost alerts
- [ ] Bookmark admin portal
- [ ] Save BigQuery console link
- [ ] Share customer portal with clients

---

## 💡 Tips

**For fastest setup:**
1. Start with [README.md](./README.md)
2. Jump to [SETUP_GUIDE.md](./docs/SETUP_GUIDE.md)
3. Done in 5 minutes!

**For admins:**
- Bookmark [admin portal](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/admin.html)
- Keep [ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md) handy
- Check costs weekly

**For developers:**
- All examples are in [bigquery/deployment-guide.md](./bigquery/deployment-guide.md)
- Test with demo API key: `demo-key-12345678-1234-1234-1234-123456789abc`
- Check browser console for errors

---

## 🔄 Updates

**Last Updated:** Feb 13, 2026

**Recent Changes:**
- ✅ Reorganized documentation (consolidated 13 → 4 main docs)
- ✅ Created web portals (admin & customer)
- ✅ Added API key authentication
- ✅ Implemented cost monitoring dashboard
- ✅ Added 2-year auto-deletion

---

## 📧 Support

**Email:** admin@conicle.ai  
**GitHub Issues:** https://github.com/tanapatj/prototype-cookie/issues  
**Live Demo:** https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/

---

**Happy consent managing!** 🍪🎉
