-- 09 — Customer spend quartiles
-- Business question: Which customers are in the top quarter by spend?
-- Teaches: NTILE(), segmenting a ranked list into equal groups.
-- NTILE(4) splits the 10 customers into 4 buckets as evenly as possible
-- (3, 3, 2, 2 here). Quartile 1 is the highest spenders in this query
-- because the window orders by total_spend DESC.
-- Run: sqlite3 data/demo.db < sql/09_customer_spend_quartiles.sql

WITH customer_totals AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price_at_sale) AS total_spend
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    c.name AS customer,
    ct.total_spend,
    NTILE(4) OVER (ORDER BY ct.total_spend DESC) AS spend_quartile
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY spend_quartile, total_spend DESC;
