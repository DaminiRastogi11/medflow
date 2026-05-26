"""
MedFlow — Executive Overview (landing page).

High-level KPIs and trends for hospital leadership and care quality teams.
"""

"""
MedFlow — Executive Overview (landing page).
...
"""

import sys
from pathlib import Path

# Ensure dashboard/ is on the Python path so we can import from components/
sys.path.insert(0, str(Path(__file__).parent))


import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

from components.db import query, get_kpis
from components.style import apply_style, page_header, COLORS, PLOTLY_TEMPLATE


# ============================================================================
# PAGE CONFIG
# ============================================================================
st.set_page_config(
    page_title="MedFlow — Executive Overview",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded",
)
apply_style()


# ============================================================================
# HEADER
# ============================================================================
page_header(
    title="MedFlow",
    subtitle="Healthcare analytics platform — executive overview",
    icon="🏥",
)


# ============================================================================
# KPI ROW
# ============================================================================
kpis = get_kpis()

col1, col2, col3, col4, col5 = st.columns(5)
with col1:
    st.metric("Patients", f"{int(kpis['total_patients']):,}")
with col2:
    st.metric("Encounters", f"{int(kpis['total_encounters']):,}")
with col3:
    billed = kpis.get("total_billed") or 0
    st.metric("Total Billed", f"${billed/1e6:.2f}M")
with col4:
    rate = kpis.get("readmission_rate_pct") or 0
    st.metric("30-Day Readmission", f"{rate}%")
with col5:
    chronic = kpis.get("chronic_patient_count") or 0
    pct_chronic = round(100.0 * chronic / max(kpis["total_patients"], 1), 1)
    st.metric("Chronic Disease Patients", f"{int(chronic):,}", delta=f"{pct_chronic}% of pop.")

st.markdown("---")


# ============================================================================
# ROW 2 — TREND + CHRONIC DISEASE PANEL
# ============================================================================
col_left, col_right = st.columns([3, 2])

with col_left:
    st.markdown("### Encounter Volume Trend")
    st.markdown(
        "<p style='color: #6B7280; margin-top: -0.5rem;'>Monthly encounters across all care settings</p>",
        unsafe_allow_html=True,
    )

    trend_df = query("""
        select
            date_trunc('month', encounter_start_at)::date as month,
            encounter_class,
            count(*) as encounters
        from medflow.marts.fct_encounters
        where encounter_start_at >= '2010-01-01'
        group by month, encounter_class
        order by month
    """)

    fig = px.area(
        trend_df,
        x="month",
        y="encounters",
        color="encounter_class",
        labels={"month": "", "encounters": "Encounters", "encounter_class": "Class"},
        template=PLOTLY_TEMPLATE,
    )
    fig.update_layout(
        height=380,
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        hovermode="x unified",
    )
    st.plotly_chart(fig, use_container_width=True)

with col_right:
    st.markdown("### Chronic Disease Prevalence")
    st.markdown(
        "<p style='color: #6B7280; margin-top: -0.5rem;'>Patients by condition (overlapping)</p>",
        unsafe_allow_html=True,
    )

    chronic_df = query("""
        select
            'Diabetes'      as condition,
            sum(case when has_diabetes then 1 else 0 end) as patient_count
        from medflow.marts.dim_patient
        union all select 'Hypertension',
            sum(case when has_hypertension then 1 else 0 end) from medflow.marts.dim_patient
        union all select 'Heart Disease',
            sum(case when has_heart_disease then 1 else 0 end) from medflow.marts.dim_patient
        union all select 'COPD',
            sum(case when has_copd then 1 else 0 end) from medflow.marts.dim_patient
        union all select 'Active Cancer',
            sum(case when has_active_cancer then 1 else 0 end) from medflow.marts.dim_patient
        union all select 'CKD',
            sum(case when has_chronic_kidney_disease then 1 else 0 end) from medflow.marts.dim_patient
        union all select 'Mental Health',
            sum(case when has_mental_health_condition then 1 else 0 end) from medflow.marts.dim_patient
        order by patient_count desc
    """)

    fig2 = px.bar(
        chronic_df,
        y="condition",
        x="patient_count",
        orientation="h",
        labels={"condition": "", "patient_count": "Patients"},
        template=PLOTLY_TEMPLATE,
    )
    fig2.update_layout(height=380, showlegend=False)
    fig2.update_traces(marker_color=COLORS["primary"])
    st.plotly_chart(fig2, use_container_width=True)


# ============================================================================
# ROW 3 — TOP PROVIDERS
# ============================================================================
st.markdown("---")
st.markdown("### Top Providers by Volume")
st.markdown(
    "<p style='color: #6B7280; margin-top: -0.5rem;'>Highest-utilization clinicians across MedFlow</p>",
    unsafe_allow_html=True,
)

top_providers = query("""
    select
        provider_name,
        specialty,
        organization_name,
        total_encounters,
        unique_patients_seen,
        round(readmission_rate_pct, 1)        as readmission_rate_pct,
        '$' || printf('%,.0f', total_billed)  as total_billed_fmt,
        volume_rank
    from medflow.marts.mart_provider_utilization_scorecard
    order by volume_rank
    limit 10
""")

st.dataframe(
    top_providers,
    use_container_width=True,
    hide_index=True,
    column_config={
        "volume_rank": st.column_config.NumberColumn("Rank", width="small"),
        "provider_name": "Provider",
        "specialty": "Specialty",
        "organization_name": "Organization",
        "total_encounters": st.column_config.NumberColumn("Encounters", format="%d"),
        "unique_patients_seen": st.column_config.NumberColumn("Unique Patients", format="%d"),
        "readmission_rate_pct": st.column_config.NumberColumn("Readmit %", format="%.1f%%"),
        "total_billed_fmt": "Total Billed",
    },
)


# ============================================================================
# FOOTER
# ============================================================================
st.markdown("---")
st.markdown(
    "<p style='color: #6B7280; font-size: 0.85rem; text-align: center;'>"
    "Built with dbt + MotherDuck + Streamlit · "
    "<a href='https://github.com/DaminiRastogi11/medflow' target='_blank'>GitHub</a>"
    "</p>",
    unsafe_allow_html=True,
)