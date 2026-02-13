-- BigQuery Schema for Consent Logging
-- Project: conicle-ai-dev
-- Dataset: consent_analytics
-- Table: consent_events

CREATE TABLE IF NOT EXISTS `conicle-ai-dev.consent_analytics.consent_events` (
  -- Event Identification
  event_id STRING NOT NULL,
  event_type STRING NOT NULL,  -- 'consent', 'change', 'first_consent'
  event_timestamp TIMESTAMP NOT NULL,
  
  -- Consent Data
  consent_id STRING,  -- UUID from ConsentManager
  consent_timestamp TIMESTAMP,
  accept_type STRING,  -- 'all', 'necessary', 'custom'
  action_label STRING,  -- Thai/English label (e.g., "ได้รับการยืนยัน", "ปฏิเสธ")
  accepted_categories ARRAY<STRING>,
  rejected_categories ARRAY<STRING>,
  
  -- Services (optional)
  accepted_services JSON,
  rejected_services JSON,
  
  -- Changed data (for 'change' events)
  changed_categories ARRAY<STRING>,
  
  -- User Information (anonymous by default for GDPR)
  session_id STRING,  -- Anonymous session identifier
  user_id STRING,     -- NULL for anonymous users, set only if user is logged in
  
  -- Technical Data
  ip_address STRING,  -- Raw IP address (now enabled)
  ip_hash STRING,     -- SHA-256 hashed IP for privacy backup
  country_code STRING,
  city STRING,
  user_agent STRING,
  browser_name STRING,
  browser_version STRING,
  os_name STRING,
  device_type STRING,  -- 'desktop', 'mobile', 'tablet'
  
  -- Page Context
  page_url STRING,
  page_title STRING,
  referrer STRING,
  language STRING,  -- Browser language
  
  -- Campaign Tracking (UTM parameters)
  utm_source STRING,    -- Traffic source (e.g., 'google', 'facebook')
  utm_medium STRING,    -- Marketing medium (e.g., 'cpc', 'email')
  utm_campaign STRING,  -- Campaign name
  utm_term STRING,      -- Paid keywords
  utm_content STRING,   -- Ad content/variation
  gclid STRING,         -- Google Ads Click ID
  fbclid STRING,        -- Facebook Click ID
  
  -- Consent Manager Metadata
  consent_manager_version STRING,
  revision INT64,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY event_type, accept_type, country_code
OPTIONS(
  description="Consent events from ConsentManager",
  require_partition_filter=false
);

-- Indexes for common queries (BigQuery auto-optimizes, but good to document)
-- Query patterns:
-- 1. SELECT COUNT(*) WHERE event_type = 'consent' AND DATE(event_timestamp) = CURRENT_DATE()
-- 2. SELECT accept_type, COUNT(*) GROUP BY accept_type
-- 3. SELECT country_code, COUNT(*) WHERE accepted_categories LIKE '%analytics%'
