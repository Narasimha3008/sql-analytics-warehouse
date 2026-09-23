-- SLOW: most recent completed order per customer, written with a correlated
-- subquery. The subquery re-executes once per customer (N+1 pattern),
-- and the plan shows a full SCAN of orders for every outer row.

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    (SELECT o.order_id
     FROM orders o
     WHERE o.customer_id = c.customer_id
       AND o.order_status = 'completed'
     ORDER BY o.order_date DESC
     LIMIT 1) AS latest_order_id,
    (SELECT o.order_date
     FROM orders o
     WHERE o.customer_id = c.customer_id
       AND o.order_status = 'completed'
     ORDER BY o.order_date DESC
     LIMIT 1) AS latest_order_date
FROM customers c;
