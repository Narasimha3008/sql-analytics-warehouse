-- 03 — Signup-month cohort retention
-- Answers: do newer cohorts stick around better than older ones?
-- Techniques: cohort bucketing, pivoting with conditional aggregation.

WITH first_orders AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS first_order_date
    FROM orders o
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
),
cohorts AS (
    SELECT
        c.customer_id,
        strftime('%Y-%m', c.signup_date) AS cohort_month,
        strftime('%Y-%m', fo.first_order_date) AS first_order_month
    FROM customers c
    JOIN first_orders fo ON fo.customer_id = c.customer_id
),
activity AS (
    SELECT
        co.cohort_month,
        strftime('%Y-%m', o.order_date) AS activity_month,
        COUNT(DISTINCT co.customer_id) AS active_customers
    FROM cohorts co
    JOIN orders o ON o.customer_id = co.customer_id
                 AND o.order_status = 'completed'
                 AND o.order_date >= co.first_order_month || '-01'
    GROUP BY co.cohort_month, activity_month
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS customers
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    a.cohort_month,
    a.activity_month,
    a.active_customers,
    cs.customers AS cohort_size,
    ROUND(a.active_customers * 100.0 / cs.customers, 1) AS retention_pct
FROM activity a
JOIN cohort_size cs ON cs.cohort_month = a.cohort_month
ORDER BY a.cohort_month, a.activity_month;
