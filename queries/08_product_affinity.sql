-- 08 — Product affinity (market basket analysis)
-- Answers: which products are frequently bought together? (bundle/cross-sell ideas)
-- Techniques: self-join on the fact table, pair counting, support metric.

WITH pairs AS (
    SELECT
        a.product_id AS product_a,
        b.product_id AS product_b,
        a.order_id
    FROM order_items a
    JOIN order_items b
      ON b.order_id = a.order_id
     AND b.product_id > a.product_id      -- each unordered pair counted once
    JOIN orders o ON o.order_id = a.order_id
    WHERE o.order_status = 'completed'
)
SELECT
    pa.product_name AS product_a,
    pb.product_name AS product_b,
    COUNT(*) AS times_bought_together,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders WHERE order_status = 'completed'), 2)
        AS pct_of_orders
FROM pairs
JOIN products pa ON pa.product_id = pairs.product_a
JOIN products pb ON pb.product_id = pairs.product_b
GROUP BY product_a, product_b
HAVING COUNT(*) >= 20
ORDER BY times_bought_together DESC
LIMIT 15;
