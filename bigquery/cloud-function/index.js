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

/**
 * Hash IP address for privacy (GDPR compliant)
 */
function hashIP(ip) {
  if (!ip) return null;
  return crypto.createHash('sha256').update(ip + process.env.IP_SALT || 'conicle-salt').digest('hex');
}

/**
 * Parse User-Agent string
 */
function parseUserAgent(ua) {
  if (!ua) return { browser_name: null, browser_version: null, os_name: null, device_type: 'unknown' };
  
  // Simplified parsing (in production, use a library like 'ua-parser-js')
  const browser = ua.match(/(Chrome|Firefox|Safari|Edge|Opera)\/(\d+)/i) || [];
  const os = ua.match(/(Windows|Mac|Linux|Android|iOS)/i) || [];
  const isMobile = /Mobile|Android|iPhone|iPad/i.test(ua);
  const isTablet = /iPad|Android(?!.*Mobile)/i.test(ua);
  
  return {
    browser_name: browser[1] || 'Unknown',
    browser_version: browser[2] || null,
    os_name: os[1] || 'Unknown',
    device_type: isTablet ? 'tablet' : (isMobile ? 'mobile' : 'desktop')
  };
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
 * Main Cloud Function handler
 */
exports.logConsent = async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*'); // In production, restrict to your domains
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
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
    
    // Get user agent
    const userAgent = req.headers['user-agent'] || '';
    const uaData = parseUserAgent(userAgent);
    
    // Get geo-location (optional)
    const geo = await getGeoLocation(clientIP);
    
    // Prepare row for BigQuery
    const row = {
      event_id: uuidv4(),
      event_type: data.event_type,
      event_timestamp: new Date().toISOString(),
      
      // Consent data
      consent_id: data.cookie?.consentId || null,
      consent_timestamp: data.cookie?.consentTimestamp || null,
      accept_type: data.acceptType || null,
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
      
      // Technical data
      ip_address: data.logIP ? clientIP : null,  // Only log if explicitly allowed
      ip_hash: hashIP(clientIP),  // Always hash for privacy
      country_code: geo.country_code,
      city: geo.city,
      user_agent: userAgent,
      browser_name: uaData.browser_name,
      browser_version: uaData.browser_version,
      os_name: uaData.os_name,
      device_type: uaData.device_type,
      
      // Page context
      page_url: data.pageUrl || null,
      page_title: data.pageTitle || null,
      referrer: data.referrer || null,
      language: data.language || null,
      
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
    
    console.log(`✅ Logged consent event: ${row.event_id}`);
    
    res.status(200).json({ 
      success: true, 
      event_id: row.event_id 
    });
    
  } catch (error) {
    console.error('❌ Error logging consent:', error);
    
    // Don't expose internal errors to client
    res.status(500).json({ 
      error: 'Failed to log consent',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
