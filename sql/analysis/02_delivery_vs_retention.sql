SELECT
    CASE
        WHEN first_order_on_time_flag IS NULL THEN 'no delivery record'
        WHEN first_order_on_time_flag THEN 'on time'
        ELSE 'late'
    END AS delivery_status,
    COUNT(*) AS customers,
    SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_retention_summary
GROUP BY 1
ORDER BY repeat_rate_pct DESC;
