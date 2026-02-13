-- Cost Monitoring Dashboard Queries
-- Project: conicle-ai-dev
-- Dataset: consent_analytics

-- ==========================================
-- 1. DAILY STORAGE & USAGE SUMMARY
-- ==========================================

-- Current storage size and row count
SELECT 
  'consent_events' as table_name,
  COUNT(*) as total_rows,
  ROUND(SUM(LENGTH(TO_JSON_STRING(t))) / 1024 / 1024 / 1024, 4) as size_gb_approx,
  ROUND(SUM(LENGTH(TO_JSON_STRING(t))) / 1024 / 1024 / 1024 * 0.02, 4) as monthly_storage_cost_usd,
  MIN(event_timestamp) as oldest_record,
  MAX(event_timestamp) as newest_record,
  DATE_DIFF(CURRENT_DATE(), DATE(MIN(event_timestamp)), DAY) as retention_days
FROM `conicle-ai-dev.consent_analytics.consent_events` t;

-- ==========================================
-- 2. MONTHLY GROWTH TREND
-- ==========================================

SELECT 
  FORMAT_DATE('%Y-%m', DATE(event_timestamp)) as month,
  COUNT(*) as new_records,
  ROUND(COUNT(*) / 1024 / 1024 * 1, 2) as approx_size_mb,  -- Rough estimate
  ROUND(COUNT(*) / 1024 / 1024 * 1 / 1024 * 0.02, 4) as monthly_storage_cost_usd
FROM `conicle-ai-dev.consent_analytics.consent_events`
GROUP BY month
ORDER BY month DESC
LIMIT 12;

-- ==========================================
-- 3. DAILY EVENT COUNT (Last 30 Days)
-- ==========================================

SELECT 
  DATE(event_timestamp) as date,
  COUNT(*) as events,
  COUNT(DISTINCT session_id) as unique_sessions,
  COUNT(DISTINCT ip_address) as unique_ips,
  ROUND(COUNT(*) / 1000000.0, 2) as events_millions
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;

-- ==========================================
-- 4. PROJECTED MONTHLY COSTS
-- ==========================================

WITH daily_stats AS (
  SELECT 
    DATE(event_timestamp) as date,
    COUNT(*) as daily_events,
    ROUND(SUM(LENGTH(TO_JSON_STRING(t))) / 1024 / 1024, 2) as daily_mb
  FROM `conicle-ai-dev.consent_analytics.consent_events` t
  WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  GROUP BY date
),
averages AS (
  SELECT 
    AVG(daily_events) as avg_daily_events,
    AVG(daily_mb) as avg_daily_mb
  FROM daily_stats
)
SELECT 
  'Cost Projection' as metric,
  ROUND(avg_daily_events * 30, 0) as projected_monthly_events,
  ROUND(avg_daily_mb * 30 / 1024, 2) as projected_monthly_gb,
  ROUND(avg_daily_mb * 30 / 1024 * 0.02, 2) as storage_cost_usd,
  ROUND(avg_daily_mb * 30 / 1024 * 0.05, 2) as streaming_cost_usd,
  ROUND((avg_daily_mb * 30 / 1024 * 0.02) + (avg_daily_mb * 30 / 1024 * 0.05), 2) as total_monthly_cost_usd,
  ROUND(((avg_daily_mb * 30 / 1024 * 0.02) + (avg_daily_mb * 30 / 1024 * 0.05)) * 37, 2) as total_monthly_cost_thb,
  CASE 
    WHEN ((avg_daily_mb * 30 / 1024 * 0.02) + (avg_daily_mb * 30 / 1024 * 0.05)) * 37 < 5000 
    THEN '✅ Under Budget' 
    ELSE '⚠️ Over Budget' 
  END as budget_status
FROM averages;

-- ==========================================
-- 5. API KEY USAGE & COSTS
-- ==========================================

SELECT 
  k.client_name,
  k.api_key,
  k.monthly_quota,
  COUNT(e.event_id) as current_month_events,
  ROUND(COUNT(e.event_id) * 1.0 / 1024 / 1024, 4) as approx_mb,
  ROUND(COUNT(e.event_id) * 1.0 / 1024 / 1024 * 0.05 / 1024, 4) as streaming_cost_usd,
  CASE 
    WHEN k.monthly_quota IS NOT NULL 
    THEN ROUND(COUNT(e.event_id) * 100.0 / k.monthly_quota, 2)
    ELSE NULL
  END as quota_usage_percent
FROM `conicle-ai-dev.consent_analytics.api_keys` k
LEFT JOIN `conicle-ai-dev.consent_analytics.consent_events` e 
  ON k.api_key = e.api_key
  AND DATE(e.event_timestamp) >= DATE_TRUNC(CURRENT_DATE(), MONTH)
WHERE k.is_active = TRUE
GROUP BY k.client_name, k.api_key, k.monthly_quota
ORDER BY current_month_events DESC;

-- ==========================================
-- 6. STORAGE BREAKDOWN BY AGE
-- ==========================================

SELECT 
  CASE 
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(event_timestamp), DAY) <= 30 THEN '0-30 days (Hot)'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(event_timestamp), DAY) <= 90 THEN '31-90 days'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(event_timestamp), DAY) <= 180 THEN '91-180 days'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(event_timestamp), DAY) <= 365 THEN '181-365 days'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(event_timestamp), DAY) <= 730 THEN '1-2 years'
    ELSE '2+ years (Should be deleted)'
  END as data_age,
  COUNT(*) as records,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percent_of_total,
  ROUND(COUNT(*) * 1.0 / 1024 / 1024, 2) as approx_mb
FROM `conicle-ai-dev.consent_analytics.consent_events`
GROUP BY data_age
ORDER BY 
  CASE 
    WHEN data_age = '0-30 days (Hot)' THEN 1
    WHEN data_age = '31-90 days' THEN 2
    WHEN data_age = '91-180 days' THEN 3
    WHEN data_age = '181-365 days' THEN 4
    WHEN data_age = '1-2 years' THEN 5
    ELSE 6
  END;

-- ==========================================
-- 7. COST ALERT: Data Older Than 2 Years
-- ==========================================

SELECT 
  'OLD DATA ALERT' as alert_type,
  COUNT(*) as records_to_delete,
  ROUND(COUNT(*) * 1.0 / 1024 / 1024, 2) as mb_to_free,
  MIN(event_timestamp) as oldest_record,
  MAX(event_timestamp) as newest_old_record,
  CASE 
    WHEN COUNT(*) > 0 THEN '⚠️ Run auto-delete-old-data.sql to free storage'
    ELSE '✅ No old data to delete'
  END as action_needed
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);

-- ==========================================
-- 8. REAL-TIME COST DASHBOARD VIEW
-- ==========================================

CREATE OR REPLACE VIEW `conicle-ai-dev.consent_analytics.cost_dashboard` AS
WITH current_stats AS (
  SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT DATE(event_timestamp)) as days_of_data,
    MIN(event_timestamp) as first_event,
    MAX(event_timestamp) as last_event
  FROM `conicle-ai-dev.consent_analytics.consent_events`
),
monthly_projection AS (
  SELECT 
    AVG(daily_count) * 30 as projected_monthly_events
  FROM (
    SELECT COUNT(*) as daily_count
    FROM `conicle-ai-dev.consent_analytics.consent_events`
    WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    GROUP BY DATE(event_timestamp)
  )
)
SELECT 
  c.total_records,
  c.days_of_data,
  c.first_event,
  c.last_event,
  ROUND(c.total_records / 1024.0 / 1024.0, 2) as approx_total_mb,
  ROUND(c.total_records / 1024.0 / 1024.0 / 1024.0, 4) as approx_total_gb,
  ROUND(c.total_records / 1024.0 / 1024.0 / 1024.0 * 0.02, 4) as monthly_storage_cost_usd,
  ROUND(c.total_records / 1024.0 / 1024.0 / 1024.0 * 0.02 * 37, 2) as monthly_storage_cost_thb,
  m.projected_monthly_events,
  ROUND(m.projected_monthly_events / 1024.0 / 1024.0 / 1024.0 * 0.05, 4) as projected_streaming_cost_usd,
  ROUND(m.projected_monthly_events / 1024.0 / 1024.0 / 1024.0 * 0.05 * 37, 2) as projected_streaming_cost_thb,
  ROUND((c.total_records / 1024.0 / 1024.0 / 1024.0 * 0.02) + (m.projected_monthly_events / 1024.0 / 1024.0 / 1024.0 * 0.05), 4) as total_monthly_cost_usd,
  ROUND(((c.total_records / 1024.0 / 1024.0 / 1024.0 * 0.02) + (m.projected_monthly_events / 1024.0 / 1024.0 / 1024.0 * 0.05)) * 37, 2) as total_monthly_cost_thb,
  5000 as monthly_budget_thb,
  ROUND(5000 - ((c.total_records / 1024.0 / 1024.0 / 1024.0 * 0.02) + (m.projected_monthly_events / 1024.0 / 1024.0 / 1024.0 * 0.05)) * 37, 2) as budget_remaining_thb
FROM current_stats c, monthly_projection m;

-- Query the dashboard
-- SELECT * FROM `conicle-ai-dev.consent_analytics.cost_dashboard`;
