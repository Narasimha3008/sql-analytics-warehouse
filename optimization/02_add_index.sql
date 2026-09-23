-- The fix: a composite index on (customer_id, order_date).
-- customer_id serves the correlated lookup; order_date serves the ORDER BY,
-- so each subquery becomes a single index seek instead of a full table scan.

CREATE INDEX IF NOT EXISTS idx_orders_customer_date
    ON orders (customer_id, order_date);
