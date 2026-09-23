-- 02 — Category & subcategory performance with share of total
-- Answers: which categories drive revenue, and at what margin?
-- Techniques: multi-level aggregation, windowed share-of-total.

WITH cat AS (
    SELECT
        p.category,
        p.subcategory,
        SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct)) AS revenue,
        SUM(oi.quantity * (p.unit_price * (1 - oi.discount_pct) - p.unit_cost)) AS profit,
        COUNT(DISTINCT o.order_id) AS orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.order_status = 'completed'
    GROUP BY p.category, p.subcategory
)
SELECT
    category,
    subcategory,
    orders,
    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2)  AS profit,
    ROUND(profit / revenue * 100, 1) AS margin_pct,
    ROUND(revenue / SUM(revenue) OVER () * 100, 1) AS pct_of_total_revenue
FROM cat
ORDER BY revenue DESC;
