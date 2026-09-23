SELECT
    customer_state,
    COUNT(*) AS customers,
    SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_retention_summary
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY repeat_rate_pct DESC;
