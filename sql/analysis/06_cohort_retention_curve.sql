WITH cohorts AS (
    SELECT
        customer_unique_id,
        DATE_TRUNC('month', first_order_date)::date AS cohort_month,
        is_repeat_customer,
        FLOOR(days_to_second_order / 30.0) AS months_to_repeat
    FROM customer_retention_summary
)
SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct,
    ROUND(AVG(months_to_repeat) FILTER (WHERE is_repeat_customer), 1) AS avg_months_to_repeat
FROM cohorts
GROUP BY cohort_month
ORDER BY cohort_month;
