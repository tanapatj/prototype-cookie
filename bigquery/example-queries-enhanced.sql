-- Enhanced BigQuery Queries with New Fields
-- Project: conicle-ai-dev
-- Dataset: consent_analytics
-- Table: consent_events

-- ====================
-- 1. VIEW RECENT EVENTS WITH NEW FIELDS
-- ====================

SELECT 
  event_timestamp,
  action_label,  -- Thai/English label
  ip_address,    -- Raw IP (now available!)
  accepted_categories,
  utm_source,
  utm_campaign,
  browser_name,
  device_type,
  page_url
FROM `conicle-ai-dev.consent_analytics.consent_events`
ORDER BY event_timestamp DESC
LIMIT 10;

-- ====================
-- 2. ACTION LABELS (Thai) BREAKDOWN
-- ====================

SELECT 
  action_label,
  COUNT(*) as total,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY action_label
ORDER BY total DESC;

-- ====================
-- 3. TRAFFIC SOURCE ANALYSIS (UTM)
-- ====================

-- Top traffic sources
SELECT 
  utm_source,
  utm_medium,
  utm_campaign,
  COUNT(*) as visitors,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND utm_source IS NOT NULL
GROUP BY utm_source, utm_medium, utm_campaign
ORDER BY visitors DESC
LIMIT 20;

-- ====================
-- 4. GOOGLE ADS PERFORMANCE (GCLID)
-- ====================

SELECT 
  DATE(event_timestamp) as date,
  COUNT(DISTINCT gclid) as unique_clicks,
  COUNT(*) as consent_events,
  COUNTIF(accept_type = 'all') as conversions,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as conversion_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE gclid IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;

-- ====================
-- 5. FACEBOOK ADS PERFORMANCE (FBCLID)
-- ====================

SELECT 
  DATE(event_timestamp) as date,
  COUNT(DISTINCT fbclid) as unique_clicks,
  COUNT(*) as consent_events,
  COUNTIF(accept_type = 'all') as conversions,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as conversion_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE fbclid IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;

-- ====================
-- 6. IP ADDRESS ANALYSIS (NOW AVAILABLE!)
-- ====================

-- Top IP addresses by consent events
SELECT 
  ip_address,
  COUNT(*) as total_events,
  COUNT(DISTINCT session_id) as unique_sessions,
  ARRAY_AGG(DISTINCT action_label IGNORE NULLS) as actions,
  MAX(event_timestamp) as last_seen
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) = CURRENT_DATE()
  AND ip_address IS NOT NULL
GROUP BY ip_address
HAVING total_events > 1
ORDER BY total_events DESC
LIMIT 20;

-- ====================
-- 7. CAMPAIGN EFFECTIVENESS
-- ====================

-- Which campaigns drive the most "Accept All"?
SELECT 
  utm_campaign,
  utm_source,
  utm_medium,
  COUNT(*) as total_visitors,
  COUNTIF(accept_type = 'all') as accepted_all,
  COUNTIF(accept_type = 'necessary') as rejected_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as accept_all_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type IN ('consent', 'first_consent')
  AND utm_campaign IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY utm_campaign, utm_source, utm_medium
HAVING total_visitors > 10
ORDER BY accept_all_rate DESC
LIMIT 20;

-- ====================
-- 8. FULL VISITOR JOURNEY (with UTM)
-- ====================

SELECT 
  session_id,
  MIN(event_timestamp) as first_seen,
  MAX(event_timestamp) as last_seen,
  ARRAY_AGG(action_label ORDER BY event_timestamp) as journey,
  ANY_VALUE(utm_source) as traffic_source,
  ANY_VALUE(utm_campaign) as campaign,
  ANY_VALUE(browser_name) as browser,
  ANY_VALUE(device_type) as device
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND session_id IS NOT NULL
GROUP BY session_id
HAVING COUNT(*) > 1  -- Users who changed their mind
ORDER BY first_seen DESC
LIMIT 50;

-- ====================
-- 9. PAID VS ORGANIC TRAFFIC
-- ====================

SELECT 
  CASE 
    WHEN gclid IS NOT NULL OR fbclid IS NOT NULL THEN 'Paid Traffic'
    WHEN utm_source IS NOT NULL THEN 'Campaign Traffic'
    ELSE 'Organic/Direct'
  END as traffic_type,
  COUNT(*) as total_visitors,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate,
  COUNT(DISTINCT ip_address) as unique_ips
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY traffic_type
ORDER BY total_visitors DESC;

-- ====================
-- 10. URL PARAMETERS BREAKDOWN
-- ====================

-- What UTM parameters are being used?
SELECT 
  'utm_source' as parameter_type,
  utm_source as value,
  COUNT(*) as occurrences
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE utm_source IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY utm_source

UNION ALL

SELECT 
  'utm_medium' as parameter_type,
  utm_medium as value,
  COUNT(*) as occurrences
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE utm_medium IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY utm_medium

UNION ALL

SELECT 
  'utm_campaign' as parameter_type,
  utm_campaign as value,
  COUNT(*) as occurrences
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE utm_campaign IS NOT NULL
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY utm_campaign

ORDER BY occurrences DESC
LIMIT 50;

-- ====================
-- 11. DEVICE & BROWSER BY TRAFFIC SOURCE
-- ====================

SELECT 
  utm_source,
  device_type,
  browser_name,
  COUNT(*) as visitors,
  COUNTIF(accept_type = 'all') as accepted_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE event_type = 'consent'
  AND DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND utm_source IS NOT NULL
GROUP BY utm_source, device_type, browser_name
HAVING visitors > 5
ORDER BY visitors DESC
LIMIT 30;

-- ====================
-- 12. IP-BASED DUPLICATE DETECTION
-- ====================

-- Find potential duplicate consents from same IP
SELECT 
  ip_address,
  COUNT(DISTINCT session_id) as unique_sessions,
  COUNT(*) as total_events,
  ARRAY_AGG(DISTINCT action_label IGNORE NULLS LIMIT 5) as actions,
  MIN(event_timestamp) as first_event,
  MAX(event_timestamp) as last_event
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND ip_address IS NOT NULL
GROUP BY ip_address
HAVING unique_sessions > 3  -- Same IP, multiple sessions (suspicious?)
ORDER BY total_events DESC
LIMIT 20;

-- ====================
-- 13. CAMPAIGN ROI DASHBOARD VIEW
-- ====================

CREATE OR REPLACE VIEW `conicle-ai-dev.consent_analytics.campaign_performance` AS
SELECT 
  DATE(event_timestamp) as date,
  utm_source,
  utm_medium,
  utm_campaign,
  COUNT(DISTINCT session_id) as unique_visitors,
  COUNT(*) as total_events,
  COUNTIF(event_type = 'first_consent') as new_visitors,
  COUNTIF(accept_type = 'all') as accepted_all,
  COUNTIF(accept_type = 'necessary') as rejected_all,
  ROUND(COUNTIF(accept_type = 'all') * 100.0 / COUNT(*), 2) as acceptance_rate,
  COUNT(DISTINCT CASE WHEN gclid IS NOT NULL THEN gclid END) as google_ads_clicks,
  COUNT(DISTINCT CASE WHEN fbclid IS NOT NULL THEN fbclid END) as facebook_ads_clicks
FROM `conicle-ai-dev.consent_analytics.consent_events`
WHERE utm_source IS NOT NULL
GROUP BY date, utm_source, utm_medium, utm_campaign
ORDER BY date DESC, unique_visitors DESC;

-- Query the view
-- SELECT * FROM `conicle-ai-dev.consent_analytics.campaign_performance` WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);
