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

Or verify everything in one command: `python3 run_queries.py` — rebuilds
`data/demo.db`, runs all 10 queries, and asserts every number in the
table below (stdlib only, no dependencies).

Requires SQLite 3.25+ (window functions). Verified on SQLite 3.45.1.

## Queries

| File | Business question | Teaches | Verified output |
|---|---|---|---|
| `sql/01_top_products_per_category.sql` | Which 3 products earn most in each category? | `RANK` vs `DENSE_RANK`, `PARTITION BY` (both agree here — no revenue tie in the demo data) | 8 rows; top: Office Chair PKR 72,000 (Furniture), Dinner Set 24pc PKR 58,000 (Kitchen), Mechanical Keyboard PKR 51,000 (Electronics) |
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

- `python3 run_queries.py` — 27 checks, all passing: base counts, total
  revenue, monthly/customer reconciliation, every row count and headline
  figure in the table above, Q06/Q07 agreement, per-category shares
  summing to 100%, and quartile sizes/members.
- All 10 files above execute against `data/demo.db` with no errors (one bug found
  and fixed during verification: ambiguous `customer_id` in query 10).
- Reconciliation: total revenue 346,800 = monthly sum 346,800 = customer sum 346,800.
- Query 06 and query 07 agree on every customer total and on the #1 customer.
- Verified outputs are saved in `outputs/` (one `.txt` per query).

## Limits

- SAMPLE / DEMO data only — fictional shop, Jan–Jun 2026, SQLite only.
- No two products tie on revenue inside a category in this data, so query 01
  shows `RANK` and `DENSE_RANK` side by side but cannot demonstrate how they
  differ on a tie; the difference is explained in the file's header comment.
- Query 07's join-duplication trap is demonstrated in its comments only: this
  dataset has no order-level amount column to inflate, so the "wrong" pattern
  has nothing to over-count. The fix pattern (aggregate before joining) is
  what the query teaches, and its totals are verified against query 06.

## Note for the publisher

No GitHub repo was created and nothing was pushed, per the task.
