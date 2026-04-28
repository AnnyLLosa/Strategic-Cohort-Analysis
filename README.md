# 🚀 E-Commerce Analytics: Cohort & Retention Pipeline

![Banner](./visualizations/e-commerce.jpg)

## 📋 Project Overview

This project implements a complete data pipeline for analyzing customer behavior and retention in an e-commerce environment. By applying a **Medallion Architecture (3 layers)**, raw transactional data is transformed into strategic insights that identify repeat purchase patterns and cohort health over time.

### 🛠️ Tech Stack

- **Languages:** Python, SQL (BigQuery / Databricks dialect)
- **Libraries:** Pandas, Matplotlib, NumPy, SQLite3
- **Infrastructure:** Jupyter Notebooks, Databricks SQL Dashboards

---

## 🏗️ Data Architecture

The pipeline follows professional data engineering standards:

1. **Raw Layer** — Direct ingestion of the CSV source data.
2. **Cleaned Layer** — Null handling, data type casting, and filtering of inconsistent records.
3. **Analytics Layer** — Business logic implemented via **Window Functions** and **CTEs** to define and segment customer cohorts.

---

## 📊 Visualizations & Data Insights

The analysis produces business-critical KPIs visualized in the dashboard below:

| Cohort Size | Retention Rate (1–3 Months) | Repeat Purchase Rate |
|:---:|:---:|:---:|
| <img width="1335" height="734" alt="cohort_size" src="https://github.com/user-attachments/assets/f47cd0cf-b940-4bcf-b2e9-9bc95926d793" > | <img width="1485" height="734" alt="retention_rate" src="https://github.com/user-attachments/assets/e334aa1a-05c4-4325-8dce-b6f6e7ff1d45" > | <img width="1485" height="734" alt="repeat_purchase_rate" src="https://github.com/user-attachments/assets/2e103ffe-e88a-4f45-9519-74c7e64d1028" >
 |



### 💡 Key Performance Indicators (KPIs) & Business Impact

* **Exceptional 3-Month Retention (87%):** Most customers who join the platform become loyal users within 90 days. This reflects high product satisfaction and strong long-term product-market fit.
* **The 30-Day Re-engagement Gap:** While long-term retention is high, only **39%** of customers return within the first month.
    * *Strategic Recommendation:* Implement automated email marketing or push notifications 14 days after the first purchase to bridge this gap and accelerate the second-purchase cycle.
* **Near-Perfect 2nd Order Rate (99%):** Almost every single customer makes at least one repeat purchase. This is a clear indicator of a successful initial user experience and onboarding.
* **Acquisition Trends:** January remains the strongest cohort in terms of volume (66 new customers), providing a benchmark for successful seasonal acquisition campaigns.

---

## 💡 Business Case & Strategy

This project goes beyond data processing. A strategic stakeholder presentation was developed covering:

- **Churn analysis** — Root cause investigation for drop-off after the first month.
- **Growth strategies** — Targeted campaigns optimized for the 30-day re-engagement window.
- **ROI impact** — Revenue projection for a 5% increase in 1-month retention.

📊 **[View the full Canva presentation here](https://canva.link/mbxu687po8qc4gd)**

---

## 🚀 Enterprise Scalability

While the project runs locally with SQLite, it is designed for enterprise-scale environments:

- **Cloud Ready:** The `/sql` folder contains `bigquery_pipeline.sql` with optimized logic for cloud warehouses, using `DATE_TRUNC`, `PARTITION BY`, and multi-layer CTEs.
- **Dashboard-as-Code:** The file `e-commerce.lvdash.json` enables direct import of the dashboard configuration into **Databricks SQL**.

---

## ⚙️ Installation & Usage

```bash
# # 1. Clone the repository

git clone https://github.com/Anny_LLosa/strategic-cohort-analysis.git

cd ecommerce-cohort-analysis

# 2. Install dependencies
pip install -r requirements.txt

# 3. Launch the notebook
jupyter notebook cohort_analysis.ipynb
```

> No cloud accounts required. Everything runs locally out of the box.

---

## 📁 Project Structure

```text
ecommerce-cohort-analysis/
├── data/
│   └── ecom_orders.csv              # Raw source dataset
├── sql/
│   └── bigquery_pipeline.sql        # Production-grade BigQuery/SQL queries
├── visualizations/
│   ├── cohort_size.png              # Monthly acquisition trends
│   ├── retention_rate.png           # Retention rate by cohort
│   └── repeat_purchase_rate.png     # Loyalty depth metrics
├── cohort_analysis.ipynb            # Main pipeline & local analysis
├── e-commerce.lvdash.json           # Databricks SQL Dashboard definition
├── requirements.txt                 # Python dependencies
└── README.md                        # Project documentation
```

---

## 📦 Requirements

```
pandas>=2.0
matplotlib>=3.7
numpy>=1.24
jupyter
```
