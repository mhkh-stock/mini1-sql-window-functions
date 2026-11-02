-- 07 — Correct totals when a join would duplicate rows
-- Business question: What is each customer's true total spend?
-- Teaches: the join-duplication trap, and the fix — aggregate BEFORE you join.
-- The trap: orders JOIN order_items gives one row per order LINE, not per
-- order. Summing an order-level value across that join would count it
-- once per line. This dataset has no order-level amount column to inflate,
-- so the trap is shown in the comment below and the fix is the pattern:
-- build order_totals in a CTE first, then join customers to that.
--
-- WRONG pattern (do NOT run as-is — it answers a different question):
--   SELECT c.name, SUM(o.something_per_order) ... FROM orders o
--   JOIN order_items oi ON oi.order_id = o.order_id GROUP BY c.name;
--   -- every order-level value is counted once per line. Wrong.
--
-- Run: sqlite3 data/demo.db < sql/07_correct_totals_join_duplication.sql

WITH order_totals AS (
    SELECT
        order_id,
        SUM(quantity * unit_price_at_sale) AS order_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    c.name AS customer,
    COUNT(o.order_id) AS orders,
    SUM(ot.order_total) AS total_spend
FROM orders o
JOIN order_totals ot ON ot.order_id = o.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.name
ORDER BY total_spend DESC;
