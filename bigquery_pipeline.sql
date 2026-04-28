-- =============================================================================
-- E-Commerce Cohort & Retention Pipeline
-- Dialect : BigQuery / Databricks SQL
-- Author  : Portfolio Project
-- Updated : 2024
--
-- Architecture: Medallion (3 layers)
--   Raw      → cohort_db.ecom_orders
--   Cleaned  → cleaned.cleaned_orders
--   Analytics→ analytics.cohort_analysis
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LAYER 1 — RAW
-- Schema setup
-- -----------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS cohort_db;
CREATE SCHEMA IF NOT EXISTS cleaned;
CREATE SCHEMA IF NOT EXISTS analytics;


-- -----------------------------------------------------------------------------
-- LAYER 2 — CLEANED
-- Cast types, filter nulls and invalid sales, add audit timestamp
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE cleaned.cleaned_orders AS
SELECT
    customer_id,
    CAST(order_date   AS DATE)          AS order_date,
    order_id,
    CAST(sales        AS DECIMAL(10,2)) AS sales_amount,
    CURRENT_TIMESTAMP()                 AS processed_at
FROM cohort_db.ecom_orders
WHERE order_date   IS NOT NULL
  AND customer_id  IS NOT NULL
  AND sales        >  0;


-- -----------------------------------------------------------------------------
-- LAYER 3 — ANALYTICS
-- Build cohort_analysis: one row per customer with first & second order dates
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE analytics.cohort_analysis AS

WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM cleaned.cleaned_orders
    GROUP BY customer_id
),

second_order AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS second_order_date
    FROM cleaned.cleaned_orders o
    INNER JOIN first_order f
           ON  o.customer_id = f.customer_id
          AND  o.order_date  > f.first_order_date
    GROUP BY o.customer_id
)

SELECT
    f.customer_id,
    f.first_order_date,
    s.second_order_date,
    CASE
        WHEN s.second_order_date IS NOT NULL
        THEN DATEDIFF(s.second_order_date, f.first_order_date)
        ELSE NULL
    END AS days_until_second_order,
    CASE
        WHEN s.second_order_date IS NULL THEN 'did not return'
        ELSE 'returned'
    END AS returned
FROM  first_order  f
LEFT  JOIN second_order s ON f.customer_id = s.customer_id;


-- =============================================================================
-- EXPLORATORY QUERIES
-- =============================================================================

-- Quick dataset overview
SELECT
    COUNT(*)                    AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    MIN(order_date)             AS first_order_date,
    MAX(order_date)             AS last_order_date,
    ROUND(AVG(sales_amount), 2) AS avg_order_value
FROM cleaned.cleaned_orders;

-- First purchase date per customer (sample)
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM cleaned.cleaned_orders
    GROUP BY customer_id
)
SELECT * FROM first_order LIMIT 10;

-- Second purchase date per customer (sample)
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM cleaned.cleaned_orders
    GROUP BY customer_id
),
second_order AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS second_order_date
    FROM cleaned.cleaned_orders o
    INNER JOIN first_order f
           ON  o.customer_id = f.customer_id
          AND  o.order_date  > f.first_order_date
    GROUP BY o.customer_id
)
SELECT * FROM second_order LIMIT 10;


-- =============================================================================
-- ANALYTICS QUERIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Retention Rate by Cohort (1, 2, 3 months)
-- Uses window function MIN() OVER PARTITION BY for first purchase date
-- -----------------------------------------------------------------------------

WITH customer_orders_with_min AS (
    SELECT
        customer_id,
        order_date,
        MIN(order_date) OVER (PARTITION BY customer_id) AS first_purchase_date
    FROM cleaned.cleaned_orders
),

customer_orders AS (
    SELECT
        customer_id,
        first_purchase_date,
        MIN(CASE
                WHEN order_date > first_purchase_date THEN order_date
                ELSE NULL
            END) AS second_purchase_date
    FROM customer_orders_with_min
    GROUP BY customer_id, first_purchase_date
),

cohort_retention AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', first_purchase_date) AS cohort_month,
        first_purchase_date,
        second_purchase_date,
        -- Flag: returned within 30 days
        CASE
            WHEN second_purchase_date IS NOT NULL
             AND DATEDIFF(second_purchase_date, first_purchase_date) <= 30
            THEN 1 ELSE 0
        END AS returned_1month,
        -- Flag: returned within 60 days
        CASE
            WHEN second_purchase_date IS NOT NULL
             AND DATEDIFF(second_purchase_date, first_purchase_date) <= 60
            THEN 1 ELSE 0
        END AS returned_2month,
        -- Flag: returned within 90 days
        CASE
            WHEN second_purchase_date IS NOT NULL
             AND DATEDIFF(second_purchase_date, first_purchase_date) <= 90
            THEN 1 ELSE 0
        END AS returned_3month
    FROM customer_orders
)

SELECT
    cohort_month,
    COUNT(*)                                              AS total_customers,
    ROUND(SUM(returned_1month) * 100.0 / COUNT(*), 2)   AS retention_rate_1month,
    ROUND(SUM(returned_2month) * 100.0 / COUNT(*), 2)   AS retention_rate_2month,
    ROUND(SUM(returned_3month) * 100.0 / COUNT(*), 2)   AS retention_rate_3month
FROM  cohort_retention
GROUP BY cohort_month
ORDER BY cohort_month;


-- -----------------------------------------------------------------------------
-- 2. Repeat Purchase Rate by Cohort (2nd, 3rd, 4th order)
-- -----------------------------------------------------------------------------

WITH customer_order_counts AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date,
        COUNT(*)        AS total_orders
    FROM cleaned.cleaned_orders
    GROUP BY customer_id
),

cohort_repeated AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', first_order_date) AS cohort_month,
        total_orders,
        CASE WHEN total_orders >= 2 THEN 1 ELSE 0 END AS repeated_2nd_order,
        CASE WHEN total_orders >= 3 THEN 1 ELSE 0 END AS repeated_3rd_order,
        CASE WHEN total_orders >= 4 THEN 1 ELSE 0 END AS repeated_4th_order
    FROM customer_order_counts
)

SELECT
    cohort_month,
    COUNT(*)                                                 AS total_customers,
    ROUND(SUM(repeated_2nd_order) * 100.0 / COUNT(*), 2)   AS repeat_rate_2nd_order,
    ROUND(SUM(repeated_3rd_order) * 100.0 / COUNT(*), 2)   AS repeat_rate_3rd_order,
    ROUND(SUM(repeated_4th_order) * 100.0 / COUNT(*), 2)   AS repeat_rate_4th_order
FROM  cohort_repeated
GROUP BY cohort_month
ORDER BY cohort_month;


-- -----------------------------------------------------------------------------
-- 3. Cohort Size by Month (new customers acquired per month)
-- -----------------------------------------------------------------------------

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_purchase_date
    FROM cleaned.cleaned_orders
    GROUP BY customer_id
)

SELECT
    DATE_TRUNC('month', first_purchase_date) AS cohort_month,
    COUNT(*)                                  AS new_customers
FROM  first_purchase
GROUP BY DATE_TRUNC('month', first_purchase_date)
ORDER BY cohort_month;


-- =============================================================================
-- PIPELINE VALIDATION
-- Record count check across all 3 layers — run after each pipeline execution
-- =============================================================================

SELECT 'raw'       AS layer, COUNT(*) AS record_count FROM cohort_db.ecom_orders
UNION ALL
SELECT 'cleaned'   AS layer, COUNT(*) AS record_count FROM cleaned.cleaned_orders
UNION ALL
SELECT 'analytics' AS layer, COUNT(*) AS record_count FROM analytics.cohort_analysis;
