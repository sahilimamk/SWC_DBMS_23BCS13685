-- Question 1: Customer Revenue In March
SELECT
    cust_id,
    SUM(total_order_cost) AS revenue
FROM orders
WHERE order_date >= '2019-03-01'
  AND order_date < '2019-04-01'
GROUP BY cust_id
ORDER BY revenue DESC;


-- Question 2: Product Engagement Momentum Shifts
WITH trends AS (
    SELECT
        product_id,
        product_name,
        month_start,
        monthly_active_users,
        LAG(monthly_active_users) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS prev_users
    FROM product_engagement
),

flags AS (
    SELECT *,
           CASE
               WHEN monthly_active_users < prev_users THEN 'D'
               WHEN monthly_active_users > prev_users THEN 'G'
           END AS trend
    FROM trends
),

patterns AS (
    SELECT
        product_id,
        product_name,

        month_start AS growth_resume_month,

        LAG(month_start,3) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS decline_start_month,

        monthly_active_users AS growth_start_users,

        LAG(monthly_active_users,3) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS lowest_users,

        LEAD(monthly_active_users,2) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS peak_users,

        trend,

        LAG(trend,1) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS t1,

        LAG(trend,2) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS t2,

        LAG(trend,3) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS t3,

        LEAD(trend,1) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS g1,

        LEAD(trend,2) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS g2
    FROM flags
)

SELECT
    product_name,
    decline_start_month,
    growth_resume_month,
    ROUND(
        (peak_users - lowest_users) * 1.0
        / lowest_users,
        2
    ) AS growth_ratio
FROM patterns
WHERE
      t3 = 'D'
  AND t2 = 'D'
  AND t1 = 'D'
  AND trend = 'G'
  AND g1 = 'G'
  AND g2 = 'G';
