/**
 * Cloud Function: Admin Key Manager
 *
 * Handles all admin operations for ConsentManager API keys:
 * - generate : Create a new API key and save to BigQuery
 * - list     : List all API keys
 * - revoke   : Deactivate an API key
 *
 * Authentication: Google ID Token (Bearer)
 * Authorization:  Only @conicle.com Google accounts
 *
 * Region: asia-southeast1 (Singapore)
 */

const { BigQuery } = require('@google-cloud/bigquery');
const crypto = require('crypto');
const https = require('https');

const bigquery = new BigQuery();
const DATASET_ID = 'consent_analytics';
const TABLE_ID = 'api_keys';
const ALLOWED_DOMAIN = process.env.ALLOWED_ADMIN_DOMAIN || 'conicle.com';

// In-memory cache: verified tokens { token_hash: { email, exp } }
const tokenCache = new Map();

// ─── Token Verification ───────────────────────────────────────────────────────

/**
 * Verify a Google ID token via Google's tokeninfo endpoint.
 * Caches results for 5 minutes to reduce outbound calls.
 */
async function verifyGoogleToken(idToken) {
  const tokenHash = crypto.createHash('sha256').update(idToken).digest('hex').slice(0, 16);
  const now = Math.floor(Date.now() / 1000);

  // Return cached result if still valid
  if (tokenCache.has(tokenHash)) {
    const cached = tokenCache.get(tokenHash);
    if (cached.exp > now + 30) {
      return cached;
    }
    tokenCache.delete(tokenHash);
  }

  // Purge expired entries occasionally
  if (Math.random() < 0.1) {
    for (const [k, v] of tokenCache.entries()) {
      if (v.exp <= now) tokenCache.delete(k);
    }
  }

  return new Promise((resolve, reject) => {
    const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          const payload = JSON.parse(data);
          if (payload.error || !payload.email) {
            return reject(new Error(payload.error_description || 'Invalid token'));
          }
          if (!payload.email_verified) {
            return reject(new Error('Email not verified'));
          }
          const result = {
            email: payload.email,
            name: payload.name || payload.email,
            picture: payload.picture || null,
            exp: parseInt(payload.exp, 10),
          };
          tokenCache.set(tokenHash, result);
          resolve(result);
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

// ─── API Key Generation ───────────────────────────────────────────────────────

/**
 * Generate a cryptographically secure API key.
 * Uses crypto.randomBytes (not Math.random) for security.
 */
function generateAPIKey() {
  const bytes = crypto.randomBytes(24);
  return 'cm_' + bytes.toString('hex');
}

// ─── Input Validation ─────────────────────────────────────────────────────────

function validateDomain(domain) {
  // Allow: alphanumeric, dots, hyphens, and one leading wildcard segment
  return /^(\*\.)?[a-zA-Z0-9][a-zA-Z0-9\-\.]{0,253}[a-zA-Z0-9]$/.test(domain)
    || /^localhost$/.test(domain);
}

// ─── Main Handler ─────────────────────────────────────────────────────────────

exports.adminKeyManager = async (req, res) => {
  const origin = req.headers.origin || '';

  // CORS – only allow the GCS-hosted portal and localhost for dev
  const allowedOrigins = [
    'https://storage.googleapis.com',
    'http://localhost:8080',
    'http://localhost:3000',
  ];
  if (allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Vary', 'Origin');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // ── Authentication ────────────────────────────────────────────────────────
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization header required' });
  }

  const idToken = authHeader.slice(7);
  let tokenPayload;
  try {
    tokenPayload = await verifyGoogleToken(idToken);
  } catch (err) {
    console.warn('Token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired Google token. Please sign in again.' });
  }

  // ── Authorization: @conicle.com only ─────────────────────────────────────
  if (!tokenPayload.email.endsWith(`@${ALLOWED_DOMAIN}`)) {
    console.warn(`Access denied for: ${tokenPayload.email}`);
    return res.status(403).json({
      error: `Access denied. Only @${ALLOWED_DOMAIN} accounts are allowed.`,
    });
  }

  const adminEmail = tokenPayload.email;
  const { action } = req.body || {};
  console.log(`[ADMIN] Action: ${action} by ${adminEmail}`);

  try {
    // ── GENERATE ────────────────────────────────────────────────────────────
    if (action === 'generate') {
      const { clientName, domains, clientEmail, quota, expiresAt, notes } = req.body;

      if (!clientName || typeof clientName !== 'string' || clientName.trim().length === 0) {
        return res.status(400).json({ error: 'clientName is required' });
      }
      if (!Array.isArray(domains) || domains.length === 0) {
        return res.status(400).json({ error: 'domains array is required' });
      }

      // Validate each domain
      const invalidDomains = domains.filter(d => !validateDomain(d));
      if (invalidDomains.length > 0) {
        return res.status(400).json({ error: `Invalid domain format: ${invalidDomains.join(', ')}` });
      }

      const apiKey = generateAPIKey();
      const apiKeyHash = crypto.createHash('sha256').update(apiKey).digest('hex');

      const row = {
        api_key: apiKey,
        api_key_hash: apiKeyHash,
        client_name: clientName.trim().substring(0, 200),
        client_email: clientEmail || null,
        allowed_domains: domains.map(d => d.trim()),
        is_active: true,
        monthly_quota: quota ? parseInt(quota, 10) : null,
        current_month_usage: 0,
        created_at: new Date().toISOString(),
        created_by: adminEmail,
        expires_at: expiresAt ? new Date(expiresAt).toISOString() : null,
        notes: notes ? notes.substring(0, 500) : null,
      };

      await bigquery.dataset(DATASET_ID).table(TABLE_ID).insert([row]);
      console.log(`[ADMIN] ✅ Generated key for ${clientName} by ${adminEmail}`);

      return res.status(200).json({
        success: true,
        apiKey,
        clientName: row.client_name,
        message: 'API key generated and saved to BigQuery',
      });

    // ── LIST ────────────────────────────────────────────────────────────────
    } else if (action === 'list') {
      const [rows] = await bigquery.query({
        query: `
          SELECT
            client_name,
            client_email,
            CONCAT(SUBSTR(api_key, 1, 12), '...', RIGHT(api_key, 6)) AS api_key_masked,
            allowed_domains,
            is_active,
            monthly_quota,
            current_month_usage,
            FORMAT_TIMESTAMP('%Y-%m-%d', created_at) AS created_date,
            created_by,
            FORMAT_TIMESTAMP('%Y-%m-%d', expires_at) AS expires_date,
            notes
          FROM \`${DATASET_ID}.${TABLE_ID}\`
          ORDER BY created_at DESC
          LIMIT 200
        `,
      });
      return res.status(200).json({ success: true, keys: rows });

    // ── REVOKE ──────────────────────────────────────────────────────────────
    } else if (action === 'revoke') {
      const { apiKeyMasked } = req.body;
      if (!apiKeyMasked) {
        return res.status(400).json({ error: 'apiKeyMasked is required' });
      }

      // Extract prefix and suffix from masked format "cm_xxxxxxxx...yyyyyy"
      const parts = apiKeyMasked.split('...');
      if (parts.length !== 2) {
        return res.status(400).json({ error: 'Invalid key format' });
      }
      const prefix = parts[0];
      const suffix = parts[1];

      await bigquery.query({
        query: `
          UPDATE \`${DATASET_ID}.${TABLE_ID}\`
          SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP()
          WHERE STARTS_WITH(api_key, @prefix)
            AND ENDS_WITH(api_key, @suffix)
            AND is_active = TRUE
        `,
        params: { prefix, suffix },
      });

      console.log(`[ADMIN] 🚫 Revoked key ${apiKeyMasked} by ${adminEmail}`);
      return res.status(200).json({ success: true, message: 'API key revoked successfully' });

    // ── UNKNOWN ─────────────────────────────────────────────────────────────
    } else {
      return res.status(400).json({ error: 'Invalid action. Allowed: generate, list, revoke' });
    }

  } catch (error) {
    console.error('[ADMIN] ❌ Error:', error.message || error);
    return res.status(500).json({ error: 'Operation failed', message: error.message });
  }
};
