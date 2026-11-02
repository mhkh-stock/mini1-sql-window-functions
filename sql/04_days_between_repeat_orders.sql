-- 04 — Days between a customer's repeat orders
-- Business question: How quickly do customers come back, and who has gone quiet?
-- Teaches: LAG(), PARTITION BY + ORDER BY, julianday() date arithmetic.
-- LAG looks at the previous row in the customer's own order history.
-- The first order per customer has no previous order, so gap_days is NULL
-- — that NULL is correct, not a missing value to fill with 0.
-- Run: sqlite3 data/demo.db < sql/04_days_between_repeat_orders.sql

SELECT
    c.name AS customer,
    o.order_id,
    o.order_date,
    LAG(o.order_date) OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date, o.order_id
    ) AS previous_order_date,
    CAST(
        julianday(o.order_date) - julianday(
            LAG(o.order_date) OVER (
                PARTITION BY o.customer_id
                ORDER BY o.order_date, o.order_id
            )
        ) AS INTEGER
    ) AS gap_days
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY c.name, o.order_date;
