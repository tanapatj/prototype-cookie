#!/usr/bin/env node
/**
 * Admin Tool: Generate API Keys for Consent Manager
 * 
 * Usage:
 *   node admin-generate-api-key.js --client="Client Name" --domains="example.com,*.example.com" --email="client@example.com"
 * 
 * Options:
 *   --client     Client/company name (required)
 *   --domains    Comma-separated list of allowed domains (required)
 *   --email      Client contact email (optional)
 *   --quota      Monthly event quota (optional, default: unlimited)
 *   --expires    Expiration date YYYY-MM-DD (optional)
 *   --notes      Internal notes (optional)
 */

const { BigQuery } = require('@google-cloud/bigquery');
const crypto = require('crypto');

const bigquery = new BigQuery();
const DATASET_ID = 'consent_analytics';
const TABLE_ID = 'api_keys';

// Parse command line arguments
function parseArgs() {
  const args = {};
  process.argv.slice(2).forEach(arg => {
    const match = arg.match(/--(\w+)=(.+)/);
    if (match) {
      args[match[1]] = match[2];
    }
  });
  return args;
}

// Generate UUID v4
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Generate API key
function generateAPIKey() {
  return `cm_${generateUUID()}`;
}

// Hash API key
function hashAPIKey(apiKey) {
  return crypto.createHash('sha256').update(apiKey).digest('hex');
}

// Main function
async function generateKey() {
  const args = parseArgs();

  // Validate required arguments
  if (!args.client) {
    console.error('❌ Error: --client is required');
    console.log('\nUsage:');
    console.log('  node admin-generate-api-key.js --client="Client Name" --domains="example.com,*.example.com"');
    process.exit(1);
  }

  if (!args.domains) {
    console.error('❌ Error: --domains is required');
    console.log('\nUsage:');
    console.log('  node admin-generate-api-key.js --client="Client Name" --domains="example.com,*.example.com"');
    process.exit(1);
  }

  // Generate API key
  const apiKey = generateAPIKey();
  const apiKeyHash = hashAPIKey(apiKey);
  const domains = args.domains.split(',').map(d => d.trim());
  
  // Prepare data
  const row = {
    api_key: apiKey,
    api_key_hash: apiKeyHash,
    client_name: args.client,
    client_email: args.email || null,
    allowed_domains: domains,
    is_active: true,
    monthly_quota: args.quota ? parseInt(args.quota) : null,
    current_month_usage: 0,
    created_at: new Date().toISOString(),
    created_by: process.env.USER || 'admin',
    expires_at: args.expires ? new Date(args.expires).toISOString() : null,
    notes: args.notes || null
  };

  try {
    // Insert into BigQuery
    await bigquery
      .dataset(DATASET_ID)
      .table(TABLE_ID)
      .insert([row]);

    console.log('\n✅ API Key Generated Successfully!\n');
    console.log('━'.repeat(80));
    console.log('📋 API Key Details:');
    console.log('━'.repeat(80));
    console.log(`🔑 API Key:        ${apiKey}`);
    console.log(`👤 Client:         ${args.client}`);
    console.log(`📧 Email:          ${args.email || 'N/A'}`);
    console.log(`🌐 Allowed Domains:`);
    domains.forEach(d => console.log(`   - ${d}`));
    console.log(`📊 Monthly Quota:  ${args.quota || 'Unlimited'}`);
    console.log(`⏰ Expires:        ${args.expires || 'Never'}`);
    console.log(`📝 Notes:          ${args.notes || 'N/A'}`);
    console.log('━'.repeat(80));
    console.log('\n📤 Send this to your client:\n');
    console.log('━'.repeat(80));
    console.log(`API Key: ${apiKey}`);
    console.log(`\nUsage (JavaScript):`);
    console.log(`fetch('https://YOUR-FUNCTION-URL.a.run.app', {`);
    console.log(`  method: 'POST',`);
    console.log(`  headers: {`);
    console.log(`    'Content-Type': 'application/json',`);
    console.log(`    'X-API-Key': '${apiKey}'`);
    console.log(`  },`);
    console.log(`  body: JSON.stringify({ /* your data */ })`);
    console.log(`});`);
    console.log('━'.repeat(80));
    console.log('\n💡 Tip: Save this API key securely. It cannot be retrieved later.\n');

  } catch (error) {
    console.error('❌ Error generating API key:', error.message);
    process.exit(1);
  }
}

// Run
generateKey().catch(console.error);
