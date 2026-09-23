-- 01 — Monthly revenue, profit, and order trend
-- Answers: is the business growing? Which months are strongest?
-- Techniques: date truncation, conditional aggregation, join of fact tables.

WITH line_revenue AS (
    SELECT
        o.order_id,
        o.order_date,
        SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct)) AS revenue,
        SUM(oi.quantity * (p.unit_price * (1 - oi.discount_pct) - p.unit_cost)) AS profit
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.order_id, o.order_date
)
SELECT
    strftime('%Y-%m', order_date) AS month,
    COUNT(*)                      AS orders,
    ROUND(SUM(revenue), 2)         AS revenue,
    ROUND(SUM(profit), 2)          AS profit,
    ROUND(SUM(profit) / SUM(revenue) * 100, 1) AS margin_pct
FROM line_revenue
GROUP BY month
ORDER BY month;
