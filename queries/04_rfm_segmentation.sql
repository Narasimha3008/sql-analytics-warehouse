-- 04 — RFM customer segmentation
-- Answers: who are the champions, loyalists, and at-risk customers?
-- Techniques: CTEs, NTILE scoring, CASE-based segment labels.

WITH rfm_base AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct)) AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
),
scored AS (
    SELECT
        customer_id,
        CAST(julianday((SELECT MAX(order_date) FROM orders)) - julianday(last_order_date) AS INTEGER) AS recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY last_order_date DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)            AS f_score,
        NTILE(5) OVER (ORDER BY monetary)             AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    (r_score + f_score + m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 2 THEN 'Loyal'
        WHEN r_score >= 3 AND m_score >= 4 THEN 'Big Spenders'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Needs Attention'
    END AS segment
FROM scored
ORDER BY rfm_score DESC, monetary DESC;
