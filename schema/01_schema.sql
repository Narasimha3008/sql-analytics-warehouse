-- ============================================================================
--  Retail Data Warehouse — schema
--  Star schema: one fact table (orders/order_items) and three dimensions
--  (customers, products, dates via order_date). Designed for SQLite, but the
--  SQL is written to be portable to Snowflake / Postgres / SQL Server.
-- ============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    first_name      TEXT    NOT NULL,
    last_name       TEXT    NOT NULL,
    email           TEXT    NOT NULL UNIQUE,
    city            TEXT    NOT NULL,
    state           TEXT    NOT NULL,
    region          TEXT    NOT NULL,          -- Northeast | Midwest | South | West
    signup_date     DATE    NOT NULL
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT    NOT NULL,
    category        TEXT    NOT NULL,          -- Electronics | Apparel | Home | Sports
    subcategory     TEXT    NOT NULL,
    unit_cost       NUMERIC NOT NULL,
    unit_price      NUMERIC NOT NULL
);

CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers (customer_id),
    order_date      DATE    NOT NULL,
    order_status    TEXT    NOT NULL,          -- completed | cancelled | returned
    shipping_mode   TEXT    NOT NULL           -- standard | express | same-day
);

CREATE TABLE order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders (order_id),
    product_id      INTEGER NOT NULL REFERENCES products (product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    discount_pct    NUMERIC NOT NULL DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 1)
);

-- Indexes that serve the analytical workload in /queries and /optimization.
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date);
CREATE INDEX idx_orders_date          ON orders (order_date);
CREATE INDEX idx_order_items_order    ON order_items (order_id);
CREATE INDEX idx_order_items_product  ON order_items (product_id);
