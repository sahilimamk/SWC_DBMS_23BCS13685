-- 1. Finding User Purchases
WITH cte AS (
    SELECT
        user_id,
        created_at,
        LEAD(created_at) OVER (
            PARTITION BY user_id
            ORDER BY created_at
        ) AS second_purchase
    FROM amazon_transactions
)

SELECT DISTINCT user_id
FROM cte
WHERE second_purchase - created_at BETWEEN 1 AND 7;


-- 2. Search Click Success Rate by User Segment
WITH max_date AS (
    SELECT DATE(MAX(event_timestamp)) AS mx_dt
    FROM search_events
),

user_segment AS (
    SELECT
        a.user_id,
        CASE
            WHEN a.registration_date >= mx_dt - INTERVAL '30 day'
                THEN 'new'
            ELSE 'existing'
        END AS segment
    FROM accounts a
    CROSS JOIN max_date
),

search_clicks AS (
    SELECT
        s.event_id,
        s.user_id,
        s.event_timestamp AS search_time,
        MIN(c.event_timestamp) AS first_click_time
    FROM search_events s
    LEFT JOIN search_events c
        ON s.session_id = c.session_id
       AND s.user_id = c.user_id
       AND c.event_type = 'click'
       AND c.event_timestamp > s.event_timestamp
    WHERE s.event_type = 'search'
    GROUP BY
        s.event_id,
        s.user_id,
        s.event_timestamp
)

SELECT
    u.segment,
    COUNT(*) AS total_searches,
    SUM(
        CASE
            WHEN first_click_time <= search_time + INTERVAL '30 second'
            THEN 1
            ELSE 0
        END
    ) AS successful_searches,
    ROUND(
        AVG(
            CASE
                WHEN first_click_time <= search_time + INTERVAL '30 second'
                THEN 1.0
                ELSE 0.0
            END
        ),
        4
    ) AS success_rate
FROM search_clicks sc
JOIN user_segment u
    ON sc.user_id = u.user_id
GROUP BY u.segment
ORDER BY u.segment;
