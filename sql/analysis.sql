-- SQLite queries run against the cleaned `events` table created by the notebook.
-- Percentages describe recorded synthetic events, not attack risk or prevention efficacy.

-- name: overview
SELECT COUNT(*) AS events,
       MIN(date(timestamp)) AS first_date,
       MAX(date(timestamp)) AS last_date,
       ROUND(100.0 * AVG(CASE WHEN severity_level = 'High' THEN 1 ELSE 0 END), 2) AS high_severity_pct,
       ROUND(100.0 * AVG(CASE WHEN action_taken = 'Blocked' THEN 1 ELSE 0 END), 2) AS blocked_pct,
       SUM(CASE WHEN severity_level = 'High' AND action_taken = 'Ignored' THEN 1 ELSE 0 END) AS high_ignored,
       ROUND(100.0 * SUM(CASE WHEN severity_level = 'High' AND action_taken = 'Ignored' THEN 1 ELSE 0 END)
             / NULLIF(SUM(CASE WHEN severity_level = 'High' THEN 1 ELSE 0 END), 0), 2) AS high_ignored_pct
FROM events;

-- name: segment_mix
WITH segment_counts AS (
    SELECT network_segment, attack_type, COUNT(*) AS events
    FROM events
    GROUP BY network_segment, attack_type
), overall_mix AS (
    SELECT attack_type, 1.0 * COUNT(*) / (SELECT COUNT(*) FROM events) AS overall_share
    FROM events
    GROUP BY attack_type
)
SELECT s.network_segment, s.attack_type, s.events,
       ROUND(100.0 * s.events / SUM(s.events) OVER (PARTITION BY s.network_segment), 2) AS segment_pct,
       ROUND(100.0 * o.overall_share, 2) AS overall_pct,
       ROUND(100.0 * s.events / SUM(s.events) OVER (PARTITION BY s.network_segment)
             - 100.0 * o.overall_share, 2) AS difference_pp
FROM segment_counts AS s
JOIN overall_mix AS o ON s.attack_type = o.attack_type
ORDER BY s.network_segment, s.events DESC;

-- name: severity_action
SELECT severity_level, action_taken, COUNT(*) AS events,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY severity_level), 2) AS within_severity_pct
FROM events
GROUP BY severity_level, action_taken
ORDER BY severity_level, action_taken;

-- name: monthly_activity
WITH monthly AS (
    SELECT strftime('%Y-%m-01', timestamp) AS month_start,
           COUNT(*) AS events,
           SUM(CASE WHEN action_taken = 'Blocked' THEN 1 ELSE 0 END) AS blocked,
           SUM(CASE WHEN action_taken = 'Ignored' THEN 1 ELSE 0 END) AS ignored
    FROM events
    GROUP BY strftime('%Y-%m-01', timestamp)
), changes AS (
    SELECT *, LAG(events) OVER (ORDER BY month_start) AS previous_events
    FROM monthly
)
SELECT month_start, events, blocked, ignored,
       ROUND(100.0 * blocked / events, 2) AS blocked_pct,
       ROUND(100.0 * ignored / events, 2) AS ignored_pct,
       ROUND(100.0 * (events - previous_events) / NULLIF(previous_events, 0), 2) AS change_pct
FROM changes
ORDER BY month_start;

-- name: state_rank
WITH state_counts AS (
    SELECT location_state, COUNT(*) AS events
    FROM events
    GROUP BY location_state
)
SELECT location_state, events,
       ROUND(100.0 * events / SUM(events) OVER (), 2) AS event_pct,
       DENSE_RANK() OVER (ORDER BY events DESC) AS volume_rank
FROM state_counts
ORDER BY volume_rank, location_state;

-- name: protocol_mix
-- Filtering retains the original model's anomaly-score threshold.
SELECT attack_type, protocol, COUNT(*) AS events,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY attack_type), 2) AS within_attack_pct
FROM events
WHERE anomaly_scores > 50
GROUP BY attack_type, protocol
ORDER BY attack_type, protocol;

-- name: high_severity_review
SELECT network_segment, COUNT(*) AS high_severity_events,
       SUM(CASE WHEN action_taken = 'Ignored' THEN 1 ELSE 0 END) AS ignored,
       ROUND(100.0 * AVG(CASE WHEN action_taken = 'Ignored' THEN 1 ELSE 0 END), 2) AS ignored_pct
FROM events
WHERE severity_level = 'High'
GROUP BY network_segment
ORDER BY ignored_pct DESC;
