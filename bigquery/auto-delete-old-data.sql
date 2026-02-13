-- Auto-Delete Data Older Than 2 Years
-- This query should be run as a Scheduled Query (daily at midnight)
-- 
-- Setup Instructions:
-- 1. Go to BigQuery Console: https://console.cloud.google.com/bigquery
-- 2. Click "Schedule" → "Create new scheduled query"
-- 3. Set schedule: Daily at 00:00 (midnight Bangkok time)
-- 4. Use this query below

-- Delete consent events older than 2 years (730 days)
DELETE FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);

-- Log deletion summary
-- This will show in the query results/logs
SELECT 
  'Data Retention Cleanup' as task,
  DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY) as cutoff_date,
  CURRENT_TIMESTAMP() as executed_at;

-- Alternative: If you want to keep a count before deleting
-- CREATE TEMP TABLE deletion_summary AS
-- SELECT 
--   COUNT(*) as records_to_delete,
--   MIN(event_timestamp) as oldest_record,
--   MAX(event_timestamp) as newest_record_to_delete
-- FROM `conicle-ai-dev.consent_analytics.consent_events`
-- WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);

-- SELECT * FROM deletion_summary;
