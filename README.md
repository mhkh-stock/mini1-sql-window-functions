# Mini #1 — SQL Window Functions Pack

**SAMPLE / DEMO data only.** Fictional shop, fictional people, fictional orders.
Never claimed as real client or real business data.

The exact skills entry-level SQL tests check: `ROW_NUMBER`, `RANK` / `DENSE_RANK`,
`LEAD` / `LAG`, `FIRST_VALUE` / `LAST_VALUE`, `NTILE`, cumulative and moving
windows, CTEs, and handling join duplication. One business question per file.

## Demo dataset

10 customers · 8 products · 32 orders · 52 order lines · Jan–Jun 2026 · PKR 346,800 total revenue.
Schema: `data/schema.sql` · Seed: `data/seed.sql` · Dictionary: `data/README.md` ·
Built database: `data/demo.db` (rebuild it any time from schema + seed).

## How to run (4 steps)

1. `cd mini1-sql-window-functions`
2. `rm -f data/demo.db && sqlite3 data/demo.db < data/schema.sql`
3. `sqlite3 data/demo.db < data/seed.sql`
4. Run any query, e.g. `sqlite3 -header -column data/demo.db < sql/01_top_products_per_category.sql`

Requires SQLite 3.25+ (window functions). Verified on SQLite 3.45.1.

## Queries

| File | Business question | Teaches | Verified output |
|---|---|---|---|
| `sql/01_top_products_per_category.sql` | Which 3 products earn most in each category? | `RANK` vs `DENSE_RANK`, `PARTITION BY` | 8 rows; top: Office Chair PKR 72,000 (Furniture), Dinner Set 24pc PKR 58,000 (Kitchen), Mechanical Keyboard PKR 51,000 (Electronics) |
| `sql/02_latest_order_per_customer.sql` | What is each customer's most recent order? | `ROW_NUMBER`, pre-aggregation | 10 rows, one per customer |
| `sql/03_running_total_monthly_revenue.sql` | How does revenue build up through the year? | Cumulative `SUM() OVER` | 6 months; Jan 37,100 → Jun running total 346,800 |
| `sql/04_days_between_repeat_orders.sql` | How quickly do customers come back? | `LAG`, `julianday` gaps | 32 rows; first order per customer correctly has NULL gap |
| `sql/05_three_month_moving_average.sql` | Is revenue trending up, or was one month a spike? | Sliding `ROWS BETWEEN` frame | 6 months; Jun moving average 76,400 vs Jun revenue 94,200 |
| `sql/06_customer_ranking_cte.sql` | Who are the top customers by spend? | CTE, aggregation before ranking | 10 rows; #1 Ayesha Khan PKR 56,700 (4 orders) |
| `sql/07_correct_totals_join_duplication.sql` | What is each customer's true total spend? | Aggregate BEFORE joining (join-duplication trap) | 10 rows; totals match query 06 exactly, sum 346,800 |
| `sql/08_share_of_category_revenue.sql` | How much does each product carry in its category? | `SUM() OVER (PARTITION BY)` | 8 rows; shares sum to 100% within each category |
| `sql/09_customer_spend_quartiles.sql` | Who is in the top quarter by spend? | `NTILE(4)` | 10 rows; quartile 1: Ayesha Khan, Bilal Ahmed, Fatima Noor |
| `sql/10_first_and_last_order_value.sql` | Did order value grow from first to last order? | `FIRST_VALUE` / `LAST_VALUE` (explicit frame for last) | 10 rows; e.g. Ayesha Khan 11,800 → 12,000 |

## Verification (done before delivery)

- All 10 files above execute against `data/demo.db` with no errors (one bug found
  and fixed during verification: ambiguous `customer_id` in query 10).
- Reconciliation: total revenue 346,800 = monthly sum 346,800 = customer sum 346,800.
- Query 06 and query 07 agree on every customer total and on the #1 customer.
- Verified outputs are saved in `outputs/` (one `.txt` per query).

## Note for the publisher

At delivery time this folder also contained 8 additional `sql/` files written
concurrently by another worker (`01_customer_running_total.sql`,
`02_rank_vs_dense_rank.sql`, `03_days_between_orders_lag.sql`,
`04_monthly_running_total.sql`, `05_top3_per_category.sql`,
`06_moving_average_3_orders.sql`, `07_join_duplication_trap.sql`,
`08_share_of_category_total.sql`). They are NOT part of the verified 10-file set
above — deduplicate before publishing so the mini ships as one clean set.
No GitHub repo was created and nothing was pushed, per the task.
