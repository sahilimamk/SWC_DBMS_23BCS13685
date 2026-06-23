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