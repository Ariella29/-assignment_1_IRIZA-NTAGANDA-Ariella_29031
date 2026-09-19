SELECT 
    o.order_id,
    c.customer_name,
    c.city,
    o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_id;

SELECT 
    oi.order_item_id,
    oi.order_id,
    p.product_name,
    p.category,
    p.price,
    oi.quantity,
    (oi.quantity * p.price) AS total_item_cost
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY oi.order_item_id;

SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    o.order_id,
    o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

WITH CustomerSpend AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        COALESCE(SUM(oi.quantity * p.price), 0) AS total_spend
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name, c.city
)
SELECT 
    customer_id,
    customer_name,
    city,
    total_spend
FROM CustomerSpend
WHERE total_spend > (SELECT AVG(total_spend) FROM CustomerSpend)
ORDER BY total_spend DESC;

WITH CustomerTotalSpend AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        COALESCE(SUM(oi.quantity * p.price), 0) AS total_spend
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name, c.city
)
SELECT 
    customer_id,
    customer_name,
    city,
    total_spend,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
    DENSE_RANK() OVER (ORDER BY total_spend DESC) AS dense_spend_rank
FROM CustomerTotalSpend
ORDER BY spend_rank;

SELECT 
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    ROW_NUMBER() OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date ASC, o.order_id ASC
    ) AS order_sequence_number
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, order_sequence_number;

WITH DailyOrderRevenue AS (
    SELECT 
        o.order_id,
        o.order_date,
        c.customer_name,
        SUM(oi.quantity * p.price) AS order_revenue
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.order_id, o.order_date, c.customer_name
)
SELECT 
    order_id,
    order_date,
    customer_name,
    order_revenue,
    SUM(order_revenue) OVER (
        ORDER BY order_date ASC, order_id ASC
    ) AS running_total_revenue
FROM DailyOrderRevenue
ORDER BY order_date ASC, order_id ASC;

WITH OrderedCustomerOrders AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.order_id,
        o.order_date,
        LAG(o.order_date) OVER (
            PARTITION BY c.customer_id 
            ORDER BY o.order_date ASC, o.order_id ASC
        ) AS previous_order_date,
        COUNT(*) OVER (
            PARTITION BY c.customer_id
        ) AS total_customer_orders
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
)
SELECT 
    customer_id,
    customer_name,
    order_id,
    order_date AS current_order_date,
    previous_order_date,
    (order_date - previous_order_date) AS days_since_previous_order
FROM OrderedCustomerOrders
WHERE total_customer_orders > 1
ORDER BY customer_id, current_order_date;
