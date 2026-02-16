/**
 * Cloud Function: Log Consent Events to BigQuery
 * 
 * Deployed to: GCP Cloud Functions
 * Trigger: HTTPS
 * Runtime: Node.js 20
 * Region: asia-southeast3 (Bangkok)
 */

const { BigQuery } = require('@google-cloud/bigquery');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

const bigquery = new BigQuery();
const DATASET_ID = 'consent_analytics';
const TABLE_ID = 'consent_events';

// ========================================
// DDOS PROTECTION
// ========================================

const rateLimitStore = new Map();
const RATE_LIMIT_WINDOW = 10000; // 10 seconds
const RATE_LIMIT_MAX_REQUESTS = 5; // 5 requests per 10 seconds (stricter for unauthenticated)

function checkRateLimit(ip) {
  if (!ip) return true;
  
  const now = Date.now();
  const key = ip;
  
  // Clean up old entries
  if (Math.random() < 0.01) {
    for (const [k, v] of rateLimitStore.entries()) {
      if (now > v.resetTime) {
        rateLimitStore.delete(k);
      }
    }
  }
  
  if (!rateLimitStore.has(key)) {
    rateLimitStore.set(key, {count: 1, resetTime: now + RATE_LIMIT_WINDOW});
    return true;
  }
  
  const record = rateLimitStore.get(key);
  
  if (now > record.resetTime) {
    record.count = 1;
    record.resetTime = now + RATE_LIMIT_WINDOW;
    return true;
  }
  
  if (record.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false;
  }
  
  record.count++;
  return true;
}

/**
 * Hash IP address for privacy (GDPR compliant)
 */
function hashIP(ip) {
  if (!ip) return null;
  const salt = process.env.IP_SALT;
  if (!salt) {
    console.warn('WARNING: IP_SALT environment variable is not set. IP hashing may be insecure.');
  }
  return crypto.createHash('sha256').update(ip + (salt || 'conicle-salt')).digest('hex');
}

/**
 * Parse User-Agent string (detailed)
 */
function parseUserAgent(ua) {
  if (!ua) return { browser_name: null, browser_version: null, os_name: null, device_type: 'unknown', full_ua: null };
  
  // Simplified parsing (in production, use a library like 'ua-parser-js')
  const browser = ua.match(/(Chrome|Firefox|Safari|Edge|Opera|WebView)\/(\d+\.\d+)/i) || [];
  const os = ua.match(/(Windows NT|Mac OS X|Linux|Android|iOS)[\s\/]?([\d._]+)?/i) || [];
  const isMobile = /Mobile|Android|iPhone|iPad/i.test(ua);
  const isTablet = /iPad|Android(?!.*Mobile)/i.test(ua);
  
  return {
    browser_name: browser[1] || 'Unknown',
    browser_version: browser[2] || null,
    os_name: os[1] || 'Unknown',
    device_type: isTablet ? 'tablet' : (isMobile ? 'mobile' : 'desktop'),
    full_ua: ua.substring(0, 500) // Store full UA (truncated)
  };
}

/**
 * Parse UTM parameters and campaign data from URL
 */
function parseCampaignData(url) {
  if (!url) return {};
  
  try {
    const urlObj = new URL(url);
    const params = urlObj.searchParams;
    
    return {
      utm_source: params.get('utm_source') || null,
      utm_medium: params.get('utm_medium') || null,
      utm_campaign: params.get('utm_campaign') || null,
      utm_term: params.get('utm_term') || null,
      utm_content: params.get('utm_content') || null,
      gclid: params.get('gclid') || null, // Google Ads
      fbclid: params.get('fbclid') || null, // Facebook Ads
      campaignid: params.get('campaignid') || null
    };
  } catch (e) {
    return {};
  }
}

/**
 * Get action label (Thai/English)
 */
function getActionLabel(eventType, acceptType) {
  const labels = {
    'first_consent': {
      'all': 'ได้รับการยืนยัน (ทั้งหมด)',
      'necessary': 'ปฏิเสธทั้งหมด',
      'custom': 'เลือกบางส่วน',
      'default': 'ยืนยันครั้งแรก'
    },
    'consent': {
      'all': 'ได้รับการยืนยัน',
      'necessary': 'ปฏิเสธ',
      'custom': 'เลือกบางส่วน',
      'default': 'ยืนยัน'
    },
    'change': {
      'all': 'เปลี่ยนเป็นยอมรับทั้งหมด',
      'necessary': 'เปลี่ยนเป็นปฏิเสธ',
      'custom': 'เปลี่ยนการตั้งค่า',
      'default': 'เปลี่ยนแปลง'
    }
  };
  
  return labels[eventType]?.[acceptType] || labels[eventType]?.['default'] || eventType;
}

/**
 * Get geo-location from IP (using GCP or external service)
 * For now, returns null - you can integrate with GCP's IP geolocation API
 */
async function getGeoLocation(ip) {
  // TODO: Integrate with GCP IP Geolocation API or MaxMind
  // For now, return null
  return {
    country_code: null,
    city: null
  };
}

/**
 * DEPRECATED: Use the authenticated version (cloud-function-auth) instead.
 * This function is kept for backward compatibility only.
 * 
 * Main Cloud Function handler
 */

// Allowed origins - restrict to known domains
const ALLOWED_ORIGINS = [
  'https://storage.googleapis.com',
  /^https:\/\/.*\.conicle\.ai$/
];

function isOriginAllowed(origin) {
  if (!origin) return false;
  return ALLOWED_ORIGINS.some(allowed => {
    if (typeof allowed === 'string') return allowed === origin;
    return allowed.test(origin);
  });
}

exports.logConsent = async (req, res) => {
  // CORS headers - restricted to known domains only
  const origin = req.headers.origin;
  if (isOriginAllowed(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  res.set('Vary', 'Origin');
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  // Only accept POST
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  
  // ========================================
  // DDOS PROTECTION CHECKS
  // ========================================
  
  // 1. Get client IP
  const clientIP = req.headers['x-forwarded-for']?.split(',')[0]?.trim() 
                || req.headers['x-real-ip'] 
                || req.connection?.remoteAddress 
                || req.socket?.remoteAddress
                || 'unknown';
  
  // 2. Check rate limit (5 requests per 10 seconds - stricter for unauthenticated)
  if (!checkRateLimit(clientIP)) {
    console.warn('[DDOS] Rate limit exceeded:', clientIP);
    return res.status(429).json({ 
      error: 'Too many requests',
      message: 'Rate limit exceeded. Please try again later.'
    });
  }
  
  // 3. Validate request size (max 50KB)
  const contentLength = parseInt(req.headers['content-length'] || '0', 10);
  if (contentLength > 51200) {
    console.warn('[DDOS] Request too large:', contentLength, 'bytes from', clientIP);
    return res.status(413).json({ 
      error: 'Payload too large',
      message: 'Request body must be less than 50KB'
    });
  }
  
  // 4. Validate Content-Type
  const contentType = req.headers['content-type'];
  if (!contentType || !contentType.includes('application/json')) {
    return res.status(415).json({ 
      error: 'Unsupported media type',
      message: 'Content-Type must be application/json'
    });
  }
  
  try {
    const data = req.body;
    
    // Validate required fields
    if (!data.event_type || !data.cookie) {
      res.status(400).json({ error: 'Missing required fields: event_type, cookie' });
      return;
    }
    
    // Note: clientIP already extracted above for rate limiting
    
    // Get user agent
    const userAgent = req.headers['user-agent'] || '';
    const uaData = parseUserAgent(userAgent);
    
    // Get geo-location (optional)
    const geo = await getGeoLocation(clientIP);
    
    // Parse campaign data from URL
    const campaignData = parseCampaignData(data.pageUrl);
    
    // Get action label (Thai/English)
    const actionLabel = getActionLabel(data.event_type, data.acceptType);
    
    // Prepare row for BigQuery
    const row = {
      event_id: uuidv4(),
      event_type: data.event_type,
      event_timestamp: new Date().toISOString(),
      
      // Consent data
      consent_id: data.cookie?.consentId || null,
      consent_timestamp: data.cookie?.consentTimestamp || null,
      accept_type: data.acceptType || null,
      action_label: actionLabel, // Thai/English label
      accepted_categories: data.cookie?.categories || [],
      rejected_categories: data.rejectedCategories || [],
      
      // Services
      accepted_services: data.cookie?.services ? JSON.stringify(data.cookie.services) : null,
      rejected_services: data.rejectedServices ? JSON.stringify(data.rejectedServices) : null,
      
      // Changed data
      changed_categories: data.changedCategories || [],
      
      // User info
      session_id: data.sessionId || null,
      user_id: data.userId || null,  // Only if user is logged in
      
      // Technical data (NOW WITH RAW IP!)
      ip_address: data.logIP !== false ? clientIP : null,  // Log raw IP by default now
      ip_hash: hashIP(clientIP),  // Always hash for privacy
      country_code: geo.country_code,
      city: geo.city,
      user_agent: userAgent.substring(0, 500), // Truncate long UAs
      browser_name: uaData.browser_name,
      browser_version: uaData.browser_version,
      os_name: uaData.os_name,
      device_type: uaData.device_type,
      
      // Page context
      page_url: data.pageUrl || null,
      page_title: data.pageTitle || null,
      referrer: data.referrer || null,
      language: data.language || null,
      
      // Campaign data (NEW!)
      utm_source: campaignData.utm_source,
      utm_medium: campaignData.utm_medium,
      utm_campaign: campaignData.utm_campaign,
      utm_term: campaignData.utm_term,
      utm_content: campaignData.utm_content,
      gclid: campaignData.gclid,
      fbclid: campaignData.fbclid,
      
      // Metadata
      consent_manager_version: data.version || '1.0.0',
      revision: data.cookie?.revision || 0,
      
      created_at: new Date().toISOString()
    };
    
    // Insert into BigQuery with timeout protection (5 seconds max)
    const insertPromise = bigquery
      .dataset(DATASET_ID)
      .table(TABLE_ID)
      .insert([row]);
    
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('BigQuery insert timeout')), 5000)
    );
    
    await Promise.race([insertPromise, timeoutPromise]);
    
    console.log(`✅ Logged consent event: ${row.event_id}`);
    
    res.status(200).json({ 
      success: true, 
      event_id: row.event_id 
    });
    
  } catch (error) {
    console.error('❌ Error logging consent:', error.message || error);
    
    // Don't leak internal error details
    const isDevelopment = process.env.NODE_ENV === 'development';
    const isTimeout = error.message === 'BigQuery insert timeout';
    
    if (isTimeout) {
      res.status(504).json({ 
        error: 'Gateway timeout',
        message: isDevelopment ? 'BigQuery insert timed out after 5 seconds' : 'Request timeout'
      });
    } else {
      res.status(500).json({ 
        error: 'Internal server error',
        message: isDevelopment ? error.message : 'An error occurred while processing your request'
      });
    }
  }
};
