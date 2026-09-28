# Logistics Operations Analysis — 3-Year Trucking Dataset (2022-2024)

End-to-end SQL + Python analysis of a trucking company's operations database, covering driver performance, route profitability, fleet utilization, maintenance cost, fuel efficiency, customer revenue, safety incidents, and seasonal trends.

**Dataset:** [Logistics Operations Database — 3-Year Trucking Operations], 14 relational tables covering 2022-01-01 to 2024-12-31.

## Project Overview

- **Database:** MySQL 8.0, 14 tables, ~460K total rows (largest: `fuel_purchases` ~196K rows, `delivery_events` ~171K rows, `trips`/`loads` ~85K rows each)
- **Tools:** MySQL, Python (pandas, SQLAlchemy, matplotlib)
- **Scope:** database design (schema + FKs), data import/cleaning, and analysis across 8 business use cases

## Entity-Relationship Overview

```
customers ─┐
routes ────┼──> loads ──> trips ──┬──> fuel_purchases
           │                      ├──> delivery_events ──> facilities
drivers ───┼──────────────────────┤──> safety_incidents
trucks ────┼──────────────────────┴──> maintenance_records
trailers ──┘

driver_monthly_metrics   (aggregated, driver_id + month)
truck_utilization_metrics (aggregated, truck_id + month)
```

Full table-by-table schema description: [`data/DATABASE_SCHEMA.txt`](data/DATABASE_SCHEMA.txt)

## Repository Structure

```
├── data/                          # source CSVs + schema description
├── sql/
│   ├── 01_schema.sql              # CREATE DATABASE + all 14 tables, FKs, indexes
│   ├── 02_load_data.sql           # LOAD DATA LOCAL INFILE import script
│   └── 03_analysis_queries.sql    # analysis queries, organized by use case
├── notebook/
│   └── logistics_analysis.ipynb   # runs the queries via SQLAlchemy, visualizes, summarizes findings
└── README.md
```

## How to Reproduce

1. **Create the database and tables**
   ```
   mysql -u root -p < sql/01_schema.sql
   ```

2. **Import the data**
   - Open `sql/02_load_data.sql` and replace `C:/path/to/your/data` with the absolute path to this repo's `data/` folder (forward slashes, even on Windows).
   - Enable local file loading (once): `SET GLOBAL local_infile = 1;` on the server, and in MySQL Workbench: *Edit > Preferences > SQL Editor > Allow LOAD LOCAL INFILE* (then reconnect).
   - Run the script:
     ```
     mysql --local-infile=1 -u root -p logistics_ops < sql/02_load_data.sql
     ```
   - The script ends with a row-count check — compare against the expected counts listed in the file's comments to confirm a clean import.

3. **Run the analysis queries directly in MySQL** (optional)
   ```
   mysql -u root -p logistics_ops < sql/03_analysis_queries.sql
   ```

4. **Run the notebook**
   ```
   pip install pandas sqlalchemy pymysql matplotlib
   jupyter notebook notebook/logistics_analysis.ipynb
   ```
   Update the MySQL credentials in the first code cell (`USER`, `PASSWORD`, `HOST`, `DATABASE`) before running.

## Analysis Use Cases

| # | Use case | Key question |
|---|----------|---------------|
| 1 | Driver performance | Who's most efficient — revenue/mile, MPG, on-time rate? |
| 2 | Route profitability | Which lanes generate the best margin per mile? |
| 3 | Fleet utilization | Which trucks generate the most revenue per mile driven? |
| 4 | Maintenance analysis | What's the cost-per-mile and downtime impact by truck/type? |
| 5 | Fuel efficiency | How does MPG and fuel cost trend over time and by region? |
| 6 | Customer analysis | Which customers/contract types drive the most revenue? |
| 7 | Safety metrics | What's the incident rate, and how much is preventable? |
| 8 | Seasonal patterns | How do load volume and rates move across months/years? |

## Key Findings

- **Total revenue:** ~USD 262.5M across ~85,400 loads (2022-2024); revenue is essentially flat year-over-year (~USD 87-88M/year) — growth has plateaued.
- **Fleet-wide on-time delivery rate: ~55.7%.** This is spread evenly across drivers rather than concentrated in a few underperformers, pointing to a systemic (scheduling/detention) issue rather than a driver-skill issue.
- **Route profitability spread is wide:** best lanes run ~USD 2.72/mile vs. ~USD 1.48/mile on the weakest (min. 100 loads) — a clear rate-renegotiation target.
- **~37.6% of safety incidents are preventable** — the highest-leverage target for a driver safety program.
- **Maintenance cost is evenly spread** across Preventive, Repair, Tire, Brake, and Engine categories (no single dominant failure mode); Inspection is the smallest cost category.
- Full breakdown and charts: see `notebook/logistics_analysis.ipynb`.

## Data Notes / Caveats

- `trip_status` and `load_status` are constant (`Completed`) across the whole dataset — not usable as filters.
- A small number of `trips`, `fuel_purchases`, and `safety_incidents` rows have missing `driver_id`/`truck_id`/`trailer_id` — handled as `NULL` during import rather than dropped, since the rest of each row is still usable.
- Dates span exactly 2022-01-01 to 2024-12-31 (3 full years, matching the dataset name).

## Author

Ricky Rahardian Bimantara
[LinkedIn](https://linkedin.com/in/rickyrahardianbimantara) · [GitHub](https://github.com/RickyRahardian)
