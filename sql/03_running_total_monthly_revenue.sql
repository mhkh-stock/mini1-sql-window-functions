-- 03 — Running total of monthly revenue
-- Business question: How does revenue build up through the year, month by month?
-- Teaches: SUM() OVER (ORDER BY ...), cumulative windows, strftime for months.
-- The default window (UNBOUNDED PRECEDING to CURRENT ROW) is what makes
-- this a running total instead of a plain monthly total.
-- Run: sqlite3 data/demo.db < sql/03_running_total_monthly_revenue.sql

WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price_at_sale) AS revenue,
        COUNT(DISTINCT o.order_id) AS orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    month,
    revenue,
    orders,
    SUM(revenue) OVER (ORDER BY month) AS running_total
FROM monthly
ORDER BY month;
