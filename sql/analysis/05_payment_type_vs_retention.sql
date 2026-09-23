SELECT
    first_order_payment_type,
    COUNT(*) AS customers,
    SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_retention_summary
WHERE first_order_payment_type IS NOT NULL
GROUP BY first_order_payment_type
ORDER BY repeat_rate_pct DESC;
