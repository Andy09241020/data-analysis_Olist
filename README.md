# Olist 平台銷售數據分析

這份專案使用 Kaggle 提供的巴西電商平台 Olist 的公開銷售數據，透過結構化的拆解分析，回答：**「平台的銷售表現如何？」**這樣常見卻相對模糊的問題，並提供建議的行動方向。專案主要以 **Python** 清理原始資料、並使用**MySQL** 建立分析用 view 並進行查詢，最後用 **Tableau** 製作儀表板視覺化呈現。

**工具**：Python（pandas）・MySQL 8.4・Tableau Public

---

## Dashboard

[![Olist Sales Report](images/Sales_Overview.png)](https://public.tableau.com/app/profile/.57596212/viz/OlistSalesReport/Sales_Overview)

[查看互動版 dashboard（Tableau Public）](https://public.tableau.com/app/profile/.57596212/viz/OlistSalesReport/Sales_Overview)

---

## Key Findings

### 1. 成長來自訂單量，而非客單價

2018 年 1–8 月 GMV 較去年同期成長 **141.1%**，其中訂單數成長 **139.9%**，
客單價（AOV）僅成長 **0.5%**（R$136.08 → R$136.75）。

由於 GMV = 訂單數 × AOV，成長幾乎完全來自訂單量增加，平均每張訂單的消費金額沒有改變。

**建議**：客單價是尚未被開發的成長槓桿。可以測試組合優惠、滿額免運門檻等提升客單價的做法，並用 A/B test 驗證效果。

### 2. 2018 年成長趨緩，進入平台期

2017 年月訂單數從 750 張快速成長到 4,000 張以上；但 2018 年 1–8 月每月訂單數停留在 **6,100–7,100 張**，月 GMV 持平在 **R$0.84M–0.98M**，8 月的訂單數與 GMV 甚至比 1 月低約 **9–10%**。

GMV 年增率也從 2018 年 1 月的 **727%** 降到 8 月的 **51%**。其中一部分來自基期效應（2017 年初平台規模小），但結合 2018 年月銷售持平的趨勢，可以判斷成長動能確實在減弱。

另外，2017 年 11 月（Black Friday 檔期）GMV 較前月成長 **52%**，是資料期間的單月最高峰，12 月則回落 26%，顯示明顯的季節性。

**建議**：可進一步分析顧客回購率，評估成長重心是否應從獲取新客轉向提升既有顧客的回購。

### 3. GMV 集中於少數商品類別

分析範圍內共 73 個商品類別（不含缺類別資料的商品），第 1 名 health_beauty 即占 GMV 的 **9.3%**；
前 7 名合計 **49.9%**，前 20 名（約 27% 的類別）合計 **84.1%**。

前段類別的成長方式也不同：bed_bath_table 靠訂單量（9,267 張訂單、客單價 R$110），watches_gifts 則靠單價（5,491 張訂單、客單價 R$212）。

**建議**：優先維持頭部類別的供貨穩定與賣家合作；針對尾部類別，可重新檢視市場定位，測試更換賣家或引進新品的效果。

---

## Problem Breakdown

| 子問題 | 指標 | 對應分析 |
|---|---|---|
| 成長來自訂單量還是客單價？ | GMV、訂單數、AOV、同期 YoY | `03_sales_analysis.sql` ① |
| 成長趨勢是否持續？有沒有季節性？ | 月 GMV、MoM、YoY | `03_sales_analysis.sql` ② |
| 不同商品類別的銷售表現如何？ | 類別 GMV、占比、累積占比、類別客單價 | `03_sales_analysis.sql` ③ |

---

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)（Kaggle）

- 巴西電商平台 Olist 約 10 萬筆訂單，期間 2016-09 ~ 2018-10
- 原始資料共 9 張表，本專案只回答「銷售表現」，因此只使用以下 3 張表加上類別翻譯表；配送、評分、付款等主題不在本次範圍

| 資料表 | 筆數 | 用途 |
|---|---|---|
| `orders` | 99,441 | 訂單狀態、下單時間 |
| `order_items` | 112,650 | 每件商品的售價，用於計算 GMV |
| `products` | 32,951 | 商品類別 |
| `product_category_name_translation` | — | 將葡萄牙文類別名稱翻譯成英文 |

---

## Analysis Workflow

```
Kaggle 原始資料 → Python 清理 → MySQL 建表與 view → SQL 查詢分析 → Tableau 視覺化
```

| 步驟 | 工具 | 做了什麼 | 檔案 |
|---|---|---|---|
| 1. 資料清理 | Python（pandas） | 類別名稱翻譯成英文（補上翻譯表缺少的 2 個類別）；日期缺值經比對訂單狀態後確認為取消或未送達訂單，屬合理缺值，予以保留；610 個缺類別的商品仍有銷售，填入 `unknown` 而不刪除；日期欄位轉為 datetime | `EDA.ipynb` |
| 2. 建表與 view | MySQL | 建立 schema 並以 `LOAD DATA` 匯入；依分析需求建立兩種粒度的 view：`v_orders`（一列 = 一張訂單）與 `v_order_items`（一列 = 一件商品），避免 JOIN 後訂單被重複計算 | `sql/01_schema_load.sql`<br>`sql/02_views.sql` |
| 3. 查詢分析 | MySQL | 同期 YoY、月度 MoM／YoY、類別排名與累積占比；每段查詢附驗證查詢，確認數字一致 | `sql/03_sales_analysis.sql` |
| 4. 視覺化 | Tableau Public | 以資料來源篩選設定分析範圍；用計算欄位定義 KPI 與同期 YoY；用 `FIXED` LOD 計算類別占比 | [Tableau Public](https://public.tableau.com/app/profile/.57596212/viz/OlistSalesReport/Sales_Overview) |

---

## 指標定義與分析範圍

**指標定義**

| 指標 | 定義 |
|---|---|
| GMV | 商品售價（`price`）加總，**不含運費**。注意 GMV 不等於平台營收 |
| 訂單數 | 不重複的 `order_id` 數 |
| AOV（客單價） | GMV ÷ 訂單數 |
| 類別客單價 | 類別 GMV ÷ 含該類別商品的訂單數 |
| 同期 YoY | 2018 年 1–8 月 vs 2017 年 1–8 月（2018 年資料只到 8 月，因此只比較相同月份） |

**分析範圍**

| 條件 | 理由 |
|---|---|
| 只計 `order_status = 'delivered'` | 只衡量實際成交的銷售。已取消、缺貨的訂單沒有成交；運送中、處理中的訂單結果未定。delivered 占全部訂單 97.0% |
| 期間 2017-01 ~ 2018-08 | 2016 年只有零星訂單，且 2016-11 整月無資料；2018-09 之後每月僅十餘筆、且無已送達訂單，為資料截止。保留連續 20 個完整月份 |
| 月份依下單時間歸屬 | 以 `order_purchase_timestamp` 判斷訂單屬於哪個月 |

範圍內共 **96,211 張訂單**、GMV **R$13,181,027.13**。

---

## Limitations

- **GMV 不等於營收**：GMV未扣除退款，也不含運費，且平台實際營收為收取之佣金，這份專案專注在「銷售表現」因此選擇只計算GMV
- **Orders只計算已送達訂單**：資料截止前仍在運送中的訂單未計入，最後幾個月的數字可能略為低估
- **缺類別的商品**：610 個商品缺類別資料（以 `unknown` 表示，占 GMV 1.3%），不列入類別排名，但計入總 GMV
- **期間較短**：只有 20 個月資料，YoY 僅能計算 2018 年 1–8 月，波動僅能作為短期決策參考

---

## Project Structure Overview

```
project_2/
├── EDA.ipynb                 
├── sql/
│   ├── 01_schema_load.sql    
│   ├── 02_views.sql          
│   └── 03_sales_analysis.sql 
├── images/
│   └── Sales_Overview.png    
├── requirements.txt
└── README.md
```

`raw_data/`、`processed_data/` 因檔案較大，未上傳至 GitHub。

---

