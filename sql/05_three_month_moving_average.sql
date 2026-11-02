-- 05 — Three-month moving average of revenue
-- Business question: Is monthly revenue really trending up, or was one month a spike?
-- Teaches: AVG() OVER (... ROWS BETWEEN ...), sliding frames.
-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW averages this month with the
-- two months before it. Early months average over fewer rows — that is
-- honest, and it is why the first two rows differ from a full 3-month mean.
-- Run: sqlite3 data/demo.db < sql/05_three_month_moving_average.sql

WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price_at_sale) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        0
    ) AS moving_avg_3m
FROM monthly
ORDER BY month;
