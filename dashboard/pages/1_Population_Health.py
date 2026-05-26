"""MedFlow — Population Health page."""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import streamlit as st
import plotly.express as px

from components.db import query
from components.style import apply_style, page_header, COLORS, PLOTLY_TEMPLATE


st.set_page_config(
    page_title="MedFlow — Population Health",
    page_icon="🩺",
    layout="wide",
)
apply_style()

page_header(
    title="Population Health",
    subtitle="Chronic disease prevalence across demographic segments",
    icon="🩺",
)


# ============================================================================
# FILTERS
# ============================================================================
panel_df = query("select * from medflow.marts.mart_chronic_disease_panel")

with st.sidebar:
    st.markdown("### Filters")
    selected_age_brackets = st.multiselect(
        "Age Bracket",
        options=panel_df["age_bracket"].unique(),
        default=panel_df["age_bracket"].unique(),
    )
    selected_genders = st.multiselect(
        "Gender",
        options=panel_df["gender"].dropna().unique(),
        default=panel_df["gender"].dropna().unique(),
    )

filtered = panel_df[
    panel_df["age_bracket"].isin(selected_age_brackets)
    & panel_df["gender"].isin(selected_genders)
]


# ============================================================================
# KPI ROW
# ============================================================================
total_patients = int(filtered["patient_count"].sum())
total_chronic = int(filtered[
    [
        "diabetes_count", "hypertension_count", "heart_disease_count",
        "copd_count", "cancer_count", "ckd_count", "mental_health_count",
    ]
].sum().sum())
avg_conditions = filtered["avg_chronic_conditions_per_patient"].mean() if len(filtered) else 0

col1, col2, col3 = st.columns(3)
col1.metric("Patients in Segment", f"{total_patients:,}")
col2.metric("Total Chronic Diagnoses", f"{total_chronic:,}")
col3.metric("Avg Conditions / Patient", f"{avg_conditions:.2f}")

st.markdown("---")


# ============================================================================
# HEATMAP — PREVALENCE BY AGE + GENDER
# ============================================================================
st.markdown("### Disease Prevalence Heatmap")
st.markdown(
    "<p style='color: #6B7280;'>Percent of segment with each condition</p>",
    unsafe_allow_html=True,
)

disease_cols = [
    ("diabetes_prevalence_pct",       "Diabetes"),
    ("hypertension_prevalence_pct",   "Hypertension"),
    ("heart_disease_prevalence_pct",  "Heart Disease"),
    ("copd_prevalence_pct",           "COPD"),
    ("cancer_prevalence_pct",         "Cancer"),
    ("ckd_prevalence_pct",            "CKD"),
    ("mental_health_prevalence_pct",  "Mental Health"),
]

if not filtered.empty:
    heatmap_data = filtered.assign(
        segment=lambda d: d["age_bracket"] + " · " + d["gender"]
    ).set_index("segment")[[c[0] for c in disease_cols]]
    heatmap_data.columns = [c[1] for c in disease_cols]

    fig = px.imshow(
        heatmap_data,
        labels=dict(x="Condition", y="Segment", color="Prevalence %"),
        color_continuous_scale=[
            [0, "#FFFFFF"],
            [0.5, COLORS["secondary"]],
            [1, COLORS["danger"]],
        ],
        aspect="auto",
        text_auto=".1f",
    )
    fig.update_layout(template=PLOTLY_TEMPLATE, height=max(380, 60 * len(heatmap_data)))
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No data for the selected filters.")


# ============================================================================
# DETAIL TABLE
# ============================================================================
st.markdown("### Segment Detail")
st.dataframe(
    filtered.rename(columns={
        "age_bracket":                          "Age Bracket",
        "gender":                               "Gender",
        "patient_count":                        "Patients",
        "diabetes_prevalence_pct":              "Diabetes %",
        "hypertension_prevalence_pct":          "HTN %",
        "heart_disease_prevalence_pct":         "Heart %",
        "copd_prevalence_pct":                  "COPD %",
        "cancer_prevalence_pct":                "Cancer %",
        "ckd_prevalence_pct":                   "CKD %",
        "mental_health_prevalence_pct":         "MH %",
        "avg_chronic_conditions_per_patient":   "Avg Conditions",
        "avg_lifetime_expenses":                "Avg Lifetime $",
    })[[
        "Age Bracket", "Gender", "Patients",
        "Diabetes %", "HTN %", "Heart %", "COPD %", "Cancer %", "CKD %", "MH %",
        "Avg Conditions", "Avg Lifetime $",
    ]],
    use_container_width=True,
    hide_index=True,
)