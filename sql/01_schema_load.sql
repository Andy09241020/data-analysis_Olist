-- =============================================================
-- 01_schema_load.sql
-- 目的：建立資料庫與 3 張資料表，載入 processed_data/ 的清理後資料
-- 範圍：2016/9 ~ 2018/10
-- =============================================================

CREATE DATABASE IF NOT EXISTS olist
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE olist;

-- 依相依順序反向刪除，讓這支程式可以重複執行
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;


-- -------------------------------------------------------------
-- 1. 建立資料表
-- -------------------------------------------------------------

-- orders：一列 = 一張訂單
CREATE TABLE orders (
    order_id                      CHAR(32)    NOT NULL,
    customer_id                   CHAR(32)    NOT NULL,
    order_status                  VARCHAR(20) NOT NULL,
    order_purchase_timestamp      DATETIME    NOT NULL,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATE        NOT NULL,
    PRIMARY KEY (order_id)
);

-- products：一列 = 一個商品
CREATE TABLE products (
    product_id                    CHAR(32)      NOT NULL,
    product_category_name         VARCHAR(60),
    product_name_length           DECIMAL(10,1),
    product_description_length    DECIMAL(10,1),
    product_photos_qty            DECIMAL(10,1),
    product_weight_g              DECIMAL(10,1),
    product_length_cm             DECIMAL(10,1),
    product_height_cm             DECIMAL(10,1),
    product_width_cm              DECIMAL(10,1),
    product_category_name_english VARCHAR(60)   NOT NULL,
    PRIMARY KEY (product_id)
);

-- order_items：一列 = 訂單中的一件商品（一張訂單可能有多列）
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


-- -------------------------------------------------------------
-- 2. 載入資料（先載 orders、products，order_items 參照它們所以最後載）
-- -------------------------------------------------------------

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


-- -------------------------------------------------------------
-- 3. 載入檢查
-- -------------------------------------------------------------

-- 3-1 筆數要和 CSV 一致
-- 預期：orders 99441、products 32951、order_items 112650
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'products',             COUNT(*)              FROM products
UNION ALL
SELECT 'order_items',          COUNT(*)              FROM order_items;

-- 3-2 缺值要以 NULL 載入，而不是空字串或 0
-- 預期：未送達日期 2965、缺類別 610
SELECT
    (SELECT COUNT(*) FROM orders   WHERE order_delivered_customer_date IS NULL) AS null_delivered_date,
    (SELECT COUNT(*) FROM products WHERE product_category_name IS NULL)         AS null_category;