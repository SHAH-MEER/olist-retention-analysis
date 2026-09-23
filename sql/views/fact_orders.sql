CREATE OR REPLACE VIEW fact_orders AS
WITH order_value AS (
    SELECT order_id, SUM(price + freight_value) AS order_value
    FROM order_items
    GROUP BY order_id
),
order_review AS (
    SELECT DISTINCT ON (order_id) order_id, review_score
    FROM order_reviews
    ORDER BY order_id, review_creation_date DESC, review_id DESC
),
order_payment AS (
    SELECT order_id, payment_type, payment_installments
    FROM order_payments
    WHERE payment_sequential = 1
),
order_category AS (
    SELECT DISTINCT ON (oi.order_id)
        oi.order_id,
        pt.product_category_name_english
    FROM order_items oi
    JOIN products pr ON pr.product_id = oi.product_id
    LEFT JOIN product_category_translation pt
        ON pt.product_category_name = pr.product_category_name
    ORDER BY oi.order_id, oi.order_item_id
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    ROW_NUMBER() OVER (
        PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp, o.order_id
    ) AS order_sequence,
    ROW_NUMBER() OVER (
        PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp, o.order_id
    ) > 1 AS is_repeat_order,
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0 AS delivery_days,
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0 AS delivery_vs_estimate_days,
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        ELSE o.order_delivered_customer_date <= o.order_estimated_delivery_date
    END AS on_time_flag,
    orv.review_score,
    opay.payment_type,
    opay.payment_installments,
    ocat.product_category_name_english AS product_category_english,
    ov.order_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_value ov ON ov.order_id = o.order_id
LEFT JOIN order_review orv ON orv.order_id = o.order_id
LEFT JOIN order_payment opay ON opay.order_id = o.order_id
LEFT JOIN order_category ocat ON ocat.order_id = o.order_id;
