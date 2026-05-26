"""
MedFlow dashboard — database connection layer.

Centralizes the MotherDuck connection so individual pages stay focused
on presentation logic. Uses Streamlit's caching to avoid re-querying
on every interaction.
"""

import os
from pathlib import Path

import duckdb
import pandas as pd
import streamlit as st
from dotenv import load_dotenv

# Load .env from project root
project_root = Path(__file__).parent.parent.parent
load_dotenv(project_root / ".env")


def _get_motherduck_token() -> str:
    """
    Resolve the MotherDuck token from one of two sources:
    1. Streamlit secrets (when deployed to Streamlit Community Cloud)
    2. Environment variable from .env (when running locally)
    """
    try:
        return st.secrets["motherduck"]["token"]
    except (KeyError, FileNotFoundError, AttributeError):
        token = os.getenv("MOTHERDUCK_TOKEN")
        if not token:
            st.error(
                "MOTHERDUCK_TOKEN not set. Add it to `.env` for local dev "
                "or to Streamlit secrets for cloud deployment."
            )
            st.stop()
        return token


@st.cache_resource(show_spinner=False)
def get_connection() -> duckdb.DuckDBPyConnection:
    """Return a cached MotherDuck connection (one per Streamlit session)."""
    token = _get_motherduck_token()
    conn_str = f"md:medflow?motherduck_token={token}"
    return duckdb.connect(conn_str, read_only=True)


@st.cache_data(ttl=300, show_spinner=False)
def query(sql: str) -> pd.DataFrame:
    """
    Execute a SQL query against MotherDuck and return a DataFrame.
    Cached for 5 minutes — perfect for dashboard responsiveness.
    """
    conn = get_connection()
    return conn.execute(sql).df()


# Convenience: pre-baked queries used across pages
def get_kpis() -> dict:
    """Return top-level KPIs for the executive overview."""
    df = query("""
        select
            (select count(*) from medflow.marts.dim_patient)            as total_patients,
            (select count(*) from medflow.marts.fct_encounters)         as total_encounters,
            (select round(sum(total_claim_cost), 0)
             from medflow.marts.fct_encounters)                         as total_billed,
            (select round(
                100.0 * sum(case when is_30day_readmission then 1 else 0 end)
                / nullif(count(*), 0), 2)
             from medflow.marts.fct_encounters
             where encounter_class = 'inpatient')                       as readmission_rate_pct,
            (select count(*) from medflow.marts.dim_patient
             where has_any_chronic_condition)                           as chronic_patient_count
    """)
    return df.iloc[0].to_dict()