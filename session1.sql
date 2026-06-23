-- 1.Acceptance Rate By Date

WITH sent_requests AS (
    SELECT user_id_sender,
           user_id_receiver,
           date AS sent_date
    FROM fb_friend_requests
    WHERE action = 'sent'
),
accepted_requests AS (
    SELECT user_id_sender,
           user_id_receiver
    FROM fb_friend_requests
    WHERE action = 'accepted'
)

SELECT
    s.sent_date,
    ROUND(
        COUNT(a.user_id_sender) * 1.0 / COUNT(*),
        2
    ) AS acceptance_rate
FROM sent_requests s
LEFT JOIN accepted_requests a
       ON s.user_id_sender = a.user_id_sender
      AND s.user_id_receiver = a.user_id_receiver
GROUP BY s.sent_date
HAVING COUNT(a.user_id_sender) > 0
ORDER BY s.sent_date;



-- 2. Daily Revenue

WITH purchases AS (
    SELECT
        transaction_date,
        SUM(amount) AS purchase_revenue
    FROM transactions
    WHERE product_id = 'PROD-2891'
      AND country = 'US'
      AND status = 'completed'
      AND transaction_type = 'purchase'
      AND transaction_date BETWEEN '2025-04-15' AND '2025-04-28'
    GROUP BY transaction_date
),

refunds AS (
    SELECT
        r.transaction_date,
        SUM(r.amount) AS refund_revenue
    FROM transactions r
    JOIN transactions p
      ON r.original_transaction_id = p.transaction_id
    WHERE r.transaction_type = 'refund'
      AND r.status = 'completed'
      AND p.transaction_type = 'purchase'
      AND p.status = 'completed'
      AND p.product_id = 'PROD-2891'
      AND p.country = 'US'
      AND p.transaction_date BETWEEN '2025-04-15' AND '2025-04-28'
    GROUP BY r.transaction_date
),

dates AS (
    SELECT generate_series(
        DATE '2025-04-15',
        DATE '2025-04-28',
        INTERVAL '1 day'
    )::date AS transaction_date
)

SELECT
    d.transaction_date,
    COALESCE(p.purchase_revenue,0)
      - COALESCE(r.refund_revenue,0) AS daily_net_revenue
FROM dates d
LEFT JOIN purchases p
    ON d.transaction_date = p.transaction_date
LEFT JOIN refunds r
    ON d.transaction_date = r.transaction_date
ORDER BY d.transaction_date;



-- 3. Finding User Purchases
WITH cte AS (
    SELECT
        user_id,
        created_at,
        ROW_NUMBER() OVER(
            PARTITION BY user_id
            ORDER BY created_at
        ) AS rn
    FROM amazon_transactions
)

SELECT c1.user_id
FROM cte c1
JOIN cte c2
    ON c1.user_id = c2.user_id
WHERE c1.rn = 1
  AND c2.rn = 2
  AND DATEDIFF(day, c1.created_at, c2.created_at) BETWEEN 1 AND 7;


-- 4. Search Click Success Rate by User Segment
WITH max_dt AS (
    SELECT DATE(MAX(event_timestamp)) AS max_date
    FROM search_events
),

user_segments AS (
    SELECT
        a.user_id,
        CASE
            WHEN a.registration_date >= max_date - INTERVAL '30 days'
                THEN 'new'
            ELSE 'existing'
        END AS user_segment
    FROM accounts a
    CROSS JOIN max_dt
),

searches AS (
    SELECT
        event_id,
        user_id,
        session_id,
        event_timestamp AS search_time
    FROM search_events
    WHERE event_type = 'search'
),

search_status AS (
    SELECT
        s.event_id,
        s.user_id,
        CASE
            WHEN MIN(c.event_timestamp) <= s.search_time + INTERVAL '30 seconds'
                THEN 1
            ELSE 0
        END AS successful_search
    FROM searches s
    LEFT JOIN search_events c
        ON s.user_id = c.user_id
       AND s.session_id = c.session_id
       AND c.event_type = 'click'
       AND c.event_timestamp > s.search_time
    GROUP BY s.event_id, s.user_id, s.search_time
)

SELECT
    u.user_segment,
    COUNT(*) AS total_searches,
    SUM(successful_search) AS successful_searches,
    ROUND(
        SUM(successful_search)::numeric / COUNT(*),
        4
    ) AS success_rate
FROM search_status ss
JOIN user_segments u
    ON ss.user_id = u.user_id
GROUP BY u.user_segment
ORDER BY u.user_segment;
