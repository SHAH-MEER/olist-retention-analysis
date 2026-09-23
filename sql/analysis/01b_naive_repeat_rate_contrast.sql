SELECT
    COUNT(DISTINCT customer_id) AS total_customer_ids,
    COUNT(*) AS total_orders,
    ROUND(100.0 * (COUNT(*) - COUNT(DISTINCT customer_id)) / COUNT(*), 2) AS naive_repeat_rate_pct
FROM orders;
