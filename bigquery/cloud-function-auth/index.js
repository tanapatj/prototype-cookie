/**
 * Cloud Function: Log Consent Events to BigQuery (WITH AUTHENTICATION)
 * 
 * Features:
 * - API Key authentication
 * - Domain whitelist validation
 * - Rate limiting (quota check)
 * - Enhanced logging with UTM tracking
 * 
 * Deployed to: GCP Cloud Functions
 * Trigger: HTTPS
 * Runtime: Node.js 20
 * Region: asia-southeast1 (Singapore)
 */

const { BigQuery } = require('@google-cloud/bigquery');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

const bigquery = new BigQuery();
const DATASET_ID = 'consent_analytics';
const TABLE_ID = 'consent_events';
const API_KEYS_TABLE_ID = 'api_keys';

/**
 * Validate API key and domain
 */
async function validateAPIKey(apiKey, origin) {
  if (!apiKey) {
    return { valid: false, error: 'API key missing' };
  }

  try {
    // Query API keys table
    const query = `
      SELECT 
        api_key,
        client_name,
        allowed_domains,
        is_active,
        monthly_quota,
        current_month_usage,
        expires_at
      FROM \`${DATASET_ID}.${API_KEYS_TABLE_ID}\`
      WHERE api_key = @apiKey
        AND is_active = TRUE
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP())
      LIMIT 1
    `;

    const options = {
      query: query,
      params: { apiKey: apiKey }
    };

    const [rows] = await bigquery.query(options);
    
    if (rows.length === 0) {
      return { valid: false, error: 'Invalid or expired API key' };
    }

    const keyData = rows[0];

    // Check domain whitelist
    if (origin) {
      const domain = new URL(origin).hostname;
      const isAllowed = keyData.allowed_domains.some(pattern => {
        // Support wildcards: *.conicle.ai matches app.conicle.ai
        const regex = new RegExp('^' + pattern.replace(/\*/g, '.*').replace(/\./g, '\\.') + '$');
        return regex.test(domain);
      });

      if (!isAllowed) {
        return { valid: false, error: `Domain ${domain} not whitelisted` };
      }
    }

    // Check monthly quota
    if (keyData.monthly_quota && keyData.current_month_usage >= keyData.monthly_quota) {
      return { valid: false, error: 'Monthly quota exceeded' };
    }

    return { 
      valid: true, 
      clientName: keyData.client_name,
      quota: keyData.monthly_quota,
      usage: keyData.current_month_usage
    };

  } catch (error) {
    console.error('API key validation error:', error);
    return { valid: false, error: 'Validation failed' };
  }
}

/**
 * Increment usage counter for API key
 */
async function incrementUsage(apiKey) {
  try {
    const query = `
      UPDATE \`${DATASET_ID}.${API_KEYS_TABLE_ID}\`
      SET current_month_usage = current_month_usage + 1,
          updated_at = CURRENT_TIMESTAMP()
      WHERE api_key = @apiKey
    `;

    await bigquery.query({
      query: query,
      params: { apiKey: apiKey }
    });
  } catch (error) {
    console.error('Failed to increment usage:', error);
    // Don't fail the request if usage tracking fails
  }
}

/**
 * Hash IP address for privacy (GDPR compliant)
 */
function hashIP(ip) {
  if (!ip) return null;
  return crypto.createHash('sha256').update(ip + (process.env.IP_SALT || 'conicle-salt')).digest('hex');
}

/**
 * Parse User-Agent string (detailed)
 */
function parseUserAgent(ua) {
  if (!ua) return { browser_name: null, browser_version: null, os_name: null, device_type: 'unknown', full_ua: null };
  
  const browser = ua.match(/(Chrome|Firefox|Safari|Edge|Opera|WebView)\/(\d+\.\d+)/i) || [];
  const os = ua.match(/(Windows NT|Mac OS X|Linux|Android|iOS)[\s\/]?([\d._]+)?/i) || [];
  const isMobile = /Mobile|Android|iPhone|iPad/i.test(ua);
  const isTablet = /iPad|Android(?!.*Mobile)/i.test(ua);
  
  return {
    browser_name: browser[1] || 'Unknown',
    browser_version: browser[2] || null,
    os_name: os[1] || 'Unknown',
    device_type: isTablet ? 'tablet' : (isMobile ? 'mobile' : 'desktop'),
    full_ua: ua.substring(0, 500)
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
      gclid: params.get('gclid') || null,
      fbclid: params.get('fbclid') || null,
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
 * Get geo-location from IP (placeholder)
 */
async function getGeoLocation(ip) {
  // TODO: Integrate with GCP IP Geolocation API
  return {
    country_code: null,
    city: null
  };
}

/**
 * Main Cloud Function handler
 */
exports.logConsent = async (req, res) => {
  // CORS headers
  const origin = req.headers.origin || req.headers.referer;
  res.set('Access-Control-Allow-Origin', origin || '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, X-API-Key');
  
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
  
  try {
    // Get API key from header
    const apiKey = req.headers['x-api-key'] || req.body.apiKey;
    
    // Validate API key and domain
    const validation = await validateAPIKey(apiKey, origin);
    if (!validation.valid) {
      console.warn('Auth failed:', validation.error, 'Origin:', origin);
      res.status(401).json({ 
        error: 'Authentication failed',
        message: validation.error 
      });
      return;
    }

    const data = req.body;
    
    // Validate required fields
    if (!data.event_type || !data.cookie) {
      res.status(400).json({ error: 'Missing required fields: event_type, cookie' });
      return;
    }
    
    // Get client IP
    const clientIP = req.headers['x-forwarded-for']?.split(',')[0]?.trim() 
                  || req.headers['x-real-ip'] 
                  || req.connection.remoteAddress 
                  || req.socket.remoteAddress;
    
    // Parse user agent
    const userAgent = req.headers['user-agent'] || '';
    const uaData = parseUserAgent(userAgent);
    
    // Get geo-location
    const geo = await getGeoLocation(clientIP);
    
    // Parse campaign data
    const campaignData = parseCampaignData(data.pageUrl);
    
    // Get action label
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
      action_label: actionLabel,
      accepted_categories: data.cookie?.categories || [],
      rejected_categories: data.rejectedCategories || [],
      
      // Services
      accepted_services: data.cookie?.services ? JSON.stringify(data.cookie.services) : null,
      rejected_services: data.rejectedServices ? JSON.stringify(data.rejectedServices) : null,
      
      // Changed data
      changed_categories: data.changedCategories || [],
      
      // User info
      session_id: data.sessionId || null,
      user_id: data.userId || null,
      
      // API key info (NEW!)
      api_key: apiKey,
      client_name: validation.clientName,
      
      // Technical data
      ip_address: data.logIP !== false ? clientIP : null,
      ip_hash: hashIP(clientIP),
      country_code: geo.country_code,
      city: geo.city,
      user_agent: userAgent.substring(0, 500),
      browser_name: uaData.browser_name,
      browser_version: uaData.browser_version,
      os_name: uaData.os_name,
      device_type: uaData.device_type,
      
      // Page context
      page_url: data.pageUrl || null,
      page_title: data.pageTitle || null,
      referrer: data.referrer || null,
      language: data.language || null,
      
      // Campaign data
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
    
    // Insert into BigQuery
    await bigquery
      .dataset(DATASET_ID)
      .table(TABLE_ID)
      .insert([row]);
    
    // Increment usage counter
    await incrementUsage(apiKey);
    
    console.log(`✅ Logged event: ${row.event_id} (client: ${validation.clientName})`);
    
    res.status(200).json({ 
      success: true, 
      event_id: row.event_id,
      client: validation.clientName,
      quota_remaining: validation.quota ? validation.quota - validation.usage - 1 : null
    });
    
  } catch (error) {
    console.error('❌ Error logging consent:', error);
    
    res.status(500).json({ 
      error: 'Failed to log consent',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
