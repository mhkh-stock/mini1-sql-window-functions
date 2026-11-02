-- 01 — Top products per category
-- Business question: Inside each category, which 3 products earn the most?
-- Teaches: RANK() vs DENSE_RANK(), PARTITION BY, CTEs.
-- Why RANK matters: two products tied on revenue share a rank, and the
-- next rank is skipped (1, 2, 2, 4). DENSE_RANK does not skip (1, 2, 2, 3).
-- Run: sqlite3 data/demo.db < sql/01_top_products_per_category.sql

WITH product_revenue AS (
    SELECT
        p.category,
        p.name AS product,
        SUM(oi.quantity * oi.unit_price_at_sale) AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category, p.name
),
ranked AS (
    SELECT
        category,
        product,
        revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_no,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS dense_rank_no
    FROM product_revenue
)
SELECT category, product, revenue, rank_no, dense_rank_no
FROM ranked
WHERE rank_no <= 3
ORDER BY category, rank_no, product;
