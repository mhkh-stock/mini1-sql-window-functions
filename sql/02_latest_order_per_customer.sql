-- 02 — Latest order per customer
-- Business question: What is each customer's most recent order, and how much was it?
-- Teaches: ROW_NUMBER(), PARTITION BY, pre-aggregating before ranking.
-- The order total is built in a CTE first, so ROW_NUMBER ranks orders,
-- not individual order lines.
-- Run: sqlite3 data/demo.db < sql/02_latest_order_per_customer.sql

WITH order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price_at_sale) AS order_total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC, order_id DESC
        ) AS rn
    FROM order_totals
)
SELECT
    c.name AS customer,
    r.order_id,
    r.order_date,
    r.order_total
FROM ranked r
JOIN customers c ON c.customer_id = r.customer_id
WHERE r.rn = 1
ORDER BY r.order_date DESC;
