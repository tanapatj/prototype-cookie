-- BigQuery Example Queries for Consent Analytics
-- Project: conicle-ai-dev
-- Dataset: consent_analytics
-- Table: consent_events

-- ====================
-- 1. DAILY OVERVIEW
-- ====================

-- Total events today
SELECT 
  COUNT(*) as total_events,
  COUNTIF(event_type = 'first_consent') as first_consents,
  COUNTIF(event_type = 'consent') as consents,
  COUNTIF(event_type = 'change') as changes
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) = CURRENT_DATE();

-- ====================
-- 2. ACCEPTANCE RATES
-- ====================

-- Overall acceptance rate (last 7 days)
SELECT 
  accept_type,
  COUNT(*) as total,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY accept_type
ORDER BY total DESC;

-- Acceptance rate by category (last 30 days)
SELECT 
  category,
  COUNT(*) as accepted_count,
  ROUND(COUNT(*) * 100.0 / (
    SELECT COUNT(DISTINCT consent_id) 
    FROM `conicle-ai-dev.consent_analytics.consent_events`
    WHERE event_type = 'consent'
      AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  ), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`,
UNNEST(accepted_categories) as category
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY category
ORDER BY acceptance_rate DESC;

-- ====================
-- 3. TRENDS OVER TIME
-- ====================

-- Daily acceptance trend (last 30 days)
SELECT 
  DATE(event_timestamp) as date,
  COUNT(*) as total_consents,
  COUNTIF(accept_type = 'all') as accepted_all,
  COUNTIF(accept_type = 'custom') as accepted_custom,
  COUNTIF(accept_type = 'necessary') as rejected_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as accept_all_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;

-- ====================
-- 4. DEVICE & BROWSER
-- ====================

-- Acceptance by device type
SELECT 
  device_type,
  COUNT(*) as users,
  COUNTIF(accept_type = 'all') as accepted_all,
  COUNTIF(accept_type = 'necessary') as rejected_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY device_type
ORDER BY users DESC;

-- Acceptance by browser
SELECT 
  browser_name,
  browser_version,
  COUNT(*) as users,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND browser_name IS NOT NULL
GROUP BY browser_name, browser_version
HAVING users > 5
ORDER BY users DESC;

-- ====================
-- 5. GEOGRAPHY
-- ====================

-- Top countries by consent events
SELECT 
  country_code,
  COUNT(*) as total_events,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND country_code IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY country_code
HAVING total_events > 10
ORDER BY total_events DESC
LIMIT 20;

-- ====================
-- 6. USER BEHAVIOR
-- ====================

-- How many users change their mind?
SELECT 
  'Changed preferences' as behavior,
  COUNT(DISTINCT session_id) as users
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'change'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
  'Accepted on first visit' as behavior,
  COUNT(DISTINCT session_id) as users
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'first_consent'
  AND accept_type = 'all'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
  'Rejected on first visit' as behavior,
  COUNT(DISTINCT session_id) as users
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'first_consent'
  AND accept_type = 'necessary'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- Average time between first consent and change
WITH user_events AS (
  SELECT 
    session_id,
    MIN(CASE WHEN event_type = 'first_consent' THEN event_timestamp END) as first_consent_time,
    MIN(CASE WHEN event_type = 'change' THEN event_timestamp END) as first_change_time
  FROM `conicle-ai-dev.consent_analytics.consent_events`
  WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  GROUP BY session_id
  HAVING first_consent_time IS NOT NULL 
    AND first_change_time IS NOT NULL
)
SELECT 
  COUNT(*) as users_who_changed,
  ROUND(AVG(TIMESTAMP_DIFF(first_change_time, first_consent_time, SECOND)) / 60, 2) as avg_minutes_to_change,
  MIN(TIMESTAMP_DIFF(first_change_time, first_consent_time, SECOND)) as min_seconds,
  MAX(TIMESTAMP_DIFF(first_change_time, first_consent_time, SECOND)) as max_seconds
FROM user_events;

-- ====================
-- 7. PAGE ANALYSIS
-- ====================

-- Which pages show the banner most?
SELECT 
  page_url,
  COUNT(*) as consent_events,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type IN ('consent', 'first_consent')
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY page_url
HAVING consent_events > 10
ORDER BY consent_events DESC
LIMIT 20;

-- ====================
-- 8. HOURLY PATTERNS
-- ====================

-- Acceptance rate by hour of day
SELECT 
  EXTRACT(HOUR FROM event_timestamp) as hour_of_day,
  COUNT(*) as total_events,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- ====================
-- 9. COHORT ANALYSIS
-- ====================

-- New vs returning user consent behavior
WITH user_first_seen AS (
  SELECT 
    session_id,
    MIN(DATE(event_timestamp)) as first_seen_date
  FROM `conicle-ai-dev.consent_analytics.consent_events`
  GROUP BY session_id
)
SELECT 
  CASE 
    WHEN uf.first_seen_date = DATE(e.event_timestamp) THEN 'New User'
    ELSE 'Returning User'
  END as user_type,
  COUNT(*) as consents,
  COUNTIF(e.accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(e.accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events` e
JOIN user_first_seen uf ON e.session_id = uf.session_id
WHERE e.event_type = 'consent'
  AND DATE(e.event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY user_type;

-- ====================
-- 10. DATA QUALITY
-- ====================

-- Check for issues
SELECT 
  'Missing IP hash' as issue,
  COUNT(*) as count
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE ip_hash IS NULL
  AND DATE(event_timestamp) = CURRENT_DATE()

UNION ALL

SELECT 
  'Missing user agent' as issue,
  COUNT(*) as count
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE user_agent IS NULL
  AND DATE(event_timestamp) = CURRENT_DATE()

UNION ALL

SELECT 
  'Missing page URL' as issue,
  COUNT(*) as count
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE page_url IS NULL
  AND DATE(event_timestamp) = CURRENT_DATE();

-- ====================
-- 11. EXPORT FOR DASHBOARDS
-- ====================

-- Summary stats for Looker Studio / Data Studio
CREATE OR REPLACE VIEW `conicle-ai-dev.consent_analytics.daily_summary` AS
SELECT 
  DATE(event_timestamp) as date,
  COUNT(*) as total_events,
  COUNT(DISTINCT session_id) as unique_sessions,
  COUNTIF(event_type = 'first_consent') as first_time_consents,
  COUNTIF(event_type = 'change') as preference_changes,
  COUNTIF(accept_type = 'all') as accepted_all,
  COUNTIF(accept_type = 'necessary') as rejected_all,
  COUNTIF(accept_type = 'custom') as custom_selection,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as accept_all_rate,
  COUNTIF('analytics' IN UNNEST(accepted_categories)) as accepted_analytics,
  COUNTIF('marketing' IN UNNEST(accepted_categories)) as accepted_marketing
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type IN ('consent', 'first_consent', 'change')
GROUP BY date
ORDER BY date DESC;

-- ====================
-- 12. CLEANUP (Run Monthly)
-- ====================

-- Delete events older than 2 years (GDPR compliance)
-- DELETE FROM `conicle-ai-dev.consent_analytics.consent_events`
-- WHERE DATE(event_timestamp) < DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);

-- Note: Uncomment the above to actually delete. Run as scheduled query.
