-- 05 — Daily revenue with 7-day moving average and running total
-- Answers: what is the underlying trend beneath daily noise?
-- Techniques: window frames (ROWS BETWEEN), running aggregates.

WITH daily AS (
    SELECT
        o.order_date,
        SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.order_date
)
SELECT
    order_date,
    ROUND(revenue, 2) AS revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS revenue_7d_avg,
    ROUND(SUM(revenue) OVER (
        ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS revenue_running_total
FROM daily
ORDER BY order_date;
