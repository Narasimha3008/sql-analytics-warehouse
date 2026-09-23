-- 07 — Churned customers (no completed order in the last 90 days)
-- Answers: how many customers have gone quiet, and what did they used to spend?
-- Techniques: anti-join pattern, date arithmetic relative to max order date.

WITH params AS (
    SELECT date(MAX(order_date), '-90 days') AS churn_cutoff
    FROM orders
    WHERE order_status = 'completed'
),
prior_spend AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_order_date,
        SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct)) AS lifetime_spend
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.region,
    ps.last_order_date,
    CAST(julianday((SELECT MAX(order_date) FROM orders WHERE order_status = 'completed'))
         - julianday(ps.last_order_date) AS INTEGER) AS days_since_last_order,
    ROUND(ps.lifetime_spend, 2) AS lifetime_spend
FROM customers c
JOIN prior_spend ps ON ps.customer_id = c.customer_id
CROSS JOIN params
WHERE ps.last_order_date < params.churn_cutoff
ORDER BY ps.lifetime_spend DESC;
