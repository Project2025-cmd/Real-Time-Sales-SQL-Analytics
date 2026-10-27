-- =============================================================
-- STEP 1: DATABASE SELECTION & INITIALIZATION
-- =============================================================

-- Database ko active karein (Kyunki database pehle se bana hua hai)
USE revenue_analytics_db;

-- Agar pehle se koi tables adhoore bane hain toh unhe clear karein
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- =============================================================
-- STEP 2: CREATING TABLES (MYSQL COMPLIANT)
-- =============================================================

-- 1. Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. Products Table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 3. Orders Table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- 4. Order Items Table (Transactional Fact Table)
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Real-Time Performance ko fast karne ke liye standard MySQL indexes
CREATE INDEX idx_orders_date ON orders(order_date DESC);
CREATE INDEX idx_orders_cust_date ON orders(customer_id, order_date);

-- =============================================================
-- STEP 3: EXECUTIVE REVENUE DASHBOARD QUERY
-- (Run this AFTER importing your CSV data into the tables)
-- =============================================================

WITH DailyRevenueMetrics AS (
    -- Har din ka aggregate calculation
    SELECT 
        DATE(o.order_date) AS processing_day,
        COUNT(DISTINCT o.order_id) AS total_successful_orders,
        COUNT(oi.order_item_id) AS total_items_sold,
        SUM(oi.quantity * oi.unit_price) AS raw_gross_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE(o.order_date)
),
AdvancedTimeWindows AS (
    -- Running Totals aur Trailing Trends Window Functions ke sath
    SELECT 
        processing_day,
        total_successful_orders,
        total_items_sold,
        raw_gross_revenue,
        
        -- Cumulative Total Sales
        SUM(raw_gross_revenue) OVER (
            ORDER BY processing_day 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue_to_date,
        
        -- 7-Day Trailing Moving Average
        AVG(raw_gross_revenue) OVER (
            ORDER BY processing_day 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS trailing_7day_avg_revenue,
        
        -- Previous Day Revenue tracking
        LAG(raw_gross_revenue, 1) OVER (ORDER BY processing_day) AS prior_day_gross_revenue
    FROM DailyRevenueMetrics
)
-- Final Select Statement safely formatting data fields
SELECT 
    processing_day AS reporting_date,
    total_successful_orders,
    total_items_sold,
    ROUND(raw_gross_revenue, 2) AS gross_revenue,
    ROUND(cumulative_revenue_to_date, 2) AS cumulative_revenue,
    ROUND(trailing_7day_avg_revenue, 2) AS moving_avg_7_days,
    ROUND(COALESCE(prior_day_gross_revenue, 0), 2) AS prior_day_revenue,
    
    -- Absolute growth margin change
    ROUND(raw_gross_revenue - COALESCE(prior_day_gross_revenue, raw_gross_revenue), 2) AS absolute_net_change,
    
    -- Percentage Growth Velocity (Handling Zero error)
    ROUND(
        ( (raw_gross_revenue - COALESCE(prior_day_gross_revenue, raw_gross_revenue)) / 
          NULLIF(prior_day_gross_revenue, 0)
        ) * 100, 2
    ) AS daily_growth_percentage
FROM AdvancedTimeWindows
ORDER BY processing_day DESC;
SELECT 
    HOUR(o.order_date) AS order_hour,
    COUNT(DISTINCT o.order_id) AS total_orders_placed,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS hourly_gross_revenue,
    -- Average order value during that hour
    ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS hourly_aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY HOUR(o.order_date)
ORDER BY hourly_gross_revenue DESC;
SELECT 
    p1.name AS product_a,
    p2.name AS product_b,
    COUNT(*) AS times_purchased_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.name, p2.name
ORDER BY times_purchased_together DESC
LIMIT 10;
SELECT 
    c.customer_id,
    c.name AS customer_name,
    MAX(o.order_date) AS last_purchase_date,
    DATEDIFF(CURRENT_TIMESTAMP, MAX(o.order_date)) AS days_since_last_order,
    COUNT(DISTINCT o.order_id) AS historical_order_count,
    CASE 
        WHEN DATEDIFF(CURRENT_TIMESTAMP, MAX(o.order_date)) > 45 THEN 'Critical Churn Risk'
        WHEN DATEDIFF(CURRENT_TIMESTAMP, MAX(o.order_date)) BETWEEN 30 AND 45 THEN 'Medium Warning'
        ELSE 'Active & Retained'
    END AS retention_health_status
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name
ORDER BY days_since_last_order DESC;



