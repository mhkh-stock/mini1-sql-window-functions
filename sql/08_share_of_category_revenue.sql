-- 08 — Each product's share of its category's revenue
-- Business question: Within its category, how much does each product really carry?
-- Teaches: SUM() OVER (PARTITION BY ...), window totals vs grand totals.
-- The window total is computed per category, so share = product revenue
-- divided by its own category total — not by the whole shop's revenue.
-- Run: sqlite3 data/demo.db < sql/08_share_of_category_revenue.sql

WITH product_revenue AS (
    SELECT
        p.category,
        p.name AS product,
        SUM(oi.quantity * oi.unit_price_at_sale) AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category, p.name
)
SELECT
    category,
    product,
    revenue,
    ROUND(
        100.0 * revenue
        / SUM(revenue) OVER (PARTITION BY category),
        1
    ) AS pct_of_category
FROM product_revenue
ORDER BY category, revenue DESC;
