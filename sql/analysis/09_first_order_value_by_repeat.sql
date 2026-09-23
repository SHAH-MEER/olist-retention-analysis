SELECT
    width_bucket(first_order_value, 0, 500, 20) AS value_bucket,
    is_repeat_customer,
    COUNT(*) AS customers
FROM customer_retention_summary
WHERE first_order_value IS NOT NULL AND first_order_value < 500
GROUP BY value_bucket, is_repeat_customer
ORDER BY value_bucket;
