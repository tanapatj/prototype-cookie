# Google Analytics Integration Guide

## 🎯 Quick Answer

**Q: Does Google Analytics auto-detect cookie preferences?**

**A: NO!** You need to:
1. Add your GA tracking ID to the script
2. Wrap the script with `data-category="analytics" type="text/plain"`
3. ConsentManager will block it until user accepts

---

## 📊 How It Works

### Without ConsentManager (❌ NOT GDPR Compliant):

```html
<!-- BAD: This runs immediately, tracks without consent -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');  // Your GA4 Measurement ID
</script>
```

**Problem:** GA loads immediately, tracks users without asking! 🚫

---

### With ConsentManager (✅ GDPR Compliant):

```html
<!-- ConsentManager CSS & JS -->
<link rel="stylesheet" href="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css">
<script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"></script>

<!-- Initialize ConsentManager -->
<script>
ConsentManager.run({
    categories: {
        necessary: { readOnly: true, enabled: true },
        analytics: {},      // ← GA will be in this category
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
                },
                preferencesModal: {
                    title: 'Cookie Preferences',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject all',
                    savePreferencesBtn: 'Save preferences',
                    closeIconLabel: 'Close',
                    sections: [
                        {
                            title: 'Strictly Necessary Cookies',
                            description: 'Essential for the website to function.',
                            linkedCategory: 'necessary'
                        },
                        {
                            title: 'Analytics Cookies',
                            description: 'Help us understand how visitors use our website.',
                            linkedCategory: 'analytics'
                        }
                    ]
                }
            }
        }
    }
});
</script>

<!-- BLOCKED Google Analytics (only runs if user accepts) -->
<script data-category="analytics" type="text/plain">
  // This script is BLOCKED until user accepts "analytics"
  (function() {
    // Load gtag.js
    var script = document.createElement('script');
    script.async = true;
    script.src = 'https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX';  // ← YOUR GA4 ID
    document.head.appendChild(script);
    
    // Initialize GA
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX');  // ← YOUR GA4 ID (same as above)
  })();
</script>
```

**Key parts:**
- `data-category="analytics"` - Links to analytics category
- `type="text/plain"` - Blocks execution until consent
- `G-XXXXXXXXXX` - **Replace with YOUR GA4 Measurement ID**

---

## 🔍 Where to Find Your Google Analytics ID

### For GA4 (Google Analytics 4):

1. Go to https://analytics.google.com
2. Click **Admin** (bottom left gear icon)
3. Under **Property** → Click **Data Streams**
4. Click your website stream
5. Copy the **Measurement ID** (format: `G-XXXXXXXXXX`)

### For Universal Analytics (Old GA):

1. Go to https://analytics.google.com
2. Click **Admin**
3. Under **Property** → Click **Tracking Info** → **Tracking Code**
4. Copy the **Tracking ID** (format: `UA-XXXXXXXXX-X`)

---

## 🎯 Complete Example (Copy & Paste)

### Option A: Google Analytics 4 (GA4) - Recommended

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Website</title>
    
    <!-- ConsentManager CSS -->
    <link rel="stylesheet" href="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css">
</head>
<body>
    
    <h1>Welcome to my website</h1>
    <p>Your content here...</p>
    
    <!-- ConsentManager JS -->
    <script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"></script>
    
    <!-- Initialize ConsentManager -->
    <script>
    ConsentManager.run({
        categories: {
            necessary: { readOnly: true, enabled: true },
            analytics: {}
        },
        language: {
            default: 'en',
            translations: {
                en: {
                    consentModal: {
                        title: 'We use cookies',
                        description: 'We use cookies to analyze traffic and improve your experience.',
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
                                title: 'Analytics Cookies',
                                description: 'Help us understand visitor behavior using Google Analytics.',
                                linkedCategory: 'analytics'
                            }
                        ]
                    }
                }
            }
        }
    });
    </script>
    
    <!-- Google Analytics 4 (BLOCKED until consent) -->
    <script data-category="analytics" type="text/plain">
        // Replace G-XXXXXXXXXX with your actual GA4 Measurement ID
        (function() {
            var script = document.createElement('script');
            script.async = true;
            script.src = 'https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX';
            document.head.appendChild(script);
            
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-XXXXXXXXXX', {
                'anonymize_ip': true  // GDPR: Anonymize IP addresses
            });
            
            console.log('✅ Google Analytics loaded after user consent');
        })();
    </script>
    
</body>
</html>
```

**Don't forget:** Replace `G-XXXXXXXXXX` with your actual Measurement ID!

---

### Option B: Universal Analytics (Old GA)

```html
<!-- Universal Analytics (BLOCKED until consent) -->
<script data-category="analytics" type="text/plain">
    // Replace UA-XXXXXXXXX-X with your actual UA Tracking ID
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
    
    ga('create', 'UA-XXXXXXXXX-X', 'auto');  // ← YOUR UA ID
    ga('set', 'anonymizeIp', true);  // GDPR: Anonymize IP
    ga('send', 'pageview');
    
    console.log('✅ Google Analytics (UA) loaded after user consent');
</script>
```

---

## 🧪 How to Test

### Step 1: Test Blocking (User Rejects)

1. Open your website in **Incognito/Private mode**
2. Open DevTools (F12) → **Console** tab
3. Reject all cookies
4. Check console:
   - ❌ Should NOT see "✅ Google Analytics loaded"
   - ❌ Should NOT see any GA network requests
5. Open DevTools → **Network** tab → Filter "google-analytics" or "gtag"
   - ❌ Should be empty (no requests)

**This means GA is properly blocked!** ✅

---

### Step 2: Test Loading (User Accepts)

1. Reload page (still in Incognito)
2. Accept all cookies
3. Check console:
   - ✅ Should see "✅ Google Analytics loaded after user consent"
4. Open DevTools → **Network** tab → Filter "google-analytics" or "gtag"
   - ✅ Should see requests to GA servers
5. Open DevTools → **Application** tab → **Cookies**
   - ✅ Should see `_ga`, `_gid` cookies

**This means GA loaded correctly after consent!** ✅

---

### Step 3: Test in GA Real-Time

1. Go to https://analytics.google.com
2. Click **Reports** → **Realtime**
3. With your website open (and cookies accepted)
4. You should see yourself in the real-time report
5. Try clicking around your site → events appear in GA

**If you see yourself, it's working!** ✅

---

## 🔧 Advanced: Tracking Custom Events

Once user accepts, you can track custom events:

```html
<script data-category="analytics" type="text/plain">
    // Initialize GA (same as before)
    var script = document.createElement('script');
    script.async = true;
    script.src = 'https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX';
    document.head.appendChild(script);
    
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX');
    
    // Make gtag available globally for custom tracking
    window.gtag = gtag;
</script>

<!-- Later in your page: Track button clicks -->
<button onclick="if(window.gtag) gtag('event', 'button_click', {button_name: 'signup'})">
    Sign Up
</button>
```

**Note:** Custom events only fire if user accepted analytics!

---

## 🌍 Multiple Google Analytics Properties

If you have multiple GA properties (e.g., one for staging, one for production):

```html
<script data-category="analytics" type="text/plain">
    (function() {
        var script = document.createElement('script');
        script.async = true;
        
        // Load gtag.js with BOTH IDs
        var GA4_PROD = 'G-XXXXXXXXXX';  // Production
        var GA4_STAGE = 'G-YYYYYYYYYY'; // Staging
        
        // Use production ID by default, staging for dev
        var GA_ID = window.location.hostname === 'localhost' ? GA4_STAGE : GA4_PROD;
        
        script.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
        document.head.appendChild(script);
        
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', GA_ID, {
            'anonymize_ip': true
        });
    })();
</script>
```

---

## 🚨 Common Mistakes

### ❌ Mistake 1: Forgetting `type="text/plain"`

```html
<!-- WRONG: This will run immediately! -->
<script data-category="analytics">
    gtag('config', 'G-XXXXXXXXXX');  // Runs without consent!
</script>
```

**Fix:** Always add `type="text/plain"`

```html
<!-- CORRECT: This is blocked until consent -->
<script data-category="analytics" type="text/plain">
    gtag('config', 'G-XXXXXXXXXX');  // Blocked until user accepts
</script>
```

---

### ❌ Mistake 2: Loading GA Script in `<head>` Without Blocking

```html
<head>
    <!-- WRONG: This loads immediately! -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
</head>
```

**Fix:** Move it to `<body>` with `data-category`:

```html
<body>
    <!-- CORRECT: Load script dynamically after consent -->
    <script data-category="analytics" type="text/plain">
        var script = document.createElement('script');
        script.async = true;
        script.src = 'https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX';
        document.head.appendChild(script);
    </script>
</body>
```

---

### ❌ Mistake 3: Using Wrong Category Name

```html
<!-- WRONG: Category "google_analytics" doesn't exist -->
<script data-category="google_analytics" type="text/plain">
```

**Fix:** Use the category name you defined in `ConsentManager.run()`:

```javascript
ConsentManager.run({
    categories: {
        analytics: {}  // ← Use this name
    }
});
```

```html
<!-- CORRECT -->
<script data-category="analytics" type="text/plain">
```

---

## 📊 Check If User Accepted Analytics

Sometimes you want to check consent status before running code:

```javascript
// Check if analytics is accepted
if (ConsentManager.acceptedCategory('analytics')) {
    // User accepted analytics
    console.log('Analytics is enabled');
    
    // Safe to call gtag
    if (window.gtag) {
        gtag('event', 'custom_event');
    }
} else {
    // User rejected analytics
    console.log('Analytics is disabled');
}
```

---

## 🎯 For Conicle AI Specifically

### Your Setup Should Look Like:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Conicle AI</title>
    
    <!-- ConsentManager -->
    <link rel="stylesheet" href="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.css">
</head>
<body>
    
    <!-- Your website content -->
    
    <!-- ConsentManager -->
    <script src="https://storage.googleapis.com/consent-manager-cdn-tanapatj-jkt/v1.0.0/consent-manager.umd.js"></script>
    <script>
        ConsentManager.run({
            categories: {
                necessary: { readOnly: true, enabled: true },
                analytics: {}
            },
            language: {
                default: 'th',  // Thai default
                autoDetect: 'browser',
                translations: {
                    th: {
                        consentModal: {
                            title: 'เราใช้คุกกี้',
                            description: 'เราใช้คุกกี้เพื่อวิเคราะห์การใช้งานและปรับปรุงประสบการณ์ของคุณ',
                            acceptAllBtn: 'ยอมรับทั้งหมด',
                            acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
                            showPreferencesBtn: 'จัดการการตั้งค่า'
                        }
                    },
                    en: {
                        consentModal: {
                            title: 'We use cookies',
                            description: 'We use cookies to analyze usage and improve your experience.',
                            acceptAllBtn: 'Accept all',
                            acceptNecessaryBtn: 'Reject all',
                            showPreferencesBtn: 'Manage preferences'
                        }
                    }
                }
            }
        });
    </script>
    
    <!-- Google Analytics for Conicle AI -->
    <script data-category="analytics" type="text/plain">
        (function() {
            // Replace with your actual GA4 Measurement ID
            var GA_ID = 'G-XXXXXXXXXX';  // ← Get this from GA admin
            
            var script = document.createElement('script');
            script.async = true;
            script.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
            document.head.appendChild(script);
            
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', GA_ID, {
                'anonymize_ip': true,
                'cookie_flags': 'SameSite=None;Secure'
            });
            
            console.log('✅ Conicle AI Analytics loaded');
        })();
    </script>
    
</body>
</html>
```

---

## ✅ Checklist

Before going live:

- [ ] Got your GA4 Measurement ID from Google Analytics
- [ ] Replaced `G-XXXXXXXXXX` with your actual ID
- [ ] Added `data-category="analytics"` to script
- [ ] Added `type="text/plain"` to script
- [ ] Tested in Incognito mode
- [ ] Verified GA is BLOCKED when rejected
- [ ] Verified GA LOADS when accepted
- [ ] Checked GA Real-Time report shows data
- [ ] Added IP anonymization (`anonymize_ip: true`)

---

## 📞 Summary

**Q: Does GA auto-detect consent?**
**A: No!** You must:

1. ✅ Add your GA tracking ID (`G-XXXXXXXXXX`)
2. ✅ Wrap script with `data-category="analytics" type="text/plain"`
3. ✅ ConsentManager blocks it until user accepts

**Result:**
- User rejects → GA never loads → No tracking ✅
- User accepts → GA loads → Tracking starts ✅

**Still GDPR compliant because GA only loads after explicit consent!**

---

**Need help finding your GA ID?** Contact your marketing/analytics team or check Google Analytics admin panel.
