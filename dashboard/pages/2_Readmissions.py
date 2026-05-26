"""MedFlow — Readmissions Analysis page."""

import streamlit as st
import plotly.express as px

from components.db import query
from components.style import apply_style, page_header, COLORS, PLOTLY_TEMPLATE


st.set_page_config(
    page_title="MedFlow — Readmissions",
    page_icon="🔄",
    layout="wide",
)
apply_style()

page_header(
    title="Readmissions Analysis",
    subtitle="30-day inpatient readmission patterns — a CMS quality metric tied to reimbursement",
    icon="🔄",
)


# ============================================================================
# OVERALL RATE
# ============================================================================
overall = query("""
    select
        count(*) as total_inpatient,
        sum(case when is_30day_readmission then 1 else 0 end) as readmissions,
        round(
            100.0 * sum(case when is_30day_readmission then 1 else 0 end)
            / nullif(count(*), 0), 2
        ) as rate_pct
    from medflow.marts.fct_encounters
    where encounter_class = 'inpatient'
""").iloc[0]

col1, col2, col3 = st.columns(3)
col1.metric("Inpatient Encounters", f"{int(overall['total_inpatient']):,}")
col2.metric("30-Day Readmissions", f"{int(overall['readmissions']):,}")
col3.metric("Readmission Rate", f"{overall['rate_pct']}%")

st.markdown("---")


# ============================================================================
# READMISSION RATE BY CHRONIC STATUS
# ============================================================================
st.markdown("### Readmission Rate by Chronic Disease Status")
st.markdown(
    "<p style='color: #6B7280;'>Patients with chronic conditions typically have higher readmission risk.</p>",
    unsafe_allow_html=True,
)

chronic_df = query("""
    select
        case when d.has_any_chronic_condition then 'Chronic' else 'Non-Chronic' end as patient_segment,
        d.chronic_condition_count,
        count(*) as inpatient_encounters,
        sum(case when f.is_30day_readmission then 1 else 0 end) as readmissions,
        round(
            100.0 * sum(case when f.is_30day_readmission then 1 else 0 end)
            / nullif(count(*), 0), 2
        ) as readmission_rate_pct
    from medflow.marts.fct_encounters f
    join medflow.marts.dim_patient d on f.patient_id = d.patient_id
    where f.encounter_class = 'inpatient'
    group by 1, 2
    order by 2
""")

if not chronic_df.empty:
    fig = px.bar(
        chronic_df,
        x="chronic_condition_count",
        y="readmission_rate_pct",
        color="patient_segment",
        labels={
            "chronic_condition_count": "Number of Chronic Conditions",
            "readmission_rate_pct": "30-Day Readmission %",
            "patient_segment": "",
        },
        template=PLOTLY_TEMPLATE,
        text="readmission_rate_pct",
        color_discrete_map={"Chronic": COLORS["danger"], "Non-Chronic": COLORS["secondary"]},
    )
    fig.update_traces(texttemplate="%{text}%", textposition="outside")
    fig.update_layout(height=420, yaxis=dict(ticksuffix="%"))
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No readmission data available.")


# ============================================================================
# READMISSION TREND
# ============================================================================
st.markdown("### Monthly Readmission Trend")

trend_df = query("""
    select
        date_trunc('month', encounter_start_at)::date as month,
        count(*) as inpatient_encounters,
        sum(case when is_30day_readmission then 1 else 0 end) as readmissions,
        round(
            100.0 * sum(case when is_30day_readmission then 1 else 0 end)
            / nullif(count(*), 0), 2
        ) as readmission_rate_pct
    from medflow.marts.fct_encounters
    where encounter_class = 'inpatient'
      and encounter_start_at >= '2010-01-01'
    group by month
    order by month
""")

if not trend_df.empty:
    fig2 = px.line(
        trend_df,
        x="month",
        y="readmission_rate_pct",
        labels={"month": "", "readmission_rate_pct": "Readmission %"},
        template=PLOTLY_TEMPLATE,
        markers=True,
    )
    fig2.update_traces(line=dict(color=COLORS["danger"], width=2))
    fig2.add_hline(
        y=15, line_dash="dash", line_color=COLORS["neutral"],
        annotation_text="CMS benchmark: 15%",
        annotation_position="top right",
    )
    fig2.update_layout(height=400, yaxis=dict(ticksuffix="%"))
    st.plotly_chart(fig2, use_container_width=True)


# ============================================================================
# READMISSION BY DEMOGRAPHIC
# ============================================================================
st.markdown("### Readmission Rate by Age Bracket + Gender")

demo_df = query("""
    select
        d.age_bracket,
        d.gender,
        count(*) as inpatient_encounters,
        round(
            100.0 * sum(case when f.is_30day_readmission then 1 else 0 end)
            / nullif(count(*), 0), 2
        ) as readmission_rate_pct
    from medflow.marts.fct_encounters f
    join medflow.marts.dim_patient d on f.patient_id = d.patient_id
    where f.encounter_class = 'inpatient'
    group by 1, 2
    order by 1, 2
""")

if not demo_df.empty:
    fig3 = px.bar(
        demo_df,
        x="age_bracket",
        y="readmission_rate_pct",
        color="gender",
        barmode="group",
        labels={
            "age_bracket": "Age Bracket",
            "readmission_rate_pct": "Readmission %",
            "gender": "Gender",
        },
        template=PLOTLY_TEMPLATE,
    )
    fig3.update_layout(height=400, yaxis=dict(ticksuffix="%"))
    st.plotly_chart(fig3, use_container_width=True)