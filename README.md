# Pet Supplies Product Performance & Customer Retention Analysis

## Executive Summary
This project analyzes product-level sales, unit economics, customer ratings, and repeat purchasing patterns for an online pet supplies business. The objective is to identify core revenue drivers, evaluate customer loyalty across merchandise categories, and isolate product-level outperformers using **PostgreSQL**.

---

## Business Objectives
* **Portfolio Health Check:** Evaluate total commercial performance, pricing distribution, and customer retention baselines across all products.
* **Category Contribution:** Identify which product categories drive top-line revenue and compare their sales velocity against repeat purchase loyalty.
* **Segment Opportunity:** Analyze product density and sales across pet species (`Bird`, `Cat`, `Dog`, `Fish`) and size classifications.
* **Merchandising Champions:** Isolate the top-performing SKUs per animal segment using window functions and identify items outperforming category averages.
* **Customer Sentiment vs. Retention:** Determine whether higher review ratings correlate with stronger repeat purchase behavior.

---

## Dataset & Business Rules
The dataset consists of **1,500 unique product records** evaluated against the following structural criteria:

| Column Name | Data Type | Business Criteria / Handling |
|:---|:---|:---|
| `product_id` | Nominal | Unique identifier for each product. Missing values not permitted. |
| `category` | Nominal | One of 6 categories: *Housing, Food, Toys, Equipment, Medicine, Accessory*. Missing values assigned `"Unknown"`. |
| `animal` | Nominal | Target animal: *Dog, Cat, Fish, Bird*. Missing values assigned `"Unknown"`. |
| `size` | Ordinal | Size classification: *Small, Medium, Large*. Missing values assigned `"Unknown"`. |
| `price` | Continuous | Product sale price rounded to 2 decimal places. Missing values imputed with the global median price. |
| `sales` | Continuous | Trailing 12-month sales value rounded to 2 decimal places. Missing values imputed with the global median sales. |
| `rating` | Discrete | Customer rating scale (1 to 10). Missing values imputed as `0` (Unrated). |
| `repeat_purchase` | Binary | Customer repeat purchase status: `1` (Repeat) or `0` (Single purchase). Missing rows removed. |

---

## Data Cleaning & Preparation (Excel)
Prior to loading the data into PostgreSQL, data auditing and standardization were completed in Excel:
* **Missing Value Imputation:** 
  * Replaced blank categorical values (`category`, `animal`, `size`) with `"Unknown"`.
  * Imputed missing numerical fields (`price`, `sales`) using `=MEDIAN(...)`.
  * Filled missing `rating` values with `0` to denote an unrated state without distorting true customer review scores.
* **Data Integrity Checks:** 
  * Removed records missing `repeat_purchase` values and verified that values strictly contain binary flags (`0` or `1`).
  * Enforced two-decimal-place currency formatting for `price` and `sales`.
  * Verified that all 1,500 `product_id` values are unique and non-null.

---

## Database Schema (PostgreSQL)

```sql
CREATE TABLE pet_supplies (
    product_id INT PRIMARY KEY,
    category VARCHAR(50),
    animal VARCHAR(50),
    size VARCHAR(20),
    price NUMERIC(10, 2),
    sales NUMERIC(10, 2),
    rating INT,
    repeat_purchase INT
);
```

---

# SQL Queries, Results & Analytical Takeaways

## 1. Overall Portfolio Performance Baseline
Establishes baseline portfolio volume, pricing benchmarks, and global customer retention.

```sql
SELECT 
    COUNT(product_id) AS total_products, 
    ROUND(AVG(price)::NUMERIC, 2) AS avg_product_price,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_revenue, 
    ROUND(AVG(rating)::NUMERIC, 2) AS avg_rating,
    ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_purchase_rate_pct
FROM pet_supplies;
```

| Total Products | Avg Product Price | Total Revenue | Avg Rating | Repeat Purchase Rate (%) |
| :--- | :--- | :--- | :--- | :--- |
| 1,500 | $26.48 | $1,494,896.77 | 4.49 | 60.40% |

> **Takeaway:** The catalog generated **$1,494,896.77** across **1,500** items with an average product price of **$26.48**. The baseline repeat purchase rate is solid at **60.40%**, while the average customer rating sits at **4.49** (moderated by the unrated items scored as 0).

---

## 2. Category Performance vs. Repeat Purchases
Evaluates total revenue, average product velocity, and customer loyalty across product categories.

```sql
SELECT 
    category, 
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales_per_product, 
    ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_rate_pct
FROM pet_supplies
GROUP BY category
ORDER BY total_sales DESC;
```

| Category | Total Sales | Avg Sales Per Product | Repeat Rate Pct |
| :--- | :--- | :--- | :--- |
| Equipment | $348,875.24 | $942.91 | 59.73% |
| Toys | $319,897.10 | $1,254.50 | 56.86% |
| Food | $287,138.16 | $1,104.38 | 58.08% |
| Medicine | $214,066.25 | $903.23 | 64.56% |
| Housing | $175,330.31 | $772.38 | 66.96% |
| Accessory | $121,273.44 | $962.49 | 55.56% |
| Unknown | $28,316.27 | $1,132.65 | 56.00% |

> **Takeaway:** Equipment is the largest overall revenue generator ($348.8K), but Toys commands the highest average sales velocity per item ($1,254.50). Conversely, essential consumable/habitat categories—Housing (66.96%) and Medicine (64.56%)—deliver the highest repeat purchase rates.

---

## 3. Pet Species & Size Segmentation Matrix
Analyzes inventory depth, average price, and item sales across animal types and size tiers.
```sql
SELECT 
    animal,
    size,
    COUNT(product_id) AS product_count,
    ROUND(AVG(price)::NUMERIC, 2) AS avg_price,
    ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales
FROM pet_supplies
WHERE animal != 'Unknown' AND size != 'Unknown'
GROUP BY animal, size
ORDER BY animal, 
    CASE size 
        WHEN 'Small' THEN 1 
        WHEN 'Medium' THEN 2 
        WHEN 'Large' THEN 3 
        ELSE 4 
    END;
```

| animal | size   | product_count | avg_price | avg_sales  |
| :----- | :----- | ------------: | --------: | ---------: |
| Bird   | Small  |            33 |    $37.20 |  $1,430.64 |
| Bird   | Medium |            82 |    $34.22 |  $1,131.91 |
| Bird   | Large  |            82 |    $40.92 |  $1,646.00 |
| Cat    | Small  |           393 |    $25.81 |  $1,072.88 |
| Cat    | Medium |           149 |    $21.30 |    $797.64 |
| Cat    | Large  |            25 |    $29.46 |  $1,349.71 |
| Dog    | Small  |           130 |    $29.38 |  $1,120.32 |
| Dog    | Medium |           145 |    $25.76 |    $819.68 |
| Dog    | Large  |            92 |    $32.77 |  $1,346.86 |
| Fish   | Small  |           198 |    $22.05 |    $741.42 |
| Fish   | Medium |           116 |    $17.00 |    $503.74 |
| Fish   | Large  |            55 |    $24.98 |    $945.87 |

> **Takeaway:** Cat Small is the most catalog-dense segment (393 items), but Bird products command the highest average prices and revenue across sizes (peaking at $40.92 price and $1,646.00 sales for Large). Across all species, Medium sized products consistently generate lower average sales than Small or Large items.

---

## 4. Top 3 Revenue Drivers per Animal Category
Applies window functions `(DENSE_RANK())` to find the top 3 selling products for each species.

```sql
WITH RankedProducts AS (
    SELECT 
        product_id,
        category,
        animal,
        sales,
        rating,
        DENSE_RANK() OVER (
            PARTITION BY animal 
            ORDER BY sales DESC
        ) AS sales_rank
    FROM pet_supplies
    WHERE animal != 'Unknown'
)
SELECT 
    animal,
    sales_rank,
    product_id,
    category,
    sales,
    rating
FROM RankedProducts
WHERE sales_rank <= 3
ORDER BY animal, sales_rank;
```

| animal | sales_rank | product_id | category | sales | rating |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Bird | 1 | 1443 | Toys | $2,255.96 | 8 |
| Bird | 2 | 653 | Toys | $2,254.99 | 8 |
| Bird | 3 | 295 | Toys | $2,249.40 | 4 |
| Cat | 1 | 219 | Toys | $1,729.76 | 0 |
| Cat | 2 | 863 | Toys | $1,724.15 | 7 |
| Cat | 3 | 1383 | Toys | $1,723.87 | 8 |
| Dog | 1 | 518 | Toys | $1,797.02 | 7 |
| Dog | 2 | 280 | Toys | $1,795.77 | 5 |
| Dog | 3 | 250 | Toys | $1,795.05 | 0 |
| Fish | 1 | 130 | Toys | $1,307.35 | 4 |
| Fish | 2 | 385 | Toys | $1,301.35 | 9 |
| Fish | 3 | 900 | Toys | $1,300.55 | 9 |

> **Takeaway:** Toys sweeps the top 3 spots across all four animal categories. Bird toys deliver the highest peak revenue per SKU in the entire business ($2,250+), outperforming top dog and cat toys by over $450 per product. Several top-earning items maintain high sales despite unrated or low customer review scores.

---

## 5. Customer Rating Cohort vs. Retention Analysis
Segments customer review scores into cohorts to test whether customer satisfaction directly predicts repeat purchase behavior.

```sql
SELECT 
    CASE 
        WHEN rating = 0 THEN '0 (Unrated)'
        WHEN rating BETWEEN 1 AND 4 THEN 'Low (1-4)'
        WHEN rating BETWEEN 5 AND 7 THEN 'Mid (5-7)'
        ELSE 'High (8-10)'
    END AS rating_tier, 
    COUNT(product_id) AS total_items, 
    ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales, 
    ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_purchase_pct
FROM pet_supplies
GROUP BY 1
ORDER BY MIN(rating);
```

| rating_tier | total_items | avg_sales | repeat_purchase_pct |
| :--- | :--- | :--- | :--- |
| 0 (Unrated) | 150 | $1,046.32 | 58.00% |
| Low (1-4) | 528 | $888.75 | 64.77% |
| Mid (5-7) | 746 | $1,036.43 | 58.45% |
| High (8-10) | 76 | $1,256.80 | 53.95% |

> **Takeaway:** Lower ratings exhibit higher repeat purchase rates. Products rated 1–4 have a 64.77% repeat purchase rate, compared to 53.95% for products rated 8–10. While high-rated items achieve higher average sales ($1,256.80), their lower repeat rate indicates they are primarily durable, one-time purchases (e.g., premium cages or tanks), whereas lower-rated items likely consist of essential consumables bought repeatedly despite mixed satisfaction.

--- 

## 6. SKUs Outperforming Category Averages
Calculates variance from category averages using window functions and subqueries to highlight top individual performers.

```sql
SELECT 
    product_id,
    category,
    sales,
    ROUND(AVG(sales) OVER(PARTITION BY category)::NUMERIC, 2) AS category_avg_sales,
    ROUND((sales - AVG(sales) OVER(PARTITION BY category))::NUMERIC, 2) AS variance_from_category_avg
FROM pet_supplies
WHERE sales > (
    SELECT AVG(p2.sales) 
    FROM pet_supplies p2 
    WHERE p2.category = pet_supplies.category
)
ORDER BY variance_from_category_avg DESC
LIMIT 10;
```

| product_id | category | sales | category_avg_sales | variance_from_category_avg |
| :--- | :--- | :--- | :--- | :--- |
| 1417 | Equipment | $1,873.47 | $1,064.17 | +$809.30 |
| 1443 | Toys | $2,255.96 | $1,453.14 | +$802.82 |
| 653 | Toys | $2,254.99 | $1,453.14 | +$801.85 |
| 295 | Toys | $2,249.40 | $1,453.14 | +$796.26 |
| 40 | Toys | $2,248.63 | $1,453.14 | +$795.49 |
| 449 | Toys | $2,248.04 | $1,453.14 | +$794.90 |
| 467 | Toys | $2,246.77 | $1,453.14 | +$793.63 |
| 1105 | Toys | $2,244.67 | $1,453.14 | +$791.53 |
| 459 | Medicine | $1,871.35 | $1,115.99 | +$755.36 |
| 1156 | Medicine | $1,866.60 | $1,115.99 | +$750.61 |

> **Takeaway:** Product `1417` (Equipment) has the *highest individual margin over its peer group* (+$809.30). Furthermore, 7 of the top 10 outperformers are Toys, reinforcing Toys as the primary product line for *high-margin individual SKUs*.

### Actionable Business Recommendations

1. **Scale the Bird Product Line:** Despite lower catalog representation than Cats or Dogs, Bird products generate the highest average selling prices and sales volumes across sizes. Expanding the Bird SKU catalog offers clear upside.
2. **Cross-Sell Bundles (Toys + Consumables):** Toys drive top revenue velocity but trail in repeat purchases. Creating promotional bundles pairing popular toys with high-retention essentials (Housing and Medicine) will help increase customer lifetime value (LTV).
3. **Product Quality Interventions on High-Repeat Items:** Products in the 1–4 rating tier account for a 64.77% repeat purchase rate. Customers are regularly repurchasing items with sub-par ratings due to necessity, presenting a major retention risk if competitors offer better quality alternatives. Prioritize quality audits and supplier reviews on high-volume products in this tier.

4. ---

## Tech Stack & Tools

* **Database Engine:** PostgreSQL
* **Query Techniques:** 
  * Window Functions (`DENSE_RANK()`, `PARTITION BY`, `OVER()`)
  * Common Table Expressions (CTEs / `WITH` queries)
  * Multi-dimensional Grouping & Aggregations (`GROUP BY`, `SUM`, `AVG`, `COUNT`)
  * Conditional Logic & Value Binning (`CASE WHEN ... THEN`)
  * Correlated Subqueries & Type Casting (`::NUMERIC`)
* **Data Auditing & Preprocessing:** Microsoft Excel (Imputation, Data Cleaning, Standardization)
