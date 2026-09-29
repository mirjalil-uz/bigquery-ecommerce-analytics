# Looker Studio Dashboard — Build Guide

Looker Studio is Google's free dashboard tool and connects directly to BigQuery.

## 1. Connect the data

1. Run `sql/08_reporting_layer.sql` in BigQuery first.
2. Go to [lookerstudio.google.com](https://lookerstudio.google.com) → **Create** → **Report**.
3. Choose the **BigQuery** connector → your project → dataset `ecommerce_analytics`.
4. Add these three data sources:
   - `v_monthly_kpis`
   - `v_category_monthly`
   - `v_customers_by_channel`

## 2. Pages to build

### Page 1 — Executive Overview (`v_monthly_kpis`)
- **Scorecards:** Revenue, Gross Profit, Orders, Customers, Return Rate (compare to previous period)
- **Line chart:** Revenue and Gross Profit by `month`
- **Calculated field:** `Gross Margin % = SUM(gross_profit) / SUM(revenue)`
- **Date range control** at the top

### Page 2 — Category Performance (`v_category_monthly`)
- **Bar chart:** Revenue by `category` (sorted descending)
- **Table:** category, units_sold, revenue, gross_profit, units_returned, with heatmap on margin
- **Calculated field:** `Return Rate = SUM(units_returned) / (SUM(units_sold) + SUM(units_returned))`
- **Filter control:** `department` (Men / Women)

### Page 3 — Customers & Channels (`v_customers_by_channel`)
- **Geo map:** Revenue by `country`
- **Bar chart:** Revenue per customer by `traffic_source`
- **Filter controls:** `traffic_source`, `country`

## 3. Finishing touches
- Use one color per metric throughout (e.g., revenue always blue).
- Add a short text box on each page with the **one key insight**.
- **Share → Anyone with the link can view**, then put the link in the GitHub README and on LinkedIn.
- Save screenshots of each page into the `results/` folder.

*Power BI alternative:* Get Data → Google BigQuery → sign in → select the same views.
