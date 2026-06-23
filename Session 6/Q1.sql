SELECT cc.customer_id
FROM customer_contracts cc
JOIN products p
    ON cc.product_id = p.product_id
GROUP BY cc.customer_id
HAVING COUNT(DISTINCT p.product_category) =
       (SELECT COUNT(DISTINCT product_category)
        FROM products);