"""MedFlow — Provider Scorecard page."""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import streamlit as st
import plotly.express as px

from components.db import query
from components.style import apply_style, page_header, COLORS, PLOTLY_TEMPLATE


st.set_page_config(
    page_title="MedFlow — Provider Scorecard",
    layout="wide",
)
apply_style()

page_header(
    title="Provider Scorecard",
    subtitle="Provider Performance Metrics",
)


# ============================================================================
# DATA
# ============================================================================
df = query("""
    select
        provider_id,
        provider_name,
        specialty,
        organization_name,
        total_encounters,
        unique_patients_seen,
        inpatient_encounters,
        emergency_encounters,
        ambulatory_encounters,
        readmissions_caused,
        readmission_rate_pct,
        total_billed,
        avg_claim_cost_per_encounter,
        avg_encounter_duration_minutes,
        volume_rank,
        revenue_rank,
        quality_rank_low_readmit
    from medflow.marts.mart_provider_utilization_scorecard
    where total_encounters > 0
    order by volume_rank
""")

# ============================================================================
# FILTERS
# ============================================================================
with st.sidebar:
    st.markdown("### Filters")
    specialties = st.multiselect(
        "Specialty",
        options=sorted(df["specialty"].dropna().unique()),
        default=sorted(df["specialty"].dropna().unique()),
    )
    min_volume = st.slider(
        "Minimum Encounters",
        min_value=0,
        max_value=int(df["total_encounters"].max()),
        value=0,
        step=5,
    )

filtered = df[df["specialty"].isin(specialties) & (df["total_encounters"] >= min_volume)]


# ============================================================================
# KPI ROW
# ============================================================================
col1, col2, col3, col4 = st.columns(4)
col1.metric("Providers", f"{len(filtered):,}")
col2.metric("Total Encounters", f"{int(filtered['total_encounters'].sum()):,}")
col3.metric("Total Billed", f"${filtered['total_billed'].sum()/1e6:.2f}M")
avg_readmit = filtered["readmission_rate_pct"].dropna().mean() if len(filtered) else 0
col4.metric("Avg Readmission %", f"{avg_readmit:.1f}%" if avg_readmit else "—")

st.markdown("---")


# ============================================================================
# VOLUME VS REVENUE SCATTER (outlier detection)
# ============================================================================
st.markdown("### Volume vs Revenue")
st.markdown(
    "<p style='color: #6B7280;'>Bubble size represents patient count.</p>",
    unsafe_allow_html=True,
)

if not filtered.empty:
    fig = px.scatter(
        filtered,
        x="total_encounters",
        y="total_billed",
        size="unique_patients_seen",
        color="specialty",
        hover_name="provider_name",
        hover_data={
            "specialty": True,
            "readmission_rate_pct": ":.2f",
            "total_billed": ":$,.0f",
        },
        labels={
            "total_encounters": "Total Encounters",
            "total_billed": "Total Billed ($)",
        },
        template=PLOTLY_TEMPLATE,
    )
    fig.update_layout(height=500, legend=dict(orientation="v"))
    st.plotly_chart(fig, use_container_width=True)


# ============================================================================
# TABLE
# ============================================================================
st.markdown("### Provider Detail")

st.dataframe(
    filtered[[
        "volume_rank", "provider_name", "specialty", "organization_name",
        "total_encounters", "unique_patients_seen",
        "inpatient_encounters", "emergency_encounters", "ambulatory_encounters",
        "readmission_rate_pct", "total_billed", "avg_claim_cost_per_encounter",
    ]].rename(columns={
        "volume_rank": "Rank",
        "provider_name": "Provider",
        "specialty": "Specialty",
        "organization_name": "Organization",
        "total_encounters": "Encounters",
        "unique_patients_seen": "Patients",
        "inpatient_encounters": "Inpatient",
        "emergency_encounters": "ED",
        "ambulatory_encounters": "Ambulatory",
        "readmission_rate_pct": "Readmit %",
        "total_billed": "Billed",
        "avg_claim_cost_per_encounter": "Avg Cost",
    }),
    use_container_width=True,
    hide_index=True,
    column_config={
        "Billed": st.column_config.NumberColumn(format="$%.0f"),
        "Avg Cost": st.column_config.NumberColumn(format="$%.0f"),
        "Readmit %": st.column_config.NumberColumn(format="%.1f%%"),
    },
)