# Customer Behavior Analysis

End-to-end analysis of 3,900 retail customers using **Python, PostgreSQL, SQL and Power BI**: data cleaning, exploratory data analysis, SQL queries and an interactive dashboard.

![Customer Behavior Dashboard](images/dashboard.png)

## Project Summary

| | |
|---|---|
| **Goal** | Understand customer spending, product categories and purchasing behavior |
| **Data** | 3,900 customers, 19 original columns (Kaggle shopping trends dataset) |
| **Stages** | Cleaning (Python) > EDA (Python) > PostgreSQL and SQL > Power BI dashboard |
| **Tools** | Python, Pandas, NumPy, Matplotlib, Seaborn, Jupyter, PostgreSQL, SQL, Power BI, Git |
| **Result** | Totals match in Python, SQL and Power BI: **$233,081 revenue, 3,900 customers, $59.76 average purchase** |

## Dataset

The data comes from a public Kaggle shopping trends dataset (`shopping_trends.csv`). It has 3,900 rows and 19 columns, including age, gender, item purchased, category, purchase amount (USD), location, size, color, season, review rating, subscription status, payment method, shipping type, discount applied, promo code used, previous purchases, preferred payment method and frequency of purchases.

**One row represents one customer** (their latest purchase plus purchase history). I checked this: `Customer ID` has 3,900 unique values.

> **Note on the messy data:** the original dataset was already clean, with no missing values and no duplicates. To practise real data cleaning, I created `data/raw/shopping_trends_messy.csv` from it by adding missing values (Age, Review Rating, Season, Size), 60 duplicate rows, and inconsistent text (mixed casing and extra spaces). The original file is never edited. The cleaning steps below were practised on this deliberately corrupted copy.

## Workflow

### 1. Data cleaning (Python, Pandas, NumPy)
Input: `shopping_trends_messy.csv` (3,960 rows). Output: `shopping_trends_clean.csv` (3,900 rows, 20 columns, 0 missing values, 0 duplicates).

| Step | What was done | Why |
|---|---|---|
| Inspect | `shape`, `info`, `isnull`, `duplicated`, `describe`, `value_counts` | Find problems before fixing them |
| Column names | Lowercase with underscores | Works cleanly in SQL and Power BI |
| Duplicates | Removed 60 duplicate rows, sorted by customer ID | Duplicates count customers twice |
| Text | `strip()` and `title()` on gender, category, location, item | Hidden spaces had made Location show 98 values instead of 50 |
| Labels | Merged "Fortnightly" into "Bi-Weekly" and "Every 3 Months" into "Quarterly" | Same meaning, found during EDA |
| Missing values | Median for Age and Review Rating, mode for Season and Size | Keeps all customers |
| Redundant column | Dropped `promo_code_used` (identical to `discount_applied`) | No extra information |
| New columns | `age_group` (6 groups) and `spend_level` (Low, Medium, High) | Segments for analysis and dashboard slicers |

Duplicates are removed **before** filling missing values, because duplicated rows would distort the median and mode.

### 2. Exploratory data analysis (Pandas, Matplotlib, Seaborn)
Three areas, each analysed with count, mean and sum together:
- **Customer spending:** by age group, gender and location
- **Product categories:** revenue, share of revenue and seasons
- **Purchasing behavior:** subscription, discount, payment method and purchase frequency

### 3. PostgreSQL and SQL
The clean data is loaded into a PostgreSQL table (`customers`) with a primary key on `customer_id`. The queries in `sql/queries.sql` cover:
- Aggregations (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`) with `GROUP BY` and `HAVING`
- `CASE WHEN` for labels and conditional counts
- CTEs (`WITH`)
- Window functions (`RANK`, `ROW_NUMBER`, `PARTITION BY`, `OVER ()`)

Example: top 3 locations by revenue.

```sql
WITH loc AS (
    SELECT location,
           SUM(purchase_amount_usd) AS revenue,
           RANK() OVER (ORDER BY SUM(purchase_amount_usd) DESC) AS rnk
    FROM customers
    GROUP BY location
)
SELECT location, revenue, rnk
FROM loc
WHERE rnk <= 3
ORDER BY rnk;
```

Result: Montana 5,784, Illinois 5,617, California 5,605.

### 4. Power BI dashboard
Connected to PostgreSQL in Import mode. The page has three KPI cards (DAX measures), four slicers (category, gender, season, age group), and four charts: revenue by category, average purchase by age group, customers by payment method, and top 10 locations by revenue. A filter test (Clothing) returns $104,264 revenue, 1,737 customers and a $60.03 average, matching the SQL results.

## Key Insights

- **Average purchase is about $60 in every age group** ($58.57 to $60.74), and almost identical by gender ($59.54 male, $60.25 female), subscription status ($59.49 vs $59.87) and discount use ($59.28 vs $60.13).
- **Clothing earns 44.7% of revenue** (1,737 purchases, $104,264) because of volume, not higher prices. Accessories 31.8%, Footwear 15.5%, Outerwear 7.9%.
- **Totals differ between groups because of customer counts**, not spending habits. For example, ages 36-45 have the most customers (848), and 68% of customers are male.
- **Only 15.8% of customers pay with their preferred payment method**, close to the 16.7% expected by chance with six methods.
- **Customer loyalty mix** (by previous purchases): Loyal 1,631, Regular 1,561, New 708.

## Project Structure

```
customer-behavior-analysis/
|-- data/
|   |-- raw/        original and messy files (never edited)
|   `-- clean/      cleaned dataset
|-- notebooks/
|   |-- 00_make_messy_data.ipynb
|   |-- 01_cleaning.ipynb
|   |-- 02_eda.ipynb
|   `-- 03_load_to_postgres.ipynb
|-- sql/
|   `-- queries.sql
|-- dashboard/
|   `-- customer_behavior.pbix
|-- images/
|   `-- dashboard.png
`-- README.md
```

## How to Run

1. Install the Python libraries:
   ```
   pip install pandas numpy matplotlib seaborn jupyter sqlalchemy psycopg2-binary
   ```
2. Run the notebooks in order (`00` to `03`). The cleaning notebook reads from `data/raw` and writes `data/clean/shopping_trends_clean.csv`.
3. Install PostgreSQL and pgAdmin, create a database named `customer_behavior`, and create the table:

   <details>
   <summary>CREATE TABLE statement</summary>

   ```sql
   CREATE TABLE customers (
       customer_id              INT PRIMARY KEY,
       age                      INT,
       gender                   VARCHAR(10),
       item_purchased           VARCHAR(50),
       category                 VARCHAR(30),
       purchase_amount_usd      INT,
       location                 VARCHAR(50),
       size                     VARCHAR(5),
       color                    VARCHAR(30),
       season                   VARCHAR(10),
       review_rating            NUMERIC(3,1),
       subscription_status      VARCHAR(5),
       payment_method           VARCHAR(30),
       shipping_type            VARCHAR(30),
       discount_applied         VARCHAR(5),
       previous_purchases       INT,
       preferred_payment_method VARCHAR(30),
       frequency_of_purchases   VARCHAR(20),
       age_group                VARCHAR(10),
       spend_level              VARCHAR(10)
   );
   ```
   </details>

4. Run `03_load_to_postgres.ipynb`. It asks for your PostgreSQL password when it runs, so no password is stored in the code.
5. Run the queries in `sql/queries.sql` in pgAdmin.
6. Open `dashboard/customer_behavior.pbix` in Power BI Desktop (Windows) and refresh the data source if needed (server `localhost`, database `customer_behavior`).

## Skills Demonstrated

- **Python:** Pandas, NumPy, data cleaning, validation, feature engineering
- **Visualisation:** Matplotlib, Seaborn, Power BI
- **SQL / PostgreSQL:** table design, aggregations, CASE WHEN, CTEs, window functions
- **Power BI:** data modelling basics, DAX measures, slicers, dashboard design
- **Process:** reproducible pipeline, raw data never edited, cross-checking results across tools, Git and GitHub

## Challenges and What I Learned

- Hidden spaces made `Location` show 98 values instead of 50. Using `strip()` fixed it.
- Duplicate frequency labels were only noticed during EDA, so I went back to the cleaning notebook, merged them, and re-ran the pipeline.
- Filling missing seasons with the most common value inflated the Spring count by 80, so I treat seasonal differences as unreliable.
- My Power BI had no Display units option, so I used `FORMAT` measures for the KPI cards.
- Comparing count, mean and sum together prevented a wrong conclusion: groups with higher totals simply had more customers.

## Limitations

- Each row is one customer, so there is no time trend or repeat-purchase analysis.
- Results compare averages (correlation) and do not prove cause.
- The data is unusually even across groups, so patterns are weak.
- No statistical significance tests were run. Differences of a dollar or two are descriptive only.

## Contact

**Himanshu** | [LinkedIn](https://www.linkedin.com/in/himanshu-02a28b254) | [GitHub](https://github.com/er-himanshujangid)
