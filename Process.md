# Marketplace Sales & Operations Performance Analysis

## 1. 專案目標

這是一份面向 Data Analyst / Business Analyst Intern 的第一份數據分析作品集。

專案使用 Olist 巴西電商公開資料，展示以下能力：

- SQL 查詢與資料彙整
- Python / pandas 資料清理與驗證
- Tableau 儀表板與視覺化
- 電商營運 KPI 設計
- 從資料提出假設、驗證結果並提出商業建議

專案不追求複雜模型或過度花俏的 insight，重點是清楚展示資料分析基本功、正確資料粒度、可重複執行的流程，以及將結果連結到營運問題。

建議專案名稱：

> Marketplace Sales & Operations Performance Analysis

建議中文名稱：

> 電商平台銷售與營運績效分析

---

## 2. 目前資料夾狀態

目前專案資料夾包含：

```text
raw_data/
├── olist_customers_dataset.csv
├── olist_geolocation_dataset.csv
├── olist_order_items_dataset.csv
├── olist_order_payments_dataset.csv
├── olist_order_reviews_dataset.csv
├── olist_orders_dataset.csv
├── olist_products_dataset.csv
├── olist_sellers_dataset.csv
└── product_category_name_translation.csv

processed_data/
├── customers.csv
├── order_items.csv
├── order_reviews.csv
├── orders.csv
└── products.csv

EDA.ipynb
sql/
└── 01_schema_load.sql

requirements.txt
```

目前已完成的 Python 工作：

- 讀取 9 張原始資料表
- 將葡萄牙文商品類別轉成英文
- 手動補上翻譯表中缺少的 2 個商品類別
- 檢查各資料表的 row count、欄位數、重複資料與缺失值
- 檢查 `orders` 缺失日期與訂單狀態的關係
- 保留合理缺失值，不進行不合理的補值
- 將時間欄位轉換為 datetime
- 將清理後的主要資料輸出至 `processed_data/`

目前尚未完成：

- SQL 分析查詢檔案；目前只有 core schema load script
- Tableau dashboard
- SQL view 與 analysis query
- README、資料字典與分析結論

目前已建立的 SQL schema 包含：

- `customers`
- `orders`
- `products`
- `order_items`
- `order_reviews`

本專案決定只使用目前 5 張核心資料表。`payments`、`sellers` 與 ZIP code 不列入本次作品集的分析範圍；README 只需說明 ZIP code 未保留前導零是資料限制。

---

## 3. 資料規模與初步檢查結果

| Table | Rows | 用途 |
|---|---:|---|
| orders | 99,441 | 訂單狀態與訂單時間 |
| order_items | 112,650 | 商品銷售、價格、運費 |
| products | 32,951 | 商品與商品類別 |
| customers | 99,441 | 客戶、地區與 customer identity |
| order_reviews | 99,224 | 顧客評分 |

資料期間：2016/09–2018/10。

注意：2016/09、2016/12、2018/09、2018/10 的訂單量很少，月度趨勢分析建議預設使用 2017/01–2018/08，或在 dashboard 中標示為 partial months。

初步計算結果：

- Delivered orders：96,478 筆
- Delivered GMV（商品價格，不含運費）：約 13.22M
- Delivered orders 準時率：約 91.9%
- 準時訂單平均 review score：約 4.29
- 延遲訂單平均 review score：約 2.27
- `canceled` + `unavailable` 訂單比例：約 1.24%
- 重複購買客戶比例：約 3.1%

延遲定義為：`order_status = 'delivered'` 且 `order_delivered_customer_date > order_estimated_delivery_date`。無法計算日期差異的 delivered orders 不納入準時/延遲比較。

以上結果只代表探索性分析。配送延遲與低評分之間的關聯不應直接解讀為因果關係。

---

## 4. 商業分析主題

### 主要分析問題

1. 哪些月份、商品類別與州別帶來主要銷售？
2. 訂單狀態與配送效率如何影響平台營運表現？
3. 配送延遲是否與較低的顧客評分有關？
4. 哪些州別或地區需要優先改善？
5. 平台是否有重複購買與客戶留存的成長機會？

### 建議假設

> 配送延遲的訂單，其顧客評價低於準時送達的訂單。

驗證方式：

- 只分析 `delivered` orders
- 將實際送達日與預計送達日比較
- 定義 `actual_delivery_date > estimated_delivery_date` 為 late
- 將多筆 review 先按照 `order_id` 聚合
- 比較 on-time 與 late orders 的平均評分、低評分比例與訂單分布

---

## 5. 建議資料模型與資料處理原則

### 建議建立 order-level SQL view

不要另外建立 `order_level_fact.csv` 或 `src/prepare_data.py`。衍生欄位與 order-level 聚合統一在 `sql/02_order_view.sql` 中完成。

一筆 view 資料代表一張訂單，至少包含：

- `order_id`
- `customer_id`
- `customer_unique_id`
- `customer_state`
- `order_status`
- `order_purchase_timestamp`
- `order_delivered_customer_date`
- `order_estimated_delivery_date`
- `gmv`
- `freight_value`
- `item_count`
- `review_score`
- `order_month`
- `delivery_days`
- `delay_days`
- `is_late`

### 重要資料粒度規則

- `orders`：一筆資料代表一張訂單
- `order_items`：一筆資料代表訂單中的一個商品項目
- `products`：一筆資料代表一個商品
- `customers`：一筆資料代表一個 customer/order relationship
- `customer_unique_id`：用於判斷同一顧客是否重複購買
- `order_reviews`：可能一張訂單有多筆 review，不能直接當作一筆訂單使用

計算訂單數與 GMV 時，必須先將 `order_items` 按照 `order_id` 聚合，再與 `orders` join，避免重複計算。多筆 review 也必須先按照 `order_id` 聚合。

### 資料清理注意事項

- `orders` 的缺失日期需要依照 `order_status` 判斷，不能全部填補
- `products` 中缺失商品類別的 610 筆資料可填成 `unknown`
- `order_reviews.review_id` 有重複情況，需依 `order_id` 聚合
- `requirements.txt` 已包含 notebook 使用的 `seaborn`
- `customer_zip_code_prefix` 的前導零未保留，但本專案只分析州別，因此列為 README 的資料限制

### Schema 注意事項

- `order_reviews` 使用 `(review_id, order_id)` 複合主鍵，因為來源資料存在重複 `review_id`
- 目前 schema 的五張表與現有 processed CSV 的 row count、主鍵及目前 foreign key 關係一致
- SQL 建表時已將 `product_name_lenght`、`product_description_lenght` 對應為 `product_name_length`、`product_description_length`，不需要修改原始 processed CSV 欄位名稱
- 本專案使用 MySQL，並在 Windows 個人電腦上執行
- schema 使用 `LOAD DATA LOCAL INFILE`，執行時需要從 project root 執行，並確認 MySQL client/server 已開啟 local infile
- 目前環境沒有 MySQL/MariaDB client，因此 `01_schema_load.sql` 尚未完成實際資料庫執行驗證

---

## 6. SQL 工作內容

建議建立以下檔案：

```text
sql/
├── 01_schema_load.sql
├── 02_order_view.sql
└── 03_analysis.sql
```

### 必須展示的 SQL 技術

- `INNER JOIN`、`LEFT JOIN`
- `GROUP BY`
- `CASE WHEN`
- CTE
- window functions
- 日期處理
- `COUNT(DISTINCT ...)`
- 缺失值與 orphan records 檢查

### 建議 SQL 查詢

1. 在 `02_order_view.sql` 建立 order-level view 與衍生欄位
2. 在 `03_analysis.sql` 完成月度 KPI、商品類別、州別、訂單狀態、配送/評分與重複購買分析
3. 在 `03_analysis.sql` 補上主鍵、外鍵、缺失日期與重複資料檢查

本專案固定使用 MySQL，並在 Windows 個人電腦上執行。所有日期函數、CTE、window functions 與 `LOAD DATA LOCAL INFILE` 都以 MySQL 語法撰寫，不需要另外維護 DuckDB 或 PostgreSQL 版本。

---

## 7. Python 工作內容

將目前的 `EDA.ipynb` 整理成較清楚的分析流程，建議區分為：

1. Data loading
2. Data cleaning
3. Data validation
4. Exploratory analysis
5. Export cleaned tables

衍生欄位不在 Python 中另行輸出，統一由 `sql/02_order_view.sql` 建立，包括：

- `order_month`
- `delivery_days`
- `delay_days`
- `is_late`
- `is_repeat_customer`
- `item_count`
- `gmv`
- `aov`
- `review_score_group`

驗證至少包含：

- row count 是否因 join 不合理增加
- primary key 是否重複
- foreign key 是否存在 orphan records
- 日期邏輯是否合理
- delivered orders 是否有缺少送達日期
- category translation 是否完整

Notebook 保留用於說明清理、驗證與探索性分析；order-level view 與所有衍生欄位由 MySQL SQL 處理。

---

## 8. Tableau Dashboard 規劃

先製作一頁 dashboard，集中展示核心銷售與配送/顧客體驗 KPI。

### Dashboard：Marketplace Performance Overview

KPI cards：

- GMV
- Orders
- AOV
- On-time delivery rate
- Average review score

圖表：

- 月度 GMV 與訂單數趨勢
- 商品類別 GMV 排名
- 州別 GMV 或訂單數排名
- 訂單狀態分布
- on-time vs late orders
- 實際配送天數分布
- 州別 late rate
- on-time vs late 的平均 review score
- 高 GMV、高延遲率的重點州別或地區

Filters：

- Order month
- Customer state
- Product category
- Order status

Dashboard 中的 KPI 定義必須與 SQL、Python 的計算方式一致。

若沒有 Tableau Server，不要宣稱已經完成自動化部署。README 說明 MySQL view 與 Tableau datasource 的更新方式即可。

---

## 9. 作品集交付內容

建議最後整理成：

```text
project_2/
├── raw_data/
├── processed_data/
├── sql/
│   ├── 01_schema_load.sql
│   ├── 02_order_view.sql
│   └── 03_analysis.sql
├── tableau/
│   ├── dashboard_screenshot.png
│   └── dashboard_link.txt
├── EDA.ipynb
├── data_dictionary.md
├── README.md
├── Process.md
└── requirements.txt
```

README 至少包含：

- Business context
- Dataset description
- Data model
- Cleaning decisions
- SQL methods
- Python methods
- Dashboard screenshot
- 3 個主要 insights
- 3 個 business recommendations
- Limitations
- How to reproduce

---

## 10. 建議的三個 Insight

### Insight 1：配送延遲與顧客滿意度

延遲訂單的平均評分明顯低於準時訂單。建議平台優先檢查高訂單量且高延遲率的州別或商品類別。

### Insight 2：銷售集中於少數商品類別

比較各類別的 GMV、訂單量與平均商品價格，找出高銷售貢獻類別，以及銷售量高但客單價低的類別。

### Insight 3：重複購買比例偏低

以 `customer_unique_id` 判斷顧客是否重複購買，將結果作為會員經營、回購促進或 CRM 分析的後續機會。

這些結論屬於描述性分析，不能直接推論改善配送一定會造成評分或回購提升。

---

## 11. 職缺對照

Shopee B2C Data Analyst Intern 的 JD 重點包括：

- 從資料擷取、探索到提出假設
- 結構化分析並評估結果
- 支援商業決策
- 建立與維護 dashboard
- SQL
- Excel
- 跨部門溝通與洞察表達

近期台灣資料分析實習職缺也反覆出現 Web/App 行為分析、行銷成效、資料清理、自動化視覺報表、Python、Excel 與 BI 工具等要求：

- [104 資料分析實習職缺搜尋](https://www.104.com.tw/jobs/search/?keyword=%E6%95%B8%E6%93%9A%E5%88%86%E6%9E%90%E5%AF%A6%E7%BF%92)
- [104 Data Analyst Intern 職缺搜尋](https://www.104.com.tw/jobs/search/?keyword=data+analyst+%E5%AF%A6%E7%BF%92)
- [Shopee 2026 Apprentice Program](https://ene.site.nthu.edu.tw/p/406-1180-304739,r5613.php?Lang=zh-tw)

因此本專案需要明確展示：

- SQL 能從多張資料表產出 KPI
- Python 能清理、驗證與重組資料
- Tableau 能製作可供營運追蹤的 dashboard
- 分析結論能回答具體商業問題
- 結論可以轉成合作單位聽得懂的建議

Excel 可以作為小型補充交付物，例如製作月度 KPI 表、pivot table、`XLOOKUP` 或 `SUMIFS`，但不需要讓 Excel 取代 SQL、Python 與 Tableau 的主軸。

---

## 12. 最有效率的執行順序

### Phase 1：資料準備

- 建立資料字典
- 確認目前 5 張 processed tables 與 schema 的 row counts、主鍵及 foreign key
- 在 README 記錄 ZIP code 前導零未保留的資料限制

### Phase 2：SQL

- 完成 `02_order_view.sql`
- 完成 `03_analysis.sql`
- 完成月度 KPI、商品類別、州別、訂單狀態、配送/評分與重複購買分析

### Phase 3：Python

- 整理 notebook
- 補上驗證與輸出流程
- 不在 Python 另建衍生欄位；確認衍生欄位由 SQL view 產生

### Phase 4：Tableau

- 建立一頁 Marketplace Performance Overview dashboard
- 檢查 KPI 與 SQL、Python 是否一致
- 匯出 dashboard screenshot

### Phase 5：作品集包裝

- 撰寫 README
- 整理三個 insight 與三個建議
- 加上限制與重現步驟
- 補充 Excel KPI 表
- 將專案連結放入履歷

預期可以在 3–5 個專注工作天完成一個可投遞的 MVP 版本。

---

## 13. Claude 執行時的工作原則

- 優先沿用目前 Olist 資料與既有清理成果
- 不要為了增加複雜度而加入機器學習模型
- 不要直接刪除合理的缺失資料
- 每次 join 後檢查 row count 與資料粒度
- 所有 KPI 必須有明確定義
- 所有 insight 必須可以由 SQL 或 Python 結果重現
- Tableau 儀表板保持簡潔，以營運追蹤與決策支援為主
- README 使用非技術主管也能理解的語言
- 不要將相關性寫成因果關係
- 不要宣稱完成未實際部署的自動化流程

---

## 14. 最新專案 Review 結果

本次完整檢查日期：2026-10-12。

### 已確認正常

- 5 張 processed CSV 的欄位數與每列欄位數一致
- customers、orders、products 的主鍵沒有重複
- `order_items` 的 `(order_id, order_item_id)` 沒有重複
- 現有 orders、customers、products、order_items、order_reviews 的 foreign key 關係沒有 orphan records
- 現有 CSV row counts 與 `01_schema_load.sql` 中的預期值一致
- `order_reviews` 中的重複 `review_id` 已由複合主鍵 `(review_id, order_id)` 避免主鍵衝突

### 已確認的範圍決策

- 本專案只使用目前 5 張核心資料表，不新增 payments 或 sellers schema
- 不做賣家績效分析；分析範圍以訂單、商品、客戶、州別、配送與評論為主
- 不修復 ZIP code 前導零，因為本專案使用州別進行地區分析；在 README 的 limitations 中說明即可
- SQL 固定使用 MySQL，執行環境為 Windows 個人電腦
- SQL 檔案固定為 `01_schema_load.sql`、`02_order_view.sql`、`03_analysis.sql`
- 衍生欄位統一在 `02_order_view.sql` 建立，不建立 `src/prepare_data.py`
- Tableau 先製作一頁 dashboard
- products 的原始 processed CSV 欄位名稱不需要修改，SQL 建表時已使用正確的 `length` 欄位名稱

### SQL 執行限制

目前只完成靜態檢查與 CSV/schema 對照，尚未在實際 MySQL/MariaDB 環境執行 SQL。正式驗證時需要確認：

- `LOCAL INFILE` 已啟用
- 從 project root 執行 schema script
- CSV 的 `\\N` 能正確載入為 SQL `NULL`
- 載入後 row counts 與 data quality checks 通過

### 下一個可接受的完成條件

在開始 Tableau 前，至少應完成：

1. 實際執行並驗證 `01_schema_load.sql`
2. 完成 `02_order_view.sql`
3. 完成第一批 monthly KPI 與 delivery/review SQL queries
4. 確認延遲定義為 delivered order 的實際送達日期晚於預計送達日期
5. 確認 SQL view、SQL analysis 與 Tableau 使用一致的 KPI 定義
