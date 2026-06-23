-- Question 1:  Premium vs Freemium

SELECT
    d.date,
    SUM(CASE
            WHEN a.paying_customer = 'no'
            THEN d.downloads
            ELSE 0
        END) AS non_paying_downloads,
    SUM(CASE
            WHEN a.paying_customer = 'yes'
            THEN d.downloads
            ELSE 0
        END) AS paying_downloads
FROM ms_download_facts d
JOIN ms_user_dimension u
    ON d.user_id = u.user_id
JOIN ms_acc_dimension a
    ON u.acc_id = a.acc_id
GROUP BY d.date
HAVING
    SUM(CASE
            WHEN a.paying_customer = 'no'
            THEN d.downloads
            ELSE 0
        END)
    >
    SUM(CASE
            WHEN a.paying_customer = 'yes'
            THEN d.downloads
            ELSE 0
        END)
ORDER BY d.date;



-- Question 2 : Minimum CPUs for Task Scheduling

WITH valid_tasks AS (
    SELECT DISTINCT
        task_id,
        start_time,
        end_time
    FROM task_schedule
    WHERE start_time IS NOT NULL
      AND end_time IS NOT NULL
),

events AS (
    SELECT
        start_time AS event_time,
        1 AS cpu_change
    FROM valid_tasks

    UNION ALL

    SELECT
        end_time AS event_time,
        -1 AS cpu_change
    FROM valid_tasks
),

running_count AS (
    SELECT
        event_time,
        SUM(cpu_change) OVER (
            ORDER BY event_time,
                     cpu_change
        ) AS active_tasks
    FROM events
)

SELECT MAX(active_tasks) AS min_cpus_required
FROM running_count;
