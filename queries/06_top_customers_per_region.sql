-- 06 — Top 5 customers per region by lifetime spend
-- Answers: who are the VIPs in each region for targeted outreach?
-- Techniques: ranking window functions (RANK), PARTITION BY.

WITH spend AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.region,
        SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct)) AS lifetime_spend,
        COUNT(DISTINCT o.order_id) AS orders
    FROM customers c
    JOIN orders o      ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p    ON p.product_id = oi.product_id
    WHERE o.order_status = 'completed'
    GROUP BY c.customer_id, customer_name, c.region
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY region ORDER BY lifetime_spend DESC) AS region_rank
    FROM spend
)
SELECT
    region,
    region_rank,
    customer_name,
    orders,
    ROUND(lifetime_spend, 2) AS lifetime_spend
FROM ranked
WHERE region_rank <= 5
ORDER BY region, region_rank;
