# MedFlow

> Production-grade healthcare analytics platform demonstrating the modern data stack — from ingestion through transformation, orchestration, quality monitoring, and self-service BI.

![Status](https://img.shields.io/badge/status-in--progress-orange)
![Stack](https://img.shields.io/badge/stack-modern--data--stack-blue)
![Python](https://img.shields.io/badge/python-3.12-blue)
![dbt](https://img.shields.io/badge/dbt-core-orange)
![Snowflake](https://img.shields.io/badge/snowflake-trial-blue)

## What this project demonstrates

- **End-to-end analytics engineering**: synthetic patient + claims data flows from raw CSV through staging, intermediate, and dimensional marts into a Streamlit + Power BI experience
- **Production patterns**: data quality testing, lineage documentation, orchestration with retries and alerting, infrastructure as code, and CI/CD on every pull request
- **Warehouse-agnostic design**: identical pipeline runs on Snowflake or DuckDB/MotherDuck via a single config switch — showcases pragmatic tradeoffs between enterprise warehouses and lakehouse alternatives

## Architecture

> _Architecture diagram coming end of Week 1_

**Data flow**: Synthea synthetic patient data + CMS public datasets → `dlt` ingestion → Snowflake `RAW` schema → `dbt` staging models → intermediate models → dimensional marts (star schema) → Streamlit dashboard + Power BI reports

**Orchestration**: Dagster jobs schedule dlt + dbt runs with retries, alerting, and failure isolation
**Quality**: dbt tests + Elementary observability + Great Expectations checks
**CI/CD**: GitHub Actions runs dbt build + test on every PR with results posted as PR comments
**Infra**: Terraform manages Snowflake roles, warehouses, and databases

## Tech Stack

| Layer | Tool |
|---|---|
| Ingestion | dlt (data load tool) |
| Warehouse | Snowflake + DuckDB/MotherDuck |
| Transformation | dbt Core |
| Orchestration | Dagster |
| Data Quality | dbt tests + Elementary + Great Expectations |
| BI | Streamlit, Power BI |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Language | Python 3.12 |

## Dataset

Synthetic patient records from [Synthea](https://synthea.mitre.org/) (MITRE Corporation) — 1,000 synthetic patients with complete medical histories spanning encounters, conditions, medications, procedures, observations, and care plans. No real PHI. Augmented with public CMS Medicare provider utilization data.

**Scale at a glance:**
- _Fill in after Day 1 exploration_

## Project Structure

medflow/
├── ingestion/          # dlt pipelines (Synthea, CMS)
├── transformation/     # dbt project (staging → intermediate → marts)
├── orchestration/      # Dagster assets and jobs
├── dashboard/          # Streamlit analytics app
├── infra/              # Terraform for Snowflake resources
├── tests/              # End-to-end pipeline tests
├── docs/               # Architecture diagram, ADRs, screenshots
└── .github/workflows/  # CI/CD pipelines

## Quick Start

```bash
# Clone
git clone https://github.com/DaminiRastogi11/medflow.git
cd medflow

# Install dependencies (uses uv)
uv sync

# Configure
cp .env.example .env
# Edit .env with your Snowflake or MotherDuck credentials

# Download Synthea sample data to data/raw/synthea/
# Get it from: https://synthea.mitre.org/downloads

# Ingest
uv run python ingestion/synthea_pipeline.py

# Transform
cd transformation/medflow_dbt
uv run dbt build
```

## Roadmap

- **Week 1** ✅ Foundation, ingestion, dimensional model
- **Week 2** ⏳ Data quality, orchestration, Terraform, CI/CD
- **Week 3** ⏳ Streamlit + Power BI dashboards, deployment, blog post

## Status

🚧 **Building in public** — follow along on [LinkedIn](https://www.linkedin.com/in/damini-rastogi/) (handle TBD)

Day 1 complete: project scaffold, dependencies, data acquired and validated.

## License

MIT

**Scale at a glance:**
- 18 source CSV files (~58 MB raw)
- 193,257 total rows across all entities
- 106 patients with 4,930 encounters (~46 encounters per patient avg)
- 63,427 clinical observations (labs, vitals, measurements)
- 3,506 conditions · 3,579 medications · 14,285 procedures
- 8,509 insurance claims with 84,359 line-item transactions
- Full longitudinal medical histories spanning births through deaths