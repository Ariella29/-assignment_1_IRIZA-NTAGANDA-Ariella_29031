# PL/SQL Assignment One

**Student Name:** IRIZA Ntaganda Ariella  
**Student ID:** 29031  
**Course:** Database Management Systems & PL/SQL  
**Database Used:** PostgreSQL 18  

---

##  Business Scenario
Sunrise Supermarket is a retail store operating in Rwanda (Kigali, Huye, Musanze, Rubavu, Gitarama). The supermarket sells products across multiple categories including *Fresh Produce*, *Dairy & Eggs*, *Bakery*, and *Beverages*. Management requires database analytics to track customer demographics, order items, revenue growth over time, customer purchasing frequency, and high-value VIP spenders.

---

### Database Creation
```sql
CREATE DATABASE assignment1_db;
```

<img width="440" height="241" alt="WhatsApp Image 2026-09-20 at 00 07 42" src="https://github.com/user-attachments/assets/f0133a51-0c86-49d8-9d79-8b40a7285a16" />

---

### Table Creation
```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL
);
```

<img width="546" height="183" alt="WhatsApp Image 2026-09-20 at 00 12 12" src="https://github.com/user-attachments/assets/1cf69f25-a0b2-4c50-9a2a-8328befb9bdb" />


---

###  JOIN Queries

#### INNER JOIN (Orders + Customers)
* **Explanation:** Joins `orders` with `customers` using `INNER JOIN` to map each order to the customer who placed it and their location.

```sql
SELECT 
    o.order_id,
    c.customer_name,
    c.city,
    o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_id;
```

<img width="1248" height="830" alt="WhatsApp Image 2026-09-20 at 00 24 50" src="https://github.com/user-attachments/assets/b55f8178-b06b-4834-bfb4-5148ddf06693" />


---

#### Query 1.2: JOIN (Order Items + Products)
* **Explanation:** Joins `order_items` with `products` to show detailed item purchases, product categories, unit prices, and calculated item total cost.

```sql
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
```

<img width="1273" height="863" alt="WhatsApp Image 2026-09-20 at 00 24 50 (1)" src="https://github.com/user-attachments/assets/58384691-9a8a-407c-9d94-7939628f8d2c" />


---

#### LEFT JOIN (Customers + Orders)
* **Explanation:** Uses `LEFT JOIN` from `customers` to `orders` to retrieve all registered customers, including inactive accounts with no order history.

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    o.order_id,
    o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;
```
<img width="1232" height="831" alt="WhatsApp Image 2026-09-20 at 00 24 50 (2)" src="https://github.com/user-attachments/assets/7672c858-172b-41c1-87da-ba05ca6dec93" />


---


#### Total Spend Per Customer & Customers Above Average Spend
* **Explanation:** Uses a (`CustomerSpend`) to aggregate total spending per customer, then filters for customers spending more than the overall customer average.

```sql
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
```
<img width="1247" height="822" alt="WhatsApp Image 2026-09-20 at 00 24 50 (3)" src="https://github.com/user-attachments/assets/cf70ad63-2780-4e0e-a9f2-e116529c69cc" />


---


#### RANK (Rank Customers by Total Spend)
* **Explanation:** Ranks customers from highest to lowest spender using the `RANK()` window function over total calculated spend.

```sql
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
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM CustomerTotalSpend
ORDER BY spend_rank;
```
<img width="1272" height="847" alt="WhatsApp Image 2026-09-20 at 00 24 50 (4)" src="https://github.com/user-attachments/assets/8aa2b2c8-964e-423d-a11f-afd7168cc3f0" />


---

#### ROW_NUMBER (Number Each Customer's Orders in Sequence)
* **Explanation:** Uses `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date)` to assign sequence numbers (1, 2, 3...) to orders per customer.

```sql
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
```
<img width="1260" height="835" alt="WhatsApp Image 2026-09-20 at 00 24 50 (5)" src="https://github.com/user-attachments/assets/55c1624d-5db6-4765-9395-f5e84e10091c" />


---

#### SUM and OVER (Running Total of Revenue Over Time)
* **Explanation:** Uses `SUM() OVER (ORDER BY order_date)` to compute cumulative store revenue over time.

```sql
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
```
<img width="1264" height="855" alt="WhatsApp Image 2026-09-20 at 00 24 50 (6)" src="https://github.com/user-attachments/assets/69c49323-f8b3-4d8a-814f-e2b00e7a9e23" />


---

#### LAG (Days Between Current and Previous Order for Repeat Customers)
* **Explanation:** Uses `LAG(order_date)` partitioned by customer to calculate days elapsed between consecutive orders (`order_date - previous_order_date`).

```sql
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
```
<img width="1269" height="848" alt="WhatsApp Image 2026-09-20 at 00 24 50 (7)" src="https://github.com/user-attachments/assets/ce61e48d-6762-4b99-aa8e-980e2aab71ef" />

---

   ##                                                  THANK YOU !
