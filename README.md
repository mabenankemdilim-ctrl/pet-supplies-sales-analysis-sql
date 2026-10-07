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
Prior to loading the dataset into PostgreSQL, data auditing, standardization, and missing value handling were completed in Excel:

* **Primary Key Verification:** Audited `product_id` to confirm zero duplicate values and ensured no missing or blank cells existed across all 1,500 records.
* **Categorical Standardization:** 
  * Replaced both blank cells and entries containing `"-"` in `category` with `"Unknown"`.
  * Audited `animal` and verified that values conformed cleanly to expected species classifications with no modifications required.
  * Standardized casing in `size` using proper capitalization (e.g., `Small`, `Medium`, `Large`) to resolve inconsistent text entries.
* **Numerical Imputation & Formatting:**
  * Identified non-numeric `"unlisted"` entries in `price` and imputed them with the catalog median value of `28.065`.
  * Formatted both `price` and `sales` to standard two-decimal-place currency precision.
* **Ratings & Retention Audit:**
  * Replaced all `"NA"` values in `rating` with `0` to explicitly flag unrated products.
  * Verified that `repeat_purchase` strictly contained valid binary flags (`0` or `1`) across all rows.

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
    ROUND(AVG(NULLIF(rating, 0)), 2) AS avg_rating,
    ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_purchase_rate_pct
FROM pet_supplies;
```

| Total Products | Avg Product Price | Total Revenue | Avg Rating | Repeat Purchase Rate (%) |
| :--- | :--- | :--- | :--- | :--- |
| 1,500 | $29.29 | $1,494,896.77 | 4.99 | 60.40% |

> **Takeaway:** The catalog generated **$1,494,896.77** across **1,500** items with an average product price of **$29.29**. The baseline repeat purchase rate is solid at **60.40%**, while the average customer rating sits at **4.99** (excluding all 0 (Unknown) values).

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

| Category | Total Sales | Avg Sales per Product | Repeat Rate Pct |
| :--- | :--- | :--- | :--- |
| Equipment | 348,875.24 | 942.91 | 59.73% |
| Toys | 319,897.10 | 1,254.50 | 56.86% |
| Food | 287,138.16 | 1,104.38 | 58.08% |
| Medicine | 214,066.25 | 903.23 | 64.56% |
| Housing | 175,330.31 | 772.38 | 66.96% |
| Accessory | 121,273.44 | 962.49 | 55.56% |
| Unknown | 28,316.27 | 1,132.65 | 56.00% |

> **Takeaway:** Equipment drives the highest total revenue ($348.8K), while Toys delivers the highest revenue per individual product listing ($1,254.50). In contrast, customer loyalty is concentrated in care and living essentials, where Housing (66.96%) and Medicine (64.56%) achieve the highest repeat purchase rates.

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

| animal | size | product_count | avg_price | avg_sales |
| :--- | :--- | :--- | :--- | :--- |
| Bird | Small | 33 | 41.45 | 1,430.64 |
| Bird | Medium | 82 | 36.96 | 1,131.91 |
| Bird | Large | 82 | 44.34 | 1,646.00 |
| Cat | Small | 393 | 28.74 | 1,072.88 |
| Cat | Medium | 149 | 23.93 | 797.64 |
| Cat | Large | 25 | 32.83 | 1,349.71 |
| Dog | Small | 130 | 33.05 | 1,120.32 |
| Dog | Medium | 145 | 27.89 | 819.68 |
| Dog | Large | 92 | 36.43 | 1,346.86 |
| Fish | Small | 198 | 24.18 | 741.42 |
| Fish | Medium | 116 | 18.94 | 503.74 |
| Fish | Large | 55 | 28.04 | 945.87 |

> **Takeaway:** Small Cat products represent the most catalog-dense segment by far (393 products), but Bird products command the highest average price points and average sales across every size category—peaking with Large Bird products ($44.34 average price, $1,646.00 average sales). Across all four animal categories, Medium products systematically yield both the lowest average prices and the lowest average sales compared to their Small and Large counterparts.

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
| Bird | 1 | 1443 | Toys | 2,255.96 | 8 |
| Bird | 2 | 653 | Toys | 2,254.99 | 8 |
| Bird | 3 | 295 | Toys | 2,249.40 | 4 |
| Cat | 1 | 863 | Toys | 1,724.15 | 7 |
| Cat | 2 | 1383 | Toys | 1,723.87 | 8 |
| Cat | 3 | 1091 | Toys | 1,723.84 | 6 |
| Dog | 1 | 518 | Toys | 1,797.02 | 7 |
| Dog | 2 | 280 | Toys | 1,795.77 | 5 |
| Dog | 3 | 728 | Toys | 1,793.71 | 6 |
| Fish | 1 | 130 | Toys | 1,307.35 | 4 |
| Fish | 2 | 385 | Toys | 1,301.35 | 9 |
| Fish | 3 | 900 | Toys | 1,300.55 | 9 |

> **Takeaway:** The Toys category completely dominates the top 3 sales ranks across all four animal categories. Bird toys generate the highest peak sales per SKU ($2,249–$2,256), outpacing the top Dog and Cat toys by roughly $450 to $530 per item. High sales volume does not strongly correlate with customer satisfaction, as several top-ranking items sustain peak revenue despite lower ratings (such as Bird #3 and Fish #1, both rated 4/10).

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
| 0 (Unrated) | 150 | 1,046.32 | 58.00 |
| Low (1-4) | 528 | 888.75 | 64.77 |
| Mid (5-7) | 746 | 1,036.43 | 58.45 |
| High (8-10) | 76 | 1,256.80 | 53.95 |

> **Takeaway:** Customer satisfaction displays an inverse relationship with repeat purchase behavior: Low-rated products (1–4) achieve the highest repeat purchase rate at 64.77%, whereas High-rated products (8–10) yield the lowest at 53.95%. However, High-rated items generate substantially higher average sales ($1,256.80 vs. $888.75 for Low-rated), despite accounting for just ~5% of the total catalog (76 items). Products in the Mid-tier (5–7) and Unrated (0) tiers track closely in repeat rates at roughly 58%.

--- 

## 6. SKUs Outperforming Category Averages
Calculates variance from category averages using window functions and subqueries to highlight top individual performers.

```sql
WITH CategoryBaselines AS (
    SELECT 
        product_id,
        category,
        sales,
        AVG(sales) OVER(PARTITION BY category) AS category_avg_sales
    FROM pet_supplies
)
SELECT 
    product_id,
    category,
    sales,
    ROUND(category_avg_sales, 2) AS category_avg_sales,
    ROUND(sales - category_avg_sales, 2) AS variance_from_category_avg
FROM CategoryBaselines
WHERE sales > category_avg_sales
ORDER BY variance_from_category_avg DESC
LIMIT 10;
```

| product_id | category | sales | category_avg_sales | variance_from_category_avg |
| :--- | :--- | :--- | :--- | :--- |
| 1443 | Toys | 2,255.96 | 1,254.50 | +1,001.46 |
| 653 | Toys | 2,254.99 | 1,254.50 | +1,000.49 |
| 295 | Toys | 2,249.40 | 1,254.50 | +994.90 |
| 40 | Toys | 2,248.63 | 1,254.50 | +994.13 |
| 449 | Toys | 2,248.04 | 1,254.50 | +993.54 |
| 467 | Toys | 2,246.77 | 1,254.50 | +992.27 |
| 1105 | Toys | 2,244.67 | 1,254.50 | +990.17 |
| 459 | Medicine | 1,871.35 | 903.23 | +968.12 |
| 1156 | Medicine | 1,866.60 | 903.23 | +963.37 |
| 1417 | Equipment | 1,873.47 | 942.91 | +930.56 |

> **Takeaway:** Toys dominate catalog outperformance, capturing 7 of the top 10 spots for absolute revenue variance above category averages, led by SKU `1443` at +$1,001.46 (~80% above baseline). However, non-toy outliers demonstrate even steeper relative premiums over their peer groups: top Medicine SKUs (`459` and `1156`) more than double their category average (+107% / +$960+), while top Equipment SKU `1417` drives $1,873.47 in sales (+$930.56 / +99% over baseline).


### Actionable Business Recommendations

1. **Expand the Bird SKU Catalog:** Despite having far fewer listings than Cats (567) or Dogs (367), Bird products generate the highest average price points ($36.96–$44.34) and average revenue per product ($1,131–$1,646) across all size tiers. Broadening the Bird catalog—especially in high-performing Large products and Toys—represents a high-margin expansion path.

2. **Bundle High-Yield Toys with High-Repeat Categories:** Toys generate the highest revenue per listing ($1,254.50) but demonstrate below-average repeat purchase rates (56.86%). Create bundled promotions or post-purchase follow-ups that pair high-performing toys with high-retention necessity categories like Medicine (64.56% repeat rate) and recurring care supplies to convert discretionary toy buyers into recurring customers.

3. **Mitigate Churn Risk on Low-Rated, High-Repeat Products:** Products rated 1–4 command the highest repeat purchase rate (64.77%) across 528 catalog items. Customers are repurchasing these items out of necessity despite low satisfaction—creating an acute vulnerability to competitor switching. Audit top-selling SKUs within the 1–4 rating tier for quality defects, supplier replacements, or packaging improvements to protect repeat revenue streams.

---

## Tech Stack & Tools

* **Database Engine:** PostgreSQL
* **Query Techniques:** 
  * Window Functions (`DENSE_RANK()`, `PARTITION BY`, `OVER()`)
  * Common Table Expressions (CTEs / `WITH` queries)
  * Multi-dimensional Grouping & Aggregations (`GROUP BY`, `SUM`, `AVG`, `COUNT`)
  * Conditional Logic & Value Binning (`CASE WHEN ... THEN`)
  * Type Casting (`::NUMERIC`)
* **Data Auditing & Preprocessing:** Microsoft Excel (Imputation, Data Cleaning, Standardization)
