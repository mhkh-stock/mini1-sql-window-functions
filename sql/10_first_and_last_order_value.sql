-- 10 — First and last order value per customer
-- Business question: Did a customer's order value grow or shrink from their first to their last order?
-- Teaches: FIRST_VALUE(), LAST_VALUE(), and why LAST_VALUE needs an explicit frame.
-- LAST_VALUE with the default frame returns the CURRENT row's value, not
-- the last row's — so this query sets ROWS BETWEEN UNBOUNDED PRECEDING
-- AND UNBOUNDED FOLLOWING for the last value, and uses DISTINCT to keep
-- one row per customer.
-- Run: sqlite3 data/demo.db < sql/10_first_and_last_order_value.sql

WITH order_totals AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price_at_sale) AS order_total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT DISTINCT
    c.name AS customer,
    FIRST_VALUE(order_total) OVER (
        PARTITION BY order_totals.customer_id ORDER BY order_date, order_id
    ) AS first_order_value,
    LAST_VALUE(order_total) OVER (
        PARTITION BY order_totals.customer_id ORDER BY order_date, order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_order_value
FROM order_totals
JOIN customers c ON c.customer_id = order_totals.customer_id
ORDER BY customer;
