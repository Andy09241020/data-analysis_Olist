-- =============================================================
-- 02_views.sql
-- 目的：建立分析用的 view，統一 KPI 的計算方式，依照分析問題的對象及計算方便分別製作兩張view：
--   v_orders      一列 = 一張訂單 → for {GMV、訂單數、AOV、月趨勢}
--   v_order_items 一列 = 一件商品 → for {類別 GMV、類別訂單數、占比}
-- =============================================================

USE olist;

-- -------------------------------------------------------------
-- 1. v_orders：一列 = 一張訂單
-- order_items 一張訂單可能有多列，先依 order_id 彙整再 join，
-- 避免訂單數被重複計算
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_orders AS
WITH items_agg AS (
    SELECT
        order_id,
        COUNT(*)           AS item_count,
        SUM(price)         AS gmv,            -- GMV 只算商品價格，不含運費
        SUM(freight_value) AS freight_value
    FROM order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    CAST(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS DATE) AS order_month,
    COALESCE(i.item_count, 0)    AS item_count,
    COALESCE(i.gmv, 0)           AS gmv,
    COALESCE(i.freight_value, 0) AS freight_value
FROM orders o
LEFT JOIN items_agg i ON i.order_id = o.order_id;

-- -------------------------------------------------------------
-- 驗證 1：一列 = 一張訂單
-- 預期：兩個數字都是 99441（等於 orders 的筆數）
SELECT COUNT(*)                 AS view_rows,
       COUNT(DISTINCT order_id) AS distinct_orders
FROM v_orders;

-- 驗證 2：GMV 沒有被重複計算或遺漏
-- 預期：兩個數字一樣，都是 13591643.70
SELECT (SELECT SUM(gmv)   FROM v_orders)    AS view_gmv,
       (SELECT SUM(price) FROM order_items) AS items_gmv;
-- -------------------------------------------------------------
-- 2. v_order_items：一列 = 一件商品
-- 一張訂單可能包含不同類別的商品，類別分析必須在商品層級計算
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    p.product_category_name_english AS category,
    oi.price,
    oi.freight_value,
    o.order_status,
    o.order_purchase_timestamp,
    CAST(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS DATE) AS order_month
FROM order_items oi
JOIN orders   o ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id;

-- -------------------------------------------------------------
-- 驗證 1：一列 = 一件商品，JOIN 沒有讓列數變多或變少
-- 預期：兩個數字都是 112650
SELECT (SELECT COUNT(*) FROM v_order_items) AS view_rows,
       (SELECT COUNT(*) FROM order_items)   AS items_rows;

-- 驗證 2：兩張 view 的 GMV 要一致，代表 KPI 定義統一
-- 預期：兩個數字都是 13591643.70
SELECT (SELECT SUM(price) FROM v_order_items) AS item_view_gmv,
       (SELECT SUM(gmv)   FROM v_orders)      AS order_view_gmv;