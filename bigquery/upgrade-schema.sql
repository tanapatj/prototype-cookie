-- Upgrade existing BigQuery table with new columns
-- Run this to add new fields to your existing table
-- Project: cookiemanager-488405
-- Dataset: consent_analytics  
-- Table: consent_events

-- Add action_label column (Thai/English labels)
ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS action_label STRING;

-- Add UTM campaign tracking columns
ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS utm_source STRING;

ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS utm_medium STRING;

ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS utm_campaign STRING;

ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS utm_term STRING;

ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS utm_content STRING;

-- Add Google/Facebook Click IDs
ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS gclid STRING;

ALTER TABLE `cookiemanager-488405.consent_analytics.consent_events`
ADD COLUMN IF NOT EXISTS fbclid STRING;

-- Done! Your table now has all the new fields.
-- The ip_address column already exists, so raw IP logging will work immediately.
