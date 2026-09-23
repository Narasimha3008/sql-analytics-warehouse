# Case study: from 3.4s to 6ms with one composite index

**The query** (`01_slow_query.sql`): latest completed order per customer, written
with two correlated scalar subqueries (a classic N+1 pattern).

## Before — no supporting index

`EXPLAIN QUERY PLAN` shows the problem immediately:

```
|--SCAN c
|--CORRELATED SCALAR SUBQUERY 1
|  |--SCAN o                      <-- full table scan, once per customer
|  `--USE TEMP B-TREE FOR ORDER BY
`--CORRELATED SCALAR SUBQUERY 2
   |--SCAN o                      <-- ...and again
   `--USE TEMP B-TREE FOR ORDER BY
```

Each of the 2,000 customers triggers **two full scans** of the 15,000-row
orders table — 4,000 scans total.

| Run | Time |
|-----|------|
| 1 | 3.378s |
| 2 | 3.597s |
| 3 | 3.242s |

## The fix — one composite index (`02_add_index.sql`)

```sql
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date);
```

`customer_id` serves the correlated lookup; `order_date` serves the
`ORDER BY ... LIMIT 1`, so every subquery becomes a single index seek.

## After — with the index

```
|--SCAN c
|--CORRELATED SCALAR SUBQUERY 1
|  `--SEARCH o USING INDEX idx_orders_customer_date (customer_id=?)
`--CORRELATED SCALAR SUBQUERY 2
   `--SEARCH o USING INDEX idx_orders_customer_date (customer_id=?)
```

| Run | Time |
|-----|------|
| 1 | 0.008s |
| 2 | 0.006s |
| 3 | 0.006s |

**Result: ~560x faster.** Same query, same data — the only change is the index.

## Takeaways

1. **Read the plan before rewriting the query.** `SCAN` inside a correlated
   subquery is the tell: cost multiplies by the outer row count.
2. **Composite indexes should match the access pattern**: equality column(s)
   first, then the ordering/range column.
3. **Measure, don't assume.** On this dataset a window-function rewrite was
   actually *slower* than the indexed correlated subquery (0.030s vs 0.006s) —
   the sort cost dominated. The plan and the timer decide, not the idiom.
