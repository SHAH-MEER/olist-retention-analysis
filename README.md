# Why Don't Customers Come Back?

A SQL and Python retention analysis of the Olist Brazilian e-commerce marketplace. Only 3.12% of customers ever place a second order. This project digs into why, using Postgres for the analytical layer and a Quarto report with interactive Plotly charts to tell the story.

Full report: [report/retention_story.html](report/retention_story.html)

## The headline finding

Delivery speed and review score, the two explanations most people would reach for first, only partly explain the low repeat rate. Customers with a late first delivery return less often than those with an on-time one (2.56% vs. 3.13%), but even a perfect first order still only returns 3% of the time. Review score barely moves the number at all. The one segment with a real, meaningful gap is customers who paid by voucher on their first order, who return at 4.52%. See the full report for the complete walkthrough, including category, spend, geography, and cohort trends.

## Tech stack

- **PostgreSQL** for the analytical database (two purpose-built views on top of the normalized source schema)
- **Python** (pandas, SQLAlchemy, Plotly) for pulling query results and charting
- **Quarto** for the narrative report, rendered to a single self-contained HTML file
- **Kaggle / kagglehub** for sourcing the raw dataset

## Repo structure

```
data/raw/           Raw Olist CSVs (gitignored, fetched via kagglehub, see below)
sql/schema/         Base table and index definitions
sql/views/          fact_orders and customer_retention_summary, the two analytical views
sql/analysis/       One SQL file per question the report answers
report/             The Quarto source (.qmd) and rendered report (.html)
plots/              Standalone PNG exports of every chart in the report
scripts/            setup_db.sh (full pipeline) and load_data.sh (data load only)
docs/               Schema and data dictionary reference docs
```

## Getting started

**Prerequisites:** PostgreSQL running locally, Python 3.11+, and the [Quarto CLI](https://quarto.org/docs/get-started/).

1. Install Python dependencies:

   ```bash
   pip install -r requirements.txt
   ```

2. Fetch the dataset (the CSVs are not committed to this repo):

   ```bash
   python -c "import kagglehub; print(kagglehub.dataset_download('olistbr/brazilian-ecommerce'))"
   ```

   Copy the CSV files from the printed path into `data/raw/`.

3. Copy `.env.example` to `.env` and set your Postgres credentials.

4. Run the full setup pipeline (creates the database, applies the schema, loads the data, and builds the views):

   ```bash
   bash scripts/setup_db.sh
   ```

5. Render the report:

   ```bash
   cd report
   quarto render retention_story.qmd
   ```

## A note on the data

Two things worth knowing before digging into the SQL:

- `customer_id` is minted fresh for every order in this dataset. `customer_unique_id` is the actual person. Every repeat-purchase query in `sql/analysis/` groups on `customer_unique_id`, not `customer_id`.
- The dataset has a fixed end date (late 2018). Recent cohorts have had less time to place a second order, which shows up as a fall-off in the cohort chart that reflects the data window, not a real trend.

## Roadmap

A lightweight Streamlit dashboard over the same two views, for ad hoc exploration beyond the fixed report, is planned as a follow-up.

## Data source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), via Kaggle.
