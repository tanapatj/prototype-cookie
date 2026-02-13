# Database Integration Guide for ConsentManager

## TL;DR - Do I Need a Database?

**NO** - For basic GDPR compliance, you DON'T need a database! ✅

The library works completely client-side and stores consent in the user's browser cookie.

---

## 🍪 How Cookie Consent Works (Client-Side Only)

### Default Behavior (No Backend Required)

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────┐
│   Website   │ ----> │ ConsentManager   │ ----> │  Browser    │
│   Loads     │       │ Shows Banner     │       │  Cookie     │
└─────────────┘       └──────────────────┘       └─────────────┘
                                                   cm_cookie = {
                                                     categories: [...],
                                                     timestamp: ...
                                                   }
```

**What happens:**

1. User visits your website
2. ConsentManager checks if `cm_cookie` exists
3. If NO cookie → Show banner
4. If cookie exists → Apply saved preferences
5. User accepts/rejects → Save to browser cookie
6. Page reload → Read cookie, apply preferences

**No server involved!** Everything is stored in the user's browser.

---

## 📊 Cookie Structure

The consent cookie (`cm_cookie`) looks like this:

```json
{
  "level": ["necessary", "analytics"],
  "revision": 0,
  "data": null,
  "rfc_cookie": true,
  "consent_date": "2026-02-12T07:00:00.000Z",
  "consent_uuid": "abc123-def456-ghi789",
  "last_consent_update": "2026-02-12T07:00:00.000Z"
}
```

**Storage:** Browser cookie (6 months expiry by default)

**Size:** ~200-500 bytes (very small!)

**Access:** Only readable by your domain (secure, httpOnly optional)

---

## ✅ What You DON'T Need a Database For

You're already GDPR compliant without a database for:

- ✅ **Blocking tracking scripts** - Works client-side
- ✅ **Showing cookie banner** - Stored in browser
- ✅ **Saving user preferences** - Stored in browser cookie
- ✅ **Remembering consent** - Cookie persists across visits
- ✅ **Respecting user choice** - Library enforces it
- ✅ **Basic GDPR compliance** - You're good to go!

---

## 🗄️ When You WOULD Need a Database (Optional)

### Use Case 1: Audit Trail (Regulatory Compliance)

Some industries (finance, healthcare) require proof of consent:

**Example: Banking compliance**
```
"User ID 12345 accepted analytics cookies on 2026-02-12 at 14:30 UTC from IP 1.2.3.4"
```

**Implementation:**

```javascript
ConsentManager.run({
    // ... normal config ...
    
    onConsent: async function({cookie}) {
        // Log to your backend
        await fetch('https://api.conicle.ai/consent-log', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                userId: getCurrentUserId(), // if user is logged in
                consentData: cookie,
                timestamp: new Date().toISOString(),
                ipAddress: await getClientIP(),
                userAgent: navigator.userAgent,
                pageUrl: window.location.href
            })
        });
    }
});
```

**Database Schema Example:**

```sql
CREATE TABLE consent_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(255),          -- NULL if anonymous
    session_id VARCHAR(255),        -- For tracking anonymous users
    consent_uuid VARCHAR(255),      -- From cm_cookie
    accepted_categories JSON,       -- ["necessary", "analytics"]
    rejected_categories JSON,       -- ["marketing"]
    ip_address VARCHAR(45),         -- For audit
    user_agent TEXT,                -- Browser info
    page_url VARCHAR(500),          -- Where consent was given
    consent_timestamp DATETIME,     -- When
    revision INT,                   -- Consent policy version
    created_at DATETIME DEFAULT NOW()
);

CREATE INDEX idx_user_id ON consent_log(user_id);
CREATE INDEX idx_consent_uuid ON consent_log(consent_uuid);
CREATE INDEX idx_timestamp ON consent_log(consent_timestamp);
```

---

### Use Case 2: Analytics Dashboard

Track consent rates across your website:

**Questions you can answer:**
- "What % of users accept analytics?"
- "Which pages have highest rejection rates?"
- "How did consent rates change after we updated the banner?"

**Implementation:**

```javascript
onConsent: async function({cookie}) {
    // Aggregate data for analytics
    await fetch('https://api.conicle.ai/consent-analytics', {
        method: 'POST',
        body: JSON.stringify({
            acceptType: cookie.level.length === totalCategories ? 'all' : 'partial',
            categories: cookie.level,
            page: window.location.pathname,
            timestamp: new Date()
        })
    });
}
```

**Dashboard Queries:**

```sql
-- Consent acceptance rate
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN 'analytics' = ANY(accepted_categories) THEN 1 ELSE 0 END) as analytics_accepted,
    ROUND(SUM(CASE WHEN 'analytics' = ANY(accepted_categories) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as acceptance_rate
FROM consent_log
WHERE consent_timestamp >= NOW() - INTERVAL 30 DAY;

-- Consent by page
SELECT 
    page_url,
    COUNT(*) as consent_events,
    AVG(JSON_LENGTH(accepted_categories)) as avg_categories_accepted
FROM consent_log
GROUP BY page_url
ORDER BY consent_events DESC;
```

---

### Use Case 3: Cross-Device Sync

If users log in, sync consent across devices:

**Flow:**

```
┌────────────────┐         ┌─────────────┐         ┌────────────────┐
│  User's Phone  │  -----> │  Database   │ <-----  │  User's Laptop │
│  Accepts all   │         │  consent:   │         │  Loads consent │
└────────────────┘         │  {all: true}│         └────────────────┘
                           └─────────────┘
```

**Implementation:**

```javascript
// On login: Load saved consent from server
async function loadUserConsent(userId) {
    const response = await fetch(`https://api.conicle.ai/users/${userId}/consent`);
    const savedConsent = await response.json();
    
    if (savedConsent) {
        // Apply saved consent
        ConsentManager.acceptCategory(savedConsent.categories);
    }
}

// On consent change: Save to server
onConsent: async function({cookie}) {
    const userId = getCurrentUserId();
    if (userId) {
        await fetch(`https://api.conicle.ai/users/${userId}/consent`, {
            method: 'PUT',
            body: JSON.stringify({
                categories: cookie.level,
                timestamp: new Date()
            })
        });
    }
}
```

**Database Schema:**

```sql
CREATE TABLE user_consent (
    user_id VARCHAR(255) PRIMARY KEY,
    accepted_categories JSON,
    last_updated DATETIME,
    consent_uuid VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

### Use Case 4: Consent Receipts (Email Proof)

Send users an email receipt of their consent:

**Example Email:**

```
Subject: Your Cookie Consent Preferences - Conicle AI

Hi,

You have updated your cookie preferences on conicle.ai:

✓ Necessary cookies: Enabled (always on)
✓ Analytics cookies: Enabled
✗ Marketing cookies: Disabled

Date: February 12, 2026 at 2:30 PM
Consent ID: abc123-def456

You can change these preferences anytime at:
https://conicle.ai/cookie-settings

- Conicle AI Team
```

**Implementation:**

```javascript
onConsent: async function({cookie}) {
    const userEmail = getCurrentUserEmail();
    if (userEmail) {
        await fetch('https://api.conicle.ai/send-consent-receipt', {
            method: 'POST',
            body: JSON.stringify({
                email: userEmail,
                consentData: cookie,
                timestamp: new Date()
            })
        });
    }
}
```

---

## 🏗️ Architecture Options

### Option A: Client-Side Only (Recommended to Start)

```
┌──────────┐
│ Browser  │ --> ConsentManager --> Browser Cookie (cm_cookie)
└──────────┘
```

**Pros:**
- Zero backend cost
- Zero complexity
- GDPR compliant
- Works immediately
- No database to maintain

**Cons:**
- No audit trail
- No cross-device sync
- No analytics on consent rates

**Best for:** Most small-to-medium websites

---

### Option B: Client-Side + Logging Backend

```
┌──────────┐         ┌────────────┐         ┌──────────┐
│ Browser  │ ------> │ API Server │ ------> │ Database │
└──────────┘         └────────────┘         └──────────┘
     |                                            |
     v                                            v
Browser Cookie                              Audit Logs
```

**Pros:**
- Still works if backend is down (cookie fallback)
- Audit trail for compliance
- Analytics on consent rates
- Can send receipts

**Cons:**
- Requires backend API
- Database costs
- More complexity

**Best for:** Enterprises, regulated industries, large sites

---

### Option C: Server-Side Managed Consent

```
┌──────────┐         ┌────────────┐         ┌──────────┐
│ Browser  │ <-----> │ API Server │ <-----> │ Database │
└──────────┘         └────────────┘         └──────────┘
(Asks server for consent on every page load)
```

**Pros:**
- Centralized consent management
- Cross-device sync for logged-in users
- Real-time consent updates

**Cons:**
- Requires server on EVERY page load (latency!)
- More expensive (more API calls)
- More complex
- Doesn't work offline

**Best for:** Enterprise applications with user accounts

---

## 📋 Decision Tree: Do I Need a Database?

```
Do you have user accounts?
│
├─ NO --> Use client-side only (no database) ✅
│
└─ YES --> Do users use multiple devices?
           │
           ├─ NO --> Use client-side only (no database) ✅
           │
           └─ YES --> Do you want cross-device sync?
                      │
                      ├─ NO --> Use client-side only (no database) ✅
                      │
                      └─ YES --> Use database for sync

Are you in a regulated industry (finance, healthcare)?
│
├─ NO --> Use client-side only (no database) ✅
│
└─ YES --> Do you need audit trail?
           │
           ├─ NO --> Use client-side only (no database) ✅
           │
           └─ YES --> Use database for audit logs

Do you want to analyze consent rates?
│
├─ NO --> Use client-side only (no database) ✅
│
└─ YES --> Use database for analytics (optional)
```

**Bottom line:** Start with client-side only. Add database later if you need it.

---

## 🚀 Recommended Approach for Conicle AI

### Phase 1: Launch (Now) - No Database

```javascript
// Just use ConsentManager as-is
ConsentManager.run({
    categories: {
        necessary: { readOnly: true, enabled: true },
        analytics: {},
        marketing: {}
    },
    // ... translations
});
```

**Cost:** $0/month (just GCP CDN)

**Time to implement:** Already done! ✅

**GDPR compliant:** Yes ✅

---

### Phase 2: Add Logging (Optional - Later)

If you later decide you want analytics:

```javascript
ConsentManager.run({
    // ... existing config ...
    
    onConsent: function({cookie}) {
        // Add logging
        if (window.gtag) {
            gtag('event', 'cookie_consent', {
                categories: cookie.level.join(','),
                accept_type: cookie.level.length === 3 ? 'all' : 'partial'
            });
        }
        
        // OR send to your backend
        // fetch('/api/log-consent', { ... })
    }
});
```

**Cost:** Depends on backend (Cloud Functions = ~$0/month for low traffic)

**Time to implement:** 1-2 hours

**Benefit:** You get consent analytics in Google Analytics

---

## 💡 Best Practices

### 1. Start Simple

- Launch with client-side only
- Add database later if needed
- Most websites don't need it

### 2. Privacy First

If you do add logging:

- **Anonymous by default** - Don't log personal data
- **Hash user IDs** - Don't store raw user IDs
- **Minimal retention** - Delete logs after 1-2 years
- **Respect DNT** - Don't log if Do Not Track is enabled

```javascript
onConsent: async function({cookie}) {
    // Good: Anonymous logging
    await logConsent({
        consentId: cookie.consent_uuid,  // Unique but anonymous
        categories: cookie.level,
        timestamp: new Date()
        // No user ID, no IP, no personal data
    });
}
```

### 3. Performance

- **Don't block page load** - Log async in background
- **Don't wait for server** - Save to cookie first, log later
- **Handle failures gracefully** - If logging fails, consent still works

```javascript
onConsent: function({cookie}) {
    // Don't await! Fire and forget
    fetch('/api/log-consent', { ... })
        .catch(err => console.warn('Logging failed', err));
    
    // Page continues without waiting
}
```

---

## 🔒 GDPR Compliance Notes

### What GDPR Requires:

✅ **Explicit consent before tracking** - ConsentManager does this  
✅ **Easy to withdraw consent** - ConsentManager does this  
✅ **Clear information** - You write the text  
✅ **Records of consent** - Cookie stores this (client-side)

### What GDPR Does NOT Require:

❌ **Server-side database of consent** - Not required!  
❌ **Audit logs** - Only required for some industries  
❌ **Cross-device sync** - Not required  
❌ **Consent receipts** - Not required

**Source:** GDPR Article 7 (Conditions for consent)

---

## 📞 Summary

### For 99% of websites:

**You DON'T need a database!** ✅

Just use ConsentManager as-is:
- Consent is stored in browser cookie
- Scripts are blocked until consent
- GDPR compliant out of the box
- Zero backend cost

### You WOULD need a database if:

- You're in a regulated industry requiring audit trails
- You want consent rate analytics
- You need cross-device sync for logged-in users
- You want to email consent receipts

### Our recommendation for Conicle AI:

**Start without a database.** 

You're already GDPR compliant with the current setup. If you later want analytics on consent rates, you can add it in 1-2 hours.

---

## 📚 Further Reading

- [GDPR Article 7: Conditions for consent](https://gdpr-info.eu/art-7-gdpr/)
- [ICO Guide: Cookie consent](https://ico.org.uk/for-organisations/guide-to-pecr/cookies-and-similar-technologies/)
- [ConsentManager API Reference](./FRONTEND_IMPLEMENTATION_GUIDE.md)

---

**Questions?** You're good to go! 🚀

The library works perfectly without a database. Launch it and add logging later only if you need it.
