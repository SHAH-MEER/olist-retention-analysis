SELECT
    CASE
        WHEN first_order_payment_installments = 1 THEN '1 (upfront)'
        WHEN first_order_payment_installments BETWEEN 2 AND 4 THEN '2-4'
        WHEN first_order_payment_installments BETWEEN 5 AND 10 THEN '5-10'
        WHEN first_order_payment_installments > 10 THEN '10+'
        ELSE 'unknown'
    END AS installment_bucket,
    COUNT(*) AS customers,
    SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_retention_summary
GROUP BY 1
ORDER BY MIN(COALESCE(first_order_payment_installments, 0));
