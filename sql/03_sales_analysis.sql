-- -------------------------------------------------------------
-- 1. Yearly Performance and YoY:
-- 範圍：2017/1 ~ 2018/8
-- 資料來源：v_orders
-- -------------------------------------------------------------
WITH yearly AS (
    -- (1) orders、GMV、AOV
    SELECT
        YEAR(order_month)   AS order_year,
        COUNT(*)            AS orders,
        SUM(gmv)            AS gmv,
        SUM(gmv) / COUNT(*) AS aov
    FROM v_orders
    WHERE order_status = 'delivered'
      AND YEAR(order_month)  IN (2017, 2018)
      AND MONTH(order_month) BETWEEN 1 AND 8
    GROUP BY YEAR(order_month)
)
-- (2) YoY（%）
SELECT
    order_year,
    orders,
    ROUND(gmv, 2) AS gmv,
    ROUND(aov, 2) AS aov,
    ROUND((orders - LAG(orders) OVER (ORDER BY order_year))
          / LAG(orders) OVER (ORDER BY order_year) * 100, 1) AS orders_yoy_pct,
    ROUND((gmv - LAG(gmv) OVER (ORDER BY order_year))
          / LAG(gmv) OVER (ORDER BY order_year) * 100, 1)    AS gmv_yoy_pct,
    ROUND((aov - LAG(aov) OVER (ORDER BY order_year))
          / LAG(aov) OVER (ORDER BY order_year) * 100, 1)    AS aov_yoy_pct
FROM yearly
ORDER BY order_year;

-- -------------------------------------------------------------
-- 2. Monthly Trends and MoM/YoY:
-- MoM：與上個月比較，反應短期變化，但受季節性影響（例如 11 月大促）
-- YoY：與去年同月比較，排除季節性，但只有 2018 年的月份有值
-- 範圍：2017/1 ~ 2018/8
-- 資料來源：v_orders
-- -------------------------------------------------------------
WITH monthly AS (
    -- (1) monthly orders, GMV, AOV
    SELECT
        order_month,
        COUNT(*)            AS orders,
        SUM(gmv)            AS gmv,
        SUM(gmv) / COUNT(*) AS aov
    FROM v_orders
    WHERE order_status = 'delivered'
      AND order_month BETWEEN '2017-01-01' AND '2018-08-01'
    GROUP BY order_month
)
-- (2) MoM/YoY（%）
SELECT
    order_month,
    orders,
    ROUND(gmv, 2) AS gmv,
    ROUND(aov, 2) AS aov,
    ROUND((gmv - LAG(gmv) OVER (ORDER BY order_month))
          / LAG(gmv) OVER (ORDER BY order_month) * 100, 1)     AS gmv_mom_pct,
    ROUND((gmv - LAG(gmv, 12) OVER (ORDER BY order_month))
          / LAG(gmv, 12) OVER (ORDER BY order_month) * 100, 1) AS gmv_yoy_pct
FROM monthly
ORDER BY order_month;

-- -------------------------------------------------------------
-- 3. Product Analysis：category GMV、order count、aov、GMV percentage and cumulative percentage
-- 範圍：2017/1 ~ 2018/8
-- 資料來源：v_order_items
-- Note：類別訂單數加總會大於總訂單數，因為跨類別訂單會在各類別各算一次；
-- -------------------------------------------------------------
WITH category_sales AS (
    -- (1) Orders and GMV by category
    SELECT
        category,
        COUNT(DISTINCT order_id) AS orders,
        SUM(price)               AS gmv
    FROM v_order_items
    WHERE order_status = 'delivered'
      AND order_month BETWEEN '2017-01-01' AND '2018-08-01'
    GROUP BY category
)
-- (2) Ranking, share, and cumulative share
SELECT
    RANK() OVER (ORDER BY gmv DESC)                     AS gmv_rank,
    category,
    orders,
    ROUND(gmv, 2)                                       AS gmv,
    ROUND(gmv / orders, 2)                              AS category_aov,
    ROUND(gmv / SUM(gmv) OVER () * 100, 2)              AS gmv_share_pct,
    ROUND(SUM(gmv) OVER (ORDER BY gmv DESC)
          / SUM(gmv) OVER () * 100, 2)                  AS cumulative_share_pct
FROM category_sales
ORDER BY gmv DESC;