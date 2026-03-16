# ConsentManager - Frontend Implementation Guide

## 📋 Quick Overview

**What:** GDPR/CCPA-compliant cookie consent manager  
**Where:** Hosted on GCP Cloud Storage (Bangkok region)  
**Cost:** ~$0.01/month (vs Cookiebot: $100-300/month)  
**Status:** ✅ Production Ready

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Add to Your HTML

```html
<!DOCTYPE html>
<html>
<head>
    <!-- 1. Load CSS -->
    <link rel="stylesheet" href="https://storage.googleapis.com/consentmanager/v1.0.0/consent-manager.css">
</head>
<body>
    
    <!-- Your website content -->
    
    <!-- 2. Load JavaScript -->
    <script src="https://storage.googleapis.com/consentmanager/v1.0.0/consent-manager.umd.js"></script>
    
    <!-- 3. Initialize -->
    <script>
        ConsentManager.run({
            categories: {
                necessary: {
                    readOnly: true,  // Can't be disabled
                    enabled: true
                },
                analytics: {},       // Google Analytics, etc.
                marketing: {}        // Facebook Pixel, etc.
            },
            language: {
                default: 'en',
                translations: {
                    en: {
                        consentModal: {
                            title: 'We use cookies',
                            description: 'We use essential cookies to make our site work and optional cookies to improve your experience.',
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
                                    description: 'We use cookies to enhance your browsing experience.'
                                },
                                {
                                    title: 'Strictly Necessary Cookies',
                                    description: 'These cookies are essential for the website to function.',
                                    linkedCategory: 'necessary'
                                },
                                {
                                    title: 'Analytics Cookies',
                                    description: 'Help us understand how visitors use our website.',
                                    linkedCategory: 'analytics'
                                },
                                {
                                    title: 'Marketing Cookies',
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
</body>
</html>
```

**That's it!** The cookie banner will appear on first visit.

---

## 🔒 Block Tracking Scripts Until User Accepts

### Google Analytics Example

**Before (runs immediately - ❌ NOT GDPR compliant):**
```html
<script>
    // This runs immediately, NOT compliant!
    ga('create', 'UA-XXXXX-Y', 'auto');
    ga('send', 'pageview');
</script>
```

**After (only runs if user accepts - ✅ GDPR compliant):**
```html
<script data-category="analytics" type="text/plain">
    // This ONLY runs if user accepts "analytics"
    ga('create', 'UA-XXXXX-Y', 'auto');
    ga('send', 'pageview');
</script>
```

### Facebook Pixel Example

```html
<script data-category="marketing" type="text/plain">
    !function(f,b,e,v,n,t,s)
    {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
    n.callMethod.apply(n,arguments):n.queue.push(arguments)};
    if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
    n.queue=[];t=b.createElement(e);t.async=!0;
    t.src=v;s=b.getElementsByTagName(e)[0];
    s.parentNode.insertBefore(t,s)}(window, document,'script',
    'https://connect.facebook.net/en_US/fbevents.js');
    fbq('init', 'YOUR_PIXEL_ID');
    fbq('track', 'PageView');
</script>
```

### Google Tag Manager Example

```html
<script data-category="analytics" type="text/plain">
    (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
    new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
    j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
    'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer','GTM-XXXXXX');
</script>
```

**Key rule:** Add `data-category="category-name"` and `type="text/plain"` to any tracking script.

---

## 🎨 Customization Options

### Change Layout & Position

```javascript
ConsentManager.run({
    guiOptions: {
        consentModal: {
            layout: 'box',           // 'box', 'cloud', 'bar'
            position: 'bottom right', // 'top left', 'middle center', etc.
            flipButtons: false,       // Flip button order
            equalWeightButtons: true  // GDPR-compliant equal styling
        },
        preferencesModal: {
            layout: 'box',            // 'box', 'bar'
            position: 'left'          // 'left' or 'right' (for bar layout)
        }
    },
    // ... rest of config
});
```

### Dark Mode

Add this class to your `<html>` tag:
```html
<html class="cm--darkmode">
```

Or toggle it dynamically:
```javascript
document.documentElement.classList.add('cm--darkmode');
```

### Thai Language (ภาษาไทย)

```javascript
language: {
    default: 'th',
    translations: {
        th: {
            consentModal: {
                title: 'เราใช้คุกกี้',
                description: 'เราใช้คุกกี้เพื่อปรับปรุงประสบการณ์ของคุณ',
                acceptAllBtn: 'ยอมรับทั้งหมด',
                acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
                showPreferencesBtn: 'จัดการการตั้งค่า'
            },
            preferencesModal: {
                title: 'การตั้งค่าคุกกี้',
                acceptAllBtn: 'ยอมรับทั้งหมด',
                acceptNecessaryBtn: 'ปฏิเสธทั้งหมด',
                savePreferencesBtn: 'บันทึก',
                closeIconLabel: 'ปิด',
                sections: [
                    {
                        title: 'คุกกี้ที่จำเป็น',
                        description: 'คุกกี้ที่จำเป็นสำหรับการทำงานของเว็บไซต์',
                        linkedCategory: 'necessary'
                    },
                    {
                        title: 'คุกกี้วิเคราะห์',
                        description: 'ช่วยให้เราเข้าใจว่าผู้เยี่ยมชมใช้เว็บไซต์อย่างไร',
                        linkedCategory: 'analytics'
                    },
                    {
                        title: 'คุกกี้การตลาด',
                        description: 'ใช้เพื่อแสดงโฆษณาที่ตรงกับความสนใจ',
                        linkedCategory: 'marketing'
                    }
                ]
            }
        }
    }
}
```

---

## 🎛️ Advanced Usage

### Check if User Accepted a Category

```javascript
if (ConsentManager.acceptedCategory('analytics')) {
    // User accepted analytics - safe to track
    trackEvent('page_view');
}
```

### Programmatically Accept/Reject

```javascript
// Accept all
ConsentManager.acceptCategory('all');

// Accept specific categories
ConsentManager.acceptCategory(['analytics', 'marketing']);

// Reject all (necessary only)
ConsentManager.acceptCategory([]);
```

### Listen to Consent Changes

```javascript
window.addEventListener('cm:onChange', function(event) {
    console.log('User changed preferences:', event.detail);
    
    // Reload tracking scripts if needed
    if (event.detail.changedCategories.includes('analytics')) {
        // Re-initialize analytics
    }
});

window.addEventListener('cm:onConsent', function(event) {
    console.log('User gave consent:', event.detail);
});
```

### Add "Cookie Settings" Button to Your Page

```html
<!-- This button will open the preferences modal -->
<button data-cc="show-preferencesModal">Cookie Settings</button>
```

Or use JavaScript:
```javascript
document.querySelector('#cookie-settings-btn').addEventListener('click', function() {
    ConsentManager.showPreferences();
});
```

---

## 📍 CDN URLs (Bangkok Region)

### Primary Files (Use These)

```
JavaScript (UMD):
https://storage.googleapis.com/consentmanager/v1.0.0/consent-manager.umd.js

CSS:
https://storage.googleapis.com/consentmanager/v1.0.0/consent-manager.css
```

### ES Modules (For Modern Build Tools)

```javascript
import * as ConsentManager from 'https://storage.googleapis.com/consentmanager/v1.0.0/consent-manager.esm.js';
```

### Core Library (No GUI - API Only)

If you want to build your own UI:
```
https://storage.googleapis.com/consentmanager/v1.0.0/core/consent-manager-core.umd.js
```

---

## ✅ Production Readiness Checklist

Before going live, make sure:

- [ ] **Test in all browsers**
  - Chrome ✅
  - Safari ✅
  - Firefox ✅
  - Edge ✅
  - Mobile browsers (iOS Safari, Chrome Mobile) ✅

- [ ] **Test scenarios**
  - [ ] First-time visitor sees banner
  - [ ] Accepting all enables tracking scripts
  - [ ] Rejecting all blocks tracking scripts
  - [ ] Preferences modal works
  - [ ] Cookie persists across page reloads
  - [ ] "Cookie Settings" button works
  - [ ] Works on mobile devices

- [ ] **Legal compliance**
  - [ ] Privacy policy link added to footer
  - [ ] Cookie policy page created
  - [ ] All tracking scripts have `data-category` attribute

- [ ] **Performance**
  - [ ] Total size: ~77KB (very lightweight ✅)
  - [ ] CDN loads in <200ms from Bangkok
  - [ ] No impact on page load speed

---

## 🐛 Troubleshooting

### Banner Doesn't Appear

**Check 1:** Open browser console (F12), look for errors  
**Check 2:** Make sure CDN URLs are correct and loading  
**Check 3:** The banner only appears on first visit (clear cookies to test again)

### Scripts Not Being Blocked

**Issue:** Tracking scripts run even when rejected  
**Fix:** Make sure scripts have both attributes:
```html
<script data-category="analytics" type="text/plain">
```

### Banner Appears Every Time

**Issue:** Cookie not being saved  
**Check:** 
1. Make sure cookies are enabled in browser
2. Check if your site is HTTPS (required for `secure: true` cookies)
3. Check browser console for errors

### CORS Errors

**Issue:** `Access-Control-Allow-Origin` error  
**Fix:** Already configured! If you still see this, contact DevOps.

---

## 📊 Analytics Integration Examples

### Google Analytics 4

```html
<!-- Google Analytics setup -->
<script data-category="analytics" type="text/plain">
    // Global site tag (gtag.js)
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX');
</script>
```

### Hotjar

```html
<script data-category="analytics" type="text/plain">
    (function(h,o,t,j,a,r){
        h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
        h._hjSettings={hjid:YOUR_HOTJAR_ID,hjsv:6};
        a=o.getElementsByTagName('head')[0];
        r=o.createElement('script');r.async=1;
        r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
        a.appendChild(r);
    })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
</script>
```

### Mixpanel

```html
<script data-category="analytics" type="text/plain">
    (function(c,a){if(!a.__SV){var b=window;try{var d,m,j,k=b.location,f=k.hash;d=function(a,b){return(m=a.match(RegExp(b+"=([^&]*)")))?m[1]:null};f&&d(f,"state")&&(j=JSON.parse(decodeURIComponent(d(f,"state"))),"mpeditor"===j.action&&(b.sessionStorage.setItem("_mpcehash",f),history.replaceState(j.desiredHash||"",c.title,k.pathname+k.search)))}catch(n){}var l,h;window.mixpanel=a;a._i=[];a.init=function(b,d,g){function c(b,i){var a=i.split(".");2==a.length&&(b=b[a[0]],i=a[1]);b[i]=function(){b.push([i].concat(Array.prototype.slice.call(arguments,0)))}}var e=a;"undefined"!==typeof g?e=a[g]=[]:g="mixpanel";e.people=e.people||[];e.toString=function(b){var a="mixpanel";"mixpanel"!==g&&(a+="."+g);b||(a+=" (stub)");return a};e.people.toString=function(){return e.toString(1)+".people (stub)"};l="disable time_event track track_pageview track_links track_forms track_with_groups add_group set_group remove_group register register_once alias unregister identify name_tag set_config reset opt_in_tracking opt_out_tracking has_opted_in_tracking has_opted_out_tracking clear_opt_in_out_tracking start_batch_senders people.set people.set_once people.unset people.increment people.append people.union people.track_charge people.clear_charges people.delete_user people.remove".split(" ");for(h=0;h<l.length;h++)c(e,l[h]);var f="set set_once union unset remove delete".split(" ");e.get_group=function(){function a(c){b[c]=function(){call2_args=arguments;call2=[c].concat(Array.prototype.slice.call(call2_args,0));e.push([d,call2])}}for(var b={},d=["get_group"].concat(Array.prototype.slice.call(arguments,0)),c=0;c<f.length;c++)a(f[c]);return b};a._i.push([b,d,g])};a.__SV=1.2;b=c.createElement("script");b.type="text/javascript";b.async=!0;b.src="undefined"!==typeof MIXPANEL_CUSTOM_LIB_URL?MIXPANEL_CUSTOM_LIB_URL:"file:"===c.location.protocol&&"//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js".match(/^\/\//)?"https://cdn.mxpnl.com/libs/mixpanel-2-latest.min.js":"//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js";d=c.getElementsByTagName("script")[0];d.parentNode.insertBefore(b,d)}})(document,window.mixpanel||[]);
    mixpanel.init("YOUR_TOKEN");
</script>
```

---

## 🌍 Multi-Language Support

### Adding Multiple Languages

```javascript
language: {
    default: 'en',
    autoDetect: 'browser',  // Auto-detect user's browser language
    translations: {
        en: {
            consentModal: { /* English */ },
            preferencesModal: { /* English */ }
        },
        th: {
            consentModal: { /* Thai */ },
            preferencesModal: { /* Thai */ }
        },
        zh: {
            consentModal: { /* Chinese */ },
            preferencesModal: { /* Chinese */ }
        }
    }
}
```

---

## 🎨 Styling & Themes

### Custom Colors (CSS Variables)

```css
:root {
    /* Background */
    --cm-bg: #ffffff;
    
    /* Text colors */
    --cm-primary-color: #2c2f31;
    --cm-secondary-color: #5e6266;
    
    /* Primary button (Accept All) */
    --cm-btn-primary-bg: #2563eb;
    --cm-btn-primary-color: #ffffff;
    --cm-btn-primary-hover-bg: #1d4ed8;
    
    /* Secondary button (Reject/Preferences) */
    --cm-btn-secondary-bg: #f3f4f6;
    --cm-btn-secondary-color: #374151;
    
    /* Border radius */
    --cm-modal-border-radius: 0.5rem;
    --cm-btn-border-radius: 0.4rem;
}
```

### Full Dark Mode

```html
<html class="cm--darkmode">
```

Or toggle dynamically:
```javascript
// Enable dark mode
document.documentElement.classList.add('cm--darkmode');

// Disable dark mode
document.documentElement.classList.remove('cm--darkmode');
```

---

## 🧪 Testing Guide

### Test Locally

1. **First Visit Test**
   - Clear cookies: Chrome DevTools → Application → Clear site data
   - Reload page → Banner should appear
   - Click "Accept all" → Banner disappears
   - Check Application → Cookies → Should see `cm_cookie`

2. **Rejection Test**
   - Clear cookies again
   - Click "Reject all"
   - Open console → Check that tracking scripts didn't run
   - Verify `cm_cookie` only has "necessary" category

3. **Preferences Test**
   - Click "Cookie Settings" button (or `data-cc="show-preferencesModal"`)
   - Toggle categories on/off
   - Click "Save preferences"
   - Verify only selected scripts run

### Test Tracking Script Blocking

```javascript
// Add this to console after accepting
ConsentManager.getUserPreferences();

// Output shows:
{
    acceptType: "all",
    acceptedCategories: ["necessary", "analytics", "marketing"],
    rejectedCategories: [],
    acceptedServices: {...},
    rejectedServices: {...}
}
```

---

## 🔧 API Reference

### Show/Hide Modals

```javascript
ConsentManager.show();              // Show consent modal
ConsentManager.hide();              // Hide consent modal
ConsentManager.showPreferences();   // Show preferences modal
ConsentManager.hidePreferences();   // Hide preferences modal
```

### Accept/Reject Categories

```javascript
ConsentManager.acceptCategory('all');                     // Accept all
ConsentManager.acceptCategory([]);                        // Reject all
ConsentManager.acceptCategory(['analytics']);             // Accept only analytics
ConsentManager.acceptCategory('all', ['marketing']);      // Accept all except marketing
```

### Check Status

```javascript
ConsentManager.validConsent();              // Returns true if user has given consent
ConsentManager.acceptedCategory('analytics'); // Returns true if analytics is accepted
ConsentManager.getUserPreferences();        // Returns full preferences object
ConsentManager.getCookie();                 // Returns the cookie content
```

### Reset (for testing)

```javascript
ConsentManager.reset(true);  // Reset and delete cookie
location.reload();           // Reload to see banner again
```

---

## 📦 Project Resources

| Resource | Location |
|----------|----------|
| **GitHub Repository** | https://github.com/tanapatj/prototype-cookie |
| **GCP Bucket** | `consentmanager` |
| **Region** | Asia-Southeast3 (Bangkok 🇹🇭) |
| **Documentation** | `/docs` folder in repo |
| **Demo Examples** | `/demo` folder in repo |

---

## 💰 Cost & Performance

| Metric | Value |
|--------|-------|
| **Bundle Size** | 23 KB (JS) + 31 KB (CSS) = 54 KB gzipped |
| **Load Time** | ~100-200ms from Bangkok |
| **Monthly Cost** | ~$0.01 (storage) + bandwidth costs |
| **Bandwidth Cost** | $0.12 per GB (1GB free/month) |
| **Estimated Monthly** | $0.01 - $0.50 for low-medium traffic |

**Comparison:**
- Cookiebot: $100-300/month
- OneTrust: $1000+/month
- **Your solution: <$1/month** 🎉

---

## 🚨 Common Mistakes to Avoid

### ❌ DON'T DO THIS:
```html
<!-- Missing type="text/plain" - script will run immediately! -->
<script data-category="analytics">
    ga('send', 'pageview');  // ❌ NOT BLOCKED
</script>
```

### ✅ DO THIS:
```html
<!-- Properly blocked until consent -->
<script data-category="analytics" type="text/plain">
    ga('send', 'pageview');  // ✅ BLOCKED until user accepts
</script>
```

---

## 📞 Support

**Questions?** Check:
1. Full documentation: https://github.com/tanapatj/prototype-cookie/tree/main/docs
2. Examples: https://github.com/tanapatj/prototype-cookie/tree/main/demo
3. Contact: Data/AI Engineering Team (that's you! 😄)

---

## 🎯 Quick Integration Checklist

- [ ] Add CSS link to `<head>`
- [ ] Add JS script before `</body>`
- [ ] Configure categories
- [ ] Add translations (EN/TH)
- [ ] Block all tracking scripts with `data-category`
- [ ] Add "Cookie Settings" link to footer
- [ ] Test on desktop & mobile
- [ ] Verify GDPR compliance
- [ ] Deploy to production

---

**Last Updated:** February 12, 2026  
**Version:** 1.0.0  
**Maintained by:** Data Engineering Team @ Conicle AI
