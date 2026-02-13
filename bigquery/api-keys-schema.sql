-- API Keys & Domain Whitelist Table
-- Project: conicle-ai-dev
-- Dataset: consent_analytics
-- Table: api_keys

CREATE TABLE IF NOT EXISTS `conicle-ai-dev.consent_analytics.api_keys` (
  -- API Key Info
  api_key STRING NOT NULL,          -- UUID format API key
  api_key_hash STRING NOT NULL,     -- SHA-256 hash of API key (for validation)
  
  -- Client Info
  client_name STRING NOT NULL,      -- Customer/client name
  client_email STRING,              -- Contact email
  client_id STRING,                 -- Internal client ID (optional)
  
  -- Domain Whitelist
  allowed_domains ARRAY<STRING>,  -- List of whitelisted domains
  
  -- Status
  is_active BOOLEAN NOT NULL,
  
  -- Usage Limits (optional)
  monthly_quota INT64,              -- Max events per month (NULL = unlimited)
  current_month_usage INT64,
  
  -- Metadata
  created_at TIMESTAMP NOT NULL,
  created_by STRING,                -- Admin who created it
  updated_at TIMESTAMP,
  expires_at TIMESTAMP,             -- Optional expiration date
  
  -- Notes
  notes STRING                      -- Internal notes
)
OPTIONS(
  description="API keys and domain whitelist for consent logging"
);

-- Insert example API key (for testing)
INSERT INTO `conicle-ai-dev.consent_analytics.api_keys` 
  (api_key, api_key_hash, client_name, allowed_domains, is_active, created_at, current_month_usage, created_by, notes)
VALUES 
  (
    'demo-key-12345678-1234-1234-1234-123456789abc',
    TO_HEX(SHA256('demo-key-12345678-1234-1234-1234-123456789abc')),
    'Demo Client',
    ['localhost', 'storage.googleapis.com', '*.conicle.ai'],
    TRUE,
    CURRENT_TIMESTAMP(),
    0,
    'system',
    'Demo API key for testing'
  );

-- Query to check API keys
-- SELECT * FROM `conicle-ai-dev.consent_analytics.api_keys` WHERE is_active = TRUE;
