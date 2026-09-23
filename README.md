# Retail SQL Analytics Warehouse

A from-scratch analytics warehouse for a fictional e-commerce retailer —
**2,000 customers, 24 products, 15,000 orders, 37,574 line items** — built to
show the SQL a data analyst actually uses on the job: complex joins, CTEs,
window functions, cohort analysis, segmentation, and query optimization.

All data is synthetic (seeded generator in `data/`), so every result below is
reproducible. Tested on SQLite; the SQL is written to port cleanly to
Snowflake, PostgreSQL, and SQL Server.

## Schema

Star schema — one fact area, three dimensions:

```
customers 1───∞ orders 1───∞ order_items ∞───1 products
```

| Table | Rows | Key columns |
|-------|------|-------------|
| `customers` | 2,000 | customer_id, region, signup_date |
| `products` | 24 | product_id, category, unit_cost, unit_price |
| `orders` | 15,000 | order_id, customer_id, order_date, order_status |
| `order_items` | 37,574 | order_id, product_id, quantity, discount_pct |

## Analysis queries (`queries/`)

| # | Query | Techniques | Headline result |
|---|-------|-----------|-----------------|
| 01 | Monthly revenue trend | date truncation, conditional aggregation | Revenue grew from **$27.8K (Jan 2024) to $418K (Aug 2026)** |
| 02 | Category performance | multi-level aggregation, share-of-total window | **Electronics / TV & Video** leads at $1.81M (21.2% of revenue) |
| 03 | Signup-month cohort retention | cohort bucketing, pivot via conditional aggregation | Retention tracked per cohort × activity month |
| 04 | RFM segmentation | CTEs, NTILE scoring, CASE labels | Customers scored into Champions / Loyal / At Risk / Lost |
| 05 | Daily revenue, 7-day MA, running total | window frames (`ROWS BETWEEN`) | Trend signal separated from daily noise |
| 06 | Top 5 customers per region | `RANK()` with `PARTITION BY` | VIP list per region for targeted outreach |
| 07 | Churned customers (90-day silence) | anti-join, date arithmetic | **748 customers** churned; ranked by recoverable lifetime spend |
| 08 | Product affinity (market basket) | self-join, pair counting, support metric | Top pair bought together **151 times** |

## Optimization case study (`optimization/`)

A correlated-subquery "latest order per customer" query ran in **~3.4s**
(`SCAN` of the orders table twice per customer). Adding one composite index
— `CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date)`
— turned both scans into index seeks: **~0.006s, ~560x faster**.
Full before/after plans and timings in [`optimization/README.md`](optimization/README.md).

## Run it yourself

```bash
# 1. Create the database from the CSVs
python3 data/generate_data.py --build-db

# 2. Run any analysis
sqlite3 data/retail.db < queries/04_rfm_segmentation.sql

# 3. Reproduce the optimization case study
#    (drop the index first to see the "before" plan)
sqlite3 data/retail.db "DROP INDEX idx_orders_customer_date;"
sqlite3 data/retail.db < optimization/01_slow_query.sql   # slow
sqlite3 data/retail.db < optimization/02_add_index.sql    # fix
sqlite3 data/retail.db < optimization/01_slow_query.sql   # fast
```

Requirements: Python 3 (standard library only) and `sqlite3`.

## Skills demonstrated

Advanced SQL (window functions, CTEs, correlated subqueries) · star-schema
data modeling · indexing and `EXPLAIN QUERY PLAN` analysis · cohort &
retention analysis · customer segmentation (RFM) · reproducible synthetic data
generation with Python
