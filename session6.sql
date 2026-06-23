
Question 1:
SELECT cc.customer_id
FROM customer_contracts cc
JOIN products p
    ON cc.product_id = p.product_id
GROUP BY cc.customer_id
HAVING COUNT(DISTINCT p.product_category) =
       (SELECT COUNT(DISTINCT product_category)
        FROM products);


Question 2:
SELECT
    user_id,
    spend,
    transaction_date
FROM (
    SELECT
        user_id,
        spend,
        transaction_date,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY transaction_date
        ) AS rn
    FROM transactions
) t
WHERE rn = 3;
