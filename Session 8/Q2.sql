WITH ranked_salaries AS (
    SELECT
        department,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS salary_rank
    FROM (
        SELECT DISTINCT department, salary
        FROM twitter_employee
    ) t
)

SELECT
    department,
    salary
FROM ranked_salaries
WHERE salary_rank <= 3
ORDER BY department, salary DESC;