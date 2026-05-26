"""MedFlow dashboard — shared visual styling."""

import streamlit as st


# Brand colors — clinical but warm
COLORS = {
    "primary":     "#1F4E79",   # deep clinical blue
    "secondary":   "#2E8B8B",   # teal
    "accent":      "#E07A5F",   # warm coral
    "danger":      "#D32F2F",
    "warning":     "#F5A623",
    "success":     "#388E3C",
    "neutral":     "#6B7280",
    "background":  "#FAFAFA",
    "text":        "#1F2937",
}


PLOTLY_TEMPLATE = {
    "layout": {
        "colorway": [
            COLORS["primary"], COLORS["secondary"], COLORS["accent"],
            COLORS["warning"], COLORS["success"], COLORS["danger"],
        ],
        "font": {"family": "Inter, system-ui, -apple-system, sans-serif", "color": COLORS["text"]},
        "title": {"font": {"size": 18, "color": COLORS["text"]}},
        "paper_bgcolor": "rgba(0,0,0,0)",
        "plot_bgcolor": "rgba(0,0,0,0)",
        "xaxis": {"gridcolor": "#E5E7EB", "linecolor": "#E5E7EB"},
        "yaxis": {"gridcolor": "#E5E7EB", "linecolor": "#E5E7EB"},
        "margin": {"l": 40, "r": 20, "t": 50, "b": 40},
    }
}


CUSTOM_CSS = """
<style>
    /* Tighter top padding */
    .block-container { padding-top: 2rem; padding-bottom: 2rem; }

    /* Subtler headings */
    h1 { color: #1F4E79; font-weight: 700; letter-spacing: -0.02em; }
    h2 { color: #1F2937; font-weight: 600; margin-top: 1.5rem; }
    h3 { color: #1F2937; font-weight: 600; }

    /* KPI card style */
    [data-testid="stMetric"] {
        background-color: #FFFFFF;
        border: 1px solid #E5E7EB;
        padding: 1rem 1.25rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
    }
    [data-testid="stMetricLabel"] {
        font-size: 0.85rem;
        color: #6B7280;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }
    [data-testid="stMetricValue"] {
        font-size: 1.75rem;
        color: #1F4E79;
        font-weight: 700;
    }

    /* Reduce sidebar visual noise */
    section[data-testid="stSidebar"] > div { padding-top: 1.5rem; }

    /* Hide Streamlit's default footer/menu */
    footer { visibility: hidden; }
    #MainMenu { visibility: hidden; }
</style>
"""


def apply_style():
    """Apply the MedFlow visual identity to the current Streamlit page."""
    st.markdown(CUSTOM_CSS, unsafe_allow_html=True)


def page_header(title: str, subtitle: str | None = None, icon: str | None = None):
    """Render a consistent page header."""
    if icon:
        st.markdown(f"# {icon} {title}")
    else:
        st.markdown(f"# {title}")
    if subtitle:
        st.markdown(
            f"<p style='color: #6B7280; margin-top: -0.5rem; margin-bottom: 1.5rem;'>{subtitle}</p>",
            unsafe_allow_html=True,
        )