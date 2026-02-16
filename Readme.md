# ConsentManager

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)]()
[![GCP](https://img.shields.io/badge/Hosted-Google%20Cloud-4285F4.svg)]()

A **lightweight**, **GDPR/PDPA-compliant** cookie consent management platform with real-time BigQuery analytics. Built with vanilla JavaScript -- zero dependencies on the client side.

**Built by Conicle AI Data Engineering Team**

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [BigQuery Analytics (Optional)](#bigquery-analytics-optional)
- [Admin & Customer Portals](#admin--customer-portals)
- [API Reference](#api-reference)
- [Security](#security)
- [Project Structure](#project-structure)
- [Development](#development)
- [Deployment](#deployment)
- [Cost](#cost)
- [Documentation](#documentation)
- [License](#license)

---

## Overview

ConsentManager is a white-labeled cookie consent solution that provides:

1. **Client-side consent library** -- A lightweight JS widget that shows a consent banner, manages cookie categories, and blocks tracking scripts until the user gives consent.
2. **BigQuery analytics backend** -- An optional authenticated Cloud Function that streams consent events to Google BigQuery for real-time analytics.
3. **Management portals** -- Admin and customer-facing web portals for API key management and domain registration.

### Why ConsentManager?

| Feature | ConsentManager | Cookiebot | OneTrust |
|---|---|---|---|
| Monthly cost | **~$1** | $100-300 | $1,000+ |
| Self-hosted | Yes | No | No |
| Open source | Yes (MIT) | No | No |
| No vendor lock-in | Yes | No | No |
| BigQuery integration | Built-in | No | No |
| Thai language support | Yes | Limited | Yes |

---

## Architecture

```
User Browser
    |
    |--> GCP Cloud Storage CDN        (consent-manager.js + CSS)
    |       Region: asia-southeast3 (Bangkok)
    |
    |--> Cloud Function (Auth)        (Consent event logging)
    |       Region: asia-southeast1 (Singapore)
    |       Auth: API Key + Domain Whitelist
    |       |
    |       +--> BigQuery
    |               Dataset: consent_analytics
    |               Tables: consent_events (37 cols), api_keys
    |
    +--> Browser Cookie (cm_cookie)   (Local consent storage)

Management:
    Admin Portal  -->  API key generation & usage monitoring
    Customer Portal  -->  Self-service domain registration
```

---

## Features

### Consent Management (Client-Side)
- Lightweight, zero-dependency vanilla JavaScript (~14KB gzipped)
- GDPR, CCPA, ePrivacy, and Thailand PDPA compliant
- Customizable consent banner and preferences modal
- Multiple layouts: box, cloud, bar
- Dark/light color scheme
- Multi-language support (18+ languages including Thai)
- RTL language support
- Script blocking via `data-category` attribute until user consents
- Per-service toggling within categories
- Cookie autoclear on consent revocation
- Revision management for re-consent
- Full TypeScript definitions

### Analytics Backend (Optional)
- Real-time consent event streaming to BigQuery
- API key authentication with domain whitelist
- Monthly quota enforcement per client
- 37-column event schema (consent data, UTM, device info, geolocation)
- Thai/English action labels
- IP hashing (SHA-256) for privacy compliance
- Automated 2-year data retention
- Pre-built analytics queries (13+ SQL templates)
- Cost dashboard with budget monitoring

### Management Portals
- Admin Portal: Generate API keys, monitor usage, view cost dashboard
- Customer Portal: Self-service domain registration with request tracking

---

## Quick Start

### Basic Setup (No Backend Required)

Add these three lines to your HTML:

```html
<!-- 1. CSS in <head> -->
<link rel="stylesheet" href="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css">

<!-- 2. JS before </body> -->
<script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"></script>

<!-- 3. Initialize -->
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
                    description: 'This website uses cookies to enhance your browsing experience.',
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
                        {
                            title: 'Cookie Usage',
                            description: 'We use cookies to ensure basic functionality and improve your experience.'
                        },
                        {
                            title: 'Strictly Necessary',
                            description: 'Essential cookies required for the website to function.',
                            linkedCategory: 'necessary'
                        },
                        {
                            title: 'Analytics',
                            description: 'Help us understand how visitors interact with our website.',
                            linkedCategory: 'analytics'
                        },
                        {
                            title: 'Marketing',
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

That's it. The consent banner will appear, and user preferences are stored in the browser cookie (`cm_cookie`). **No backend or database required.**

### Block Tracking Scripts (GDPR Compliance)

Wrap your tracking scripts so they only run after consent:

```html
<!-- Before: Runs immediately (NOT compliant) -->
<script>
    ga('send', 'pageview');
</script>

<!-- After: Blocked until user accepts "analytics" (COMPLIANT) -->
<script data-category="analytics" type="text/plain">
    ga('send', 'pageview');
</script>
```

---

## Installation

### Via CDN (Recommended)

```html
<link rel="stylesheet" href="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css">
<script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"></script>
```

### Via npm / pnpm

```bash
npm install consent-manager
# or
pnpm install consent-manager
```

```javascript
import * as ConsentManager from 'consent-manager';
import 'consent-manager/dist/consent-manager.css';
```

### ES Module

```html
<script type="module">
import * as ConsentManager from 'https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.esm.js';
</script>
```

---

## Usage

### Thai Language Example

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
                    description: 'เว็บไซต์นี้ใช้คุกกี้เพื่อปรับปรุงประสบการณ์การใช้งาน',
                    acceptAllBtn: 'ยอมรับทั้งหมด',
                    acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
                    showPreferencesBtn: 'จัดการการตั้งค่า'
                }
            }
        }
    }
});
```

### Custom Appearance

```javascript
ConsentManager.run({
    guiOptions: {
        consentModal: {
            layout: 'box',              // 'box', 'cloud', or 'bar'
            position: 'bottom right',   // 'bottom left', 'middle center', etc.
        }
    },
    // ...categories and language config
});
```

```css
/* Custom brand colors */
:root {
    --cm-btn-primary-bg: #FF6B35;
    --cm-btn-primary-hover-bg: #E55A2B;
    --cm-modal-border-radius: 16px;
}
```

### Dark Mode

```html
<html class="cm--darkmode">
```

### Event Listeners

```javascript
window.addEventListener('cm:onConsent', function({ detail }) {
    console.log('User consented:', detail.cookie.categories);
});

window.addEventListener('cm:onChange', function({ detail }) {
    console.log('Preferences changed:', detail.changedCategories);
});
```

---

## BigQuery Analytics (Optional)

For organizations that need consent analytics, ConsentManager includes a ready-to-deploy BigQuery logging pipeline.

### Setup

1. **Deploy the Cloud Function:**

```bash
cd bigquery/cloud-function-auth
npm install
gcloud functions deploy logConsentAuth \
    --runtime nodejs20 \
    --trigger-http \
    --region asia-southeast1 \
    --project your-project-id
```

2. **Create BigQuery tables:**

```bash
bq query --use_legacy_sql=false < bigquery/schema.sql
bq query --use_legacy_sql=false < bigquery/api-keys-schema.sql
```

3. **Generate an API key:**

```bash
node bigquery/admin-generate-api-key.js \
    --client="Your Company" \
    --domains="yourdomain.com,*.yourdomain.com" \
    --email="admin@yourdomain.com" \
    --quota=5000000
```

4. **Add logging to your site** (API key should be injected server-side):

```javascript
window.addEventListener('cm:onConsent', async function({ detail }) {
    await fetch('YOUR_CLOUD_FUNCTION_URL', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-API-Key': 'YOUR_API_KEY'  // Inject server-side, never hardcode
        },
        body: JSON.stringify({
            event_type: 'consent',
            cookie: detail.cookie,
            pageUrl: window.location.href,
            version: '1.0.0'
        })
    });
});
```

5. **Schedule data retention cleanup (2-year policy):**

```bash
bq query --use_legacy_sql=false \
    --schedule='every day 00:00' \
    --location=asia-southeast3 \
    "DELETE FROM \`your-project.consent_analytics.consent_events\`
     WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY)"
```

### Pre-Built Analytics Queries

See `bigquery/example-queries.sql` and `bigquery/example-queries-enhanced.sql` for 13+ ready-to-use queries including:

- Daily consent overview and acceptance rates
- Device/browser breakdown
- Geographic distribution
- Campaign performance (UTM tracking)
- Hourly activity patterns
- Cost projections

---

## Admin & Customer Portals

### Admin Portal (`admin-portal/index.html`)

- Generate API keys via web form
- View and manage active API keys
- Monitor per-client usage statistics
- Access cost dashboard

### Customer Portal (`customer-portal/index.html`)

- Self-service domain registration
- Request tracking with unique IDs
- Automated admin notification

---

## API Reference

### Core Methods

| Method | Description |
|---|---|
| `ConsentManager.run(config)` | Initialize with configuration |
| `ConsentManager.show()` | Show consent banner |
| `ConsentManager.hide()` | Hide consent banner |
| `ConsentManager.showPreferences()` | Show preferences modal |
| `ConsentManager.hidePreferences()` | Hide preferences modal |
| `ConsentManager.acceptCategory(categories)` | Accept specific categories |
| `ConsentManager.acceptedCategory(name)` | Check if category is accepted |
| `ConsentManager.getUserPreferences()` | Get current consent state |
| `ConsentManager.getCookie(field?)` | Get cookie data |
| `ConsentManager.validConsent()` | Check if consent is valid |
| `ConsentManager.reset(deleteCookie?)` | Reset all state |
| `ConsentManager.setLanguage(lang)` | Change language |
| `ConsentManager.setCookieData({value, mode})` | Store custom data in cookie |
| `ConsentManager.eraseCookies(names, path?, domain?)` | Erase specific cookies |
| `ConsentManager.loadScript(src, attrs?)` | Dynamically load a script |

### Events

| Event | Fired When |
|---|---|
| `cm:onFirstConsent` | User gives consent for the first time |
| `cm:onConsent` | On every page load where consent exists |
| `cm:onChange` | User changes their preferences |
| `cm:onModalShow` | Any modal is shown |
| `cm:onModalHide` | Any modal is hidden |
| `cm:onModalReady` | Modal DOM is ready |

Full API documentation is available in the `docs/` folder.

---

## Security

A white-box penetration test was conducted on this project. See `PENTEST_REPORT.md` for the full report.

### Key Security Measures

- **API key authentication** with domain whitelist for BigQuery logging
- **CORS restricted** to validated origins only
- **IP address hashing** (SHA-256 with salt) for privacy compliance
- **Input sanitization** against XSS and SQL injection
- **Monthly quota enforcement** to prevent abuse
- **HTTPS-only** communication
- **No secrets in client-side code** -- API keys must be injected server-side

### Security Best Practices

- Store API keys in environment variables or GCP Secret Manager
- Set the `IP_SALT` environment variable on your Cloud Function (never use the default)
- Rotate API keys periodically
- Monitor usage patterns for anomalies
- Review the `PENTEST_REPORT.md` for full findings and remediation status

---

## Project Structure

```
cookieconsent-master/
├── src/                          # Library source code
│   ├── core/                     # Core library (api, config, modals, global state)
│   └── utils/                    # Utilities (cookies, language, scripts, DOM)
├── dist/                         # Built library files (UMD, ESM, CSS)
├── types/                        # TypeScript definitions
├── tests/                        # Jest test suite
├── demo/                         # Local demo pages
├── demo-live/                    # Production live demo (GCP hosted)
│   └── index.html                # Interactive demo with BigQuery logging
├── admin-portal/                 # Admin portal for API key management
│   └── index.html
├── customer-portal/              # Customer registration portal
│   └── index.html
├── bigquery/                     # BigQuery integration
│   ├── cloud-function/           # Cloud Function (unauthenticated, deprecated)
│   ├── cloud-function-auth/      # Cloud Function (authenticated, production)
│   ├── schema.sql                # BigQuery event table schema
│   ├── api-keys-schema.sql       # BigQuery API keys table schema
│   ├── admin-generate-api-key.js # CLI tool for API key generation
│   ├── example-queries.sql       # Analytics SQL queries
│   ├── example-queries-enhanced.sql
│   ├── cost-monitoring.sql       # Cost tracking queries
│   └── auto-delete-old-data.sql  # 2-year retention cleanup
├── docs/                         # VitePress documentation site
├── playground/                   # Development playground
├── PENTEST_REPORT.md             # Security penetration test report
├── IMPLEMENTATION_SUMMARY.md     # Full technical implementation details
└── package.json
```

---

## Development

### Prerequisites

- [Node.js LTS](https://nodejs.org/) (v18+)
- [pnpm](https://pnpm.io/) (`npm i -g pnpm`)

### Setup

```bash
pnpm install
```

### Dev Mode (watch)

```bash
pnpm dev
```

### Build

```bash
pnpm build
```

### Run Tests

```bash
pnpm test
```

### Documentation Site

```bash
pnpm docs:dev    # Development server
pnpm docs:build  # Build static site
```

---

## Deployment

### CDN Assets (GCP Cloud Storage)

The built library is hosted on GCP Cloud Storage in the Bangkok region:

| File | URL |
|---|---|
| JS (UMD) | `https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js` |
| JS (ESM) | `https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.esm.js` |
| CSS | `https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css` |

### Cloud Function

The authenticated logging endpoint runs on GCP Cloud Functions (asia-southeast1).

### BigQuery

Dataset `consent_analytics` in GCP project, partitioned by date, clustered by event type and accept type.

---

## Cost

### CDN Hosting Only (No Analytics)

| Item | Monthly Cost |
|---|---|
| GCP Cloud Storage (< 1 GB) | ~$0.01 |
| Bandwidth (moderate traffic) | ~$0.00-0.50 |
| **Total** | **< $1/month** |

### With BigQuery Analytics (15M Events/Month)

| Item | Monthly Cost |
|---|---|
| BigQuery Storage (15 GB) | ~$0.30 |
| BigQuery Streaming Inserts | ~$0.75 |
| BigQuery Queries (< 1 TB free tier) | $0.00 |
| Cloud Function (free tier) | $0.00 |
| **Total** | **~$1.05/month (~39 THB)** |

---

## Documentation

| Document | Description |
|---|---|
| `Readme.md` | This file -- project overview |
| `PENTEST_REPORT.md` | Security assessment (19 findings, 7 critical/high remediated) |
| `IMPLEMENTATION_SUMMARY.md` | Full technical architecture and specifications |
| `FRONTEND_IMPLEMENTATION_GUIDE.md` | Step-by-step frontend integration guide |
| `DATABASE_INTEGRATION_GUIDE.md` | When and how to add BigQuery logging |
| `GOOGLE_ANALYTICS_INTEGRATION.md` | GA integration with consent blocking |
| `ENTERPRISE_FEATURES.md` | Security, scalability, and cost optimization details |
| `PORTALS_GUIDE.md` | Admin and customer portal usage |
| `bigquery/deployment-guide.md` | BigQuery infrastructure setup |
| `bigquery/example-queries.sql` | Ready-to-use analytics SQL queries |
| `docs/` | Full API documentation (VitePress) |

---

## Live Demo

**Interactive Demo:** [Open Demo](https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/index.html)

The demo includes:
- Interactive consent banner with accept/reject controls
- Real-time tracking script blocking demonstration
- Event log showing all consent events
- API method testing buttons
- BigQuery logging integration

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

**Original project:** [cookieconsent](https://github.com/orestbida/cookieconsent) by orestbida
**White-labeled and extended:** February 2026 by Conicle AI

---

## Contact

- **Team:** AI Tech Capabilities @ Conicle
- **Email:** tanapatj@conicle.com
- **GitHub:** [github.com/tanapatj/prototype-cookie](https://github.com/tanapatj/prototype-cookie)
