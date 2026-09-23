CREATE OR REPLACE VIEW customer_retention_summary AS
WITH first_order AS (
    SELECT *
    FROM fact_orders
    WHERE order_sequence = 1
),
second_order AS (
    SELECT customer_unique_id, order_purchase_timestamp AS second_order_date
    FROM fact_orders
    WHERE order_sequence = 2
),
totals AS (
    SELECT customer_unique_id, COUNT(*) AS total_orders
    FROM fact_orders
    GROUP BY customer_unique_id
)
SELECT
    fo.customer_unique_id,
    fo.customer_state,
    t.total_orders,
    t.total_orders > 1 AS is_repeat_customer,
    fo.order_purchase_timestamp AS first_order_date,
    EXTRACT(EPOCH FROM (so.second_order_date - fo.order_purchase_timestamp)) / 86400.0 AS days_to_second_order,
    fo.delivery_days AS first_order_delivery_days,
    fo.on_time_flag AS first_order_on_time_flag,
    fo.review_score AS first_order_review_score,
    fo.product_category_english AS first_order_category,
    fo.order_value AS first_order_value,
    fo.payment_type AS first_order_payment_type,
    fo.payment_installments AS first_order_payment_installments
FROM first_order fo
JOIN totals t ON t.customer_unique_id = fo.customer_unique_id
LEFT JOIN second_order so ON so.customer_unique_id = fo.customer_unique_id;
