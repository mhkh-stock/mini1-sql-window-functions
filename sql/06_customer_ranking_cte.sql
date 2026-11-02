-- 06 — Customer ranking with a CTE
-- Business question: Who are the top customers by total spend, and how many orders did that take?
-- Teaches: CTEs (WITH), aggregation before ranking, RANK().
-- The CTE answers "how much did each customer spend?" first. Ranking
-- that small result is then trivial — and it avoids ranking raw order
-- lines, which would double-count nothing but confuse the question.
-- Run: sqlite3 data/demo.db < sql/06_customer_ranking_cte.sql

WITH customer_totals AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.quantity * oi.unit_price_at_sale) AS total_spend
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    c.name AS customer,
    c.city,
    ct.orders,
    ct.total_spend,
    RANK() OVER (ORDER BY ct.total_spend DESC) AS spend_rank
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY spend_rank, customer;
