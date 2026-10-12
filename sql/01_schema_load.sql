-- 01_schema_load.sql
-- Create database and tables, then load cleaned CSVs from processed_data/

CREATE DATABASE IF NOT EXISTS olist
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE olist;

-- Drop tables in reverse dependency order so the script can be re-run
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

-- customers: one row per customer_id (one customer_id per order)
CREATE TABLE customers (
    customer_id              CHAR(32)     NOT NULL,
    customer_unique_id       CHAR(32)     NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           CHAR(2),
    PRIMARY KEY (customer_id)
);

-- orders: one row per order
CREATE TABLE orders (
    order_id                      CHAR(32)    NOT NULL,
    customer_id                   CHAR(32)    NOT NULL,
    order_status                  VARCHAR(20) NOT NULL,
    order_purchase_timestamp      DATETIME    NOT NULL,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATE        NOT NULL,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

-- products: one row per product
CREATE TABLE products (
    product_id                    CHAR(32)     NOT NULL,
    product_category_name         VARCHAR(60),
    product_name_length           DECIMAL(10,1),
    product_description_length    DECIMAL(10,1),
    product_photos_qty            DECIMAL(10,1),
    product_weight_g              DECIMAL(10,1),
    product_length_cm             DECIMAL(10,1),
    product_height_cm             DECIMAL(10,1),
    product_width_cm              DECIMAL(10,1),
    product_category_name_english VARCHAR(60)  NOT NULL,
    PRIMARY KEY (product_id)
);

-- order_items: one row per item within an order
CREATE TABLE order_items (
    order_id            CHAR(32)      NOT NULL,
    order_item_id       INT           NOT NULL,
    product_id          CHAR(32)      NOT NULL,
    seller_id           CHAR(32)      NOT NULL,
    shipping_limit_date DATETIME      NOT NULL,
    price               DECIMAL(10,2) NOT NULL,
    freight_value       DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders (order_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- order_reviews: one row per review (an order may have more than one review)
CREATE TABLE order_reviews (
    review_id               CHAR(32) NOT NULL,
    order_id                CHAR(32) NOT NULL,
    review_score            TINYINT  NOT NULL,
    review_creation_date    DATETIME NOT NULL,
    review_answer_timestamp DATETIME NOT NULL,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

-- Load cleaned CSVs (run from the project root so the relative paths work)
LOAD DATA LOCAL INFILE 'processed_data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'processed_data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'processed_data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'processed_data/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'processed_data/order_reviews.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Check row counts against the CSV exports
-- Expected: customers 99441, orders 99441, products 32951, order_items 112650, order_reviews 99224
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders',        COUNT(*) FROM orders
UNION ALL
SELECT 'products',      COUNT(*) FROM products
UNION ALL
SELECT 'order_items',   COUNT(*) FROM order_items
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews;