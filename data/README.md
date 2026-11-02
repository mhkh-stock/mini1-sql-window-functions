# Data dictionary — Mini #1 (SAMPLE / DEMO data only)
Fictional shop, fictional people, fictional orders, Jan–Jun 2026.
10 customers · 8 products · 32 orders · 52 order lines. All money in PKR.

| Table | Column | Meaning |
|---|---|---|
| customers | customer_id / name / city / signup_date | One row per customer |
| products | product_id / name / category / unit_price | List price (PKR); sale price lives on order_items |
| orders | order_id / customer_id / order_date | One row per order |
| order_items | order_item_id / order_id / product_id / quantity / unit_price_at_sale | One row per product line in an order; order total = SUM(quantity × unit_price_at_sale) |

Run: `sqlite3 demo.db < data/schema.sql` then `sqlite3 demo.db < data/seed.sql`, then any file in `sql/`.
