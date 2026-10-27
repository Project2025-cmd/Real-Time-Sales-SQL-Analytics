## 🛠️ Step-by-Step Execution Guide

To replicate or run this analytics engine locally, follow these sequential steps:

### Phase 1: Environment Setup & Data Pipeline Injection
1. Open **Google Colab** and initialize your runtime engine.
2. Execute the synthetic stream generator Python pipeline script (`pipeline.py`) to simulate transaction ledgers.
3. Once calculations finish, download the aggregated operational logs using the automatic browser download snippet:
   ```python
   from google.colab import files
   files.download('sales_revenue_report.csv')
   ```

### Phase 2: Relational Database Configuration
1. Open your native SQL client (e.g., **MySQL Workbench**).
2. Execute the database initialization block to stand up the `sales_analytics_master` tablespace container.
3. Right-click on the `sales_analytics_master` schema tree branch and initiate the **Table Data Import Wizard**.
4. Path the engine directly to your downloaded `sales_revenue_report.csv` file, accept default column mappings, and execute the bulk import pipeline.
5. Verify successful database ingestion:
   ```sql
   SELECT COUNT(*) FROM sales_analytics_master;
   ```

### Phase 3: Generating Executive Analytics
1. Run the `Live Executive Revenue Dashboard Workflow` query within your client to render trailing windows, running totals, and growth matrices.
2. Execute the deep-dive context matrices (`Hourly Traffic`, `Market Basket Models`, and `Churn Predictors`) to parse enterprise operational health.

---

## 📊 Business Intelligence Technical Stack
- **Data Engineering Engine:** Python (Pandas, Psycopg2 ecosystem)
- **Analytical Storage Sandbox:** MySQL Relational Infrastructure (B-Tree indexing architectures)
- **Analytical Modeling Logic:** Window aggregates (`SUM OVER`), temporal lookups (`LAG`), and dynamic data classification matrix transformations (`NTILE` workflows)
- **Deployment Interface:** Google Colab Framework & Localized MySQL Enterprise Environments
