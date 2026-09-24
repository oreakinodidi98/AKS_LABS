"""Caldova Clinical material inventory page."""

from __future__ import annotations

import html
import json
import os
from datetime import date
from typing import TypedDict
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

import streamlit as st


class Material(TypedDict):
    """Inventory material returned by the clinical API."""

    id: int
    name: str
    category: str
    lot_number: str
    quantity: int
    unit: str
    status: str
    location: str
    expiry_date: str
    image_url: str


API_URL = os.getenv("CALDOVA_API_URL", "http://127.0.0.1:8000")


@st.cache_data(ttl=30, show_spinner=False)
def load_materials() -> list[Material]:
    """Load the current inventory from the FastAPI service."""

    try:
        with urlopen(f"{API_URL}/materials", timeout=5) as response:  # noqa: S310
            payload = json.load(response)
    except (HTTPError, URLError, TimeoutError) as exc:
        raise RuntimeError(
            f"The clinical API at {API_URL} is unavailable. Start FastAPI and try again."
        ) from exc

    if not isinstance(payload, list):
        raise RuntimeError("The clinical API returned an unexpected inventory response.")

    return payload


def escape(value: object) -> str:
    """Escape a value before inserting it into custom HTML."""

    return html.escape(str(value), quote=True)


def format_expiry(value: str) -> str:
    """Format an ISO date for the inventory card."""

    return date.fromisoformat(value).strftime("%b %d, %Y")


def render_material_card(material: Material) -> None:
    """Render one clinical material as a compact inventory card."""

    status_class = material["status"].lower().replace(" ", "-")
    st.markdown(
        f"""
        <article class="material-card">
          <div class="material-image" style="background-image:url('{escape(material['image_url'])}')">
            <span class="stock-badge {escape(status_class)}">{escape(material['status'])}</span>
          </div>
          <div class="material-body">
            <p class="material-category">{escape(material['category'])}</p>
            <h3>{escape(material['name'])}</h3>
            <p class="quantity"><strong>{material['quantity']:,}</strong> {escape(material['unit'])} available</p>
            <dl>
              <div><dt>Lot</dt><dd>{escape(material['lot_number'])}</dd></div>
              <div><dt>Expires</dt><dd>{escape(format_expiry(material['expiry_date']))}</dd></div>
              <div><dt>Location</dt><dd>{escape(material['location'])}</dd></div>
            </dl>
          </div>
          <div class="card-action">View material <span>&rarr;</span></div>
        </article>
        """,
        unsafe_allow_html=True,
    )


def apply_styles() -> None:
    """Apply the Caldova clinical workspace visual system."""

    st.markdown(
        """
        <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@600;700&display=swap');
        :root { --ink:#17312e; --green:#1e5a50; --deep:#153f3a; --line:#d9e1dc; --muted:#667873; --coral:#cf654d; }
        html, body, [class*="css"] { font-family:'DM Sans',sans-serif; color:var(--ink); }
        .stApp { background:#f2f5f2; }
        [data-testid="stSidebar"] { background:var(--deep); border-right:0; }
        [data-testid="stSidebar"] * { color:#d8e7e3; }
        [data-testid="stSidebar"] h1 { color:white; font:700 25px 'Manrope'; margin-bottom:0; }
        [data-testid="stSidebar"] h1 + div p { color:#9abbb3; font-size:10px; letter-spacing:2px; }
        [data-testid="stSidebar"] .stRadio label { padding:9px 10px; border-radius:6px; }
        [data-testid="stSidebar"] .stRadio label:has(input:checked) { background:#f3ca7c; }
        [data-testid="stSidebar"] .stRadio label:has(input:checked) p { color:var(--deep); font-weight:700; }
        .block-container { max-width:1440px; padding:2.4rem 3.2rem 4rem; }
        .eyebrow { color:#a24b38; font-size:11px; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; margin:0 0 8px; }
        .page-title { color:var(--ink); font:700 40px 'Manrope'; letter-spacing:0; margin:0; }
        .subtitle { color:var(--muted); font-size:14px; margin:8px 0 26px; }
        [data-testid="stMetric"] { background:white; border:1px solid var(--line); padding:16px 20px; min-height:96px; }
        [data-testid="stMetricLabel"] p { color:var(--muted); font-size:12px; }
        [data-testid="stMetricValue"] { color:var(--ink); font:700 25px 'Manrope'; }
        .material-card { background:white; border:1px solid var(--line); margin:8px 0 14px; min-height:420px; display:flex; flex-direction:column; }
        .material-image { position:relative; height:172px; background-size:cover; background-position:center; }
        .stock-badge { position:absolute; top:13px; left:13px; padding:6px 9px; border-radius:4px; background:#e2f1e9; color:#236447; font-size:9px; font-weight:700; text-transform:uppercase; letter-spacing:.5px; }
        .stock-badge.low-stock { background:#fff2d4; color:#8c6114; }
        .stock-badge.reorder { background:#f9dfd8; color:#a64734; }
        .material-body { padding:19px 20px 13px; flex:1; }
        .material-category { color:#a4513f; font-size:9px; font-weight:700; letter-spacing:1px; text-transform:uppercase; margin:0 0 7px; }
        .material-body h3 { color:var(--ink); font:700 17px/1.3 'Manrope'; letter-spacing:0; min-height:44px; margin:0; }
        .quantity { color:var(--muted); font-size:10px; margin:15px 0; }
        .quantity strong { color:var(--ink); font:700 22px 'Manrope'; margin-right:5px; }
        dl { border-top:1px solid #e8ece9; margin:0; padding-top:10px; }
        dl div { display:flex; justify-content:space-between; gap:10px; padding:4px 0; font-size:10px; }
        dt { color:var(--muted); } dd { color:#344b47; font-weight:600; margin:0; text-align:right; }
        .card-action { border-top:1px solid var(--line); color:var(--green); display:flex; justify-content:space-between; padding:12px 20px; font-size:11px; font-weight:700; }
        .validation { background:#f6faf7; border-left:3px solid var(--green); color:var(--green); font-size:12px; padding:13px 16px; margin:12px 0 20px; }
        @media (max-width:760px) { .block-container { padding:1.5rem 1rem 3rem; } .page-title { font-size:30px; } }
        </style>
        """,
        unsafe_allow_html=True,
    )


def render_home() -> None:
    """Render the Caldova inventory workspace."""

    st.set_page_config(page_title="Caldova Clinical", page_icon="C", layout="wide")
    apply_styles()

    with st.sidebar:
        st.title("Caldova")
        st.caption("CLINICAL")
        st.markdown("#### Workspace")
        st.radio(
            "Workspace navigation",
            [
                "Overview",
                "Material inventory",
                "Clinical studies",
                "Quality review",
                "Locations",
                "Access control",
            ],
            index=1,
            label_visibility="collapsed",
        )
        st.markdown("---")
        st.caption("Validated environment")

    st.markdown('<p class="eyebrow">Clinical operations</p>', unsafe_allow_html=True)
    st.markdown('<h1 class="page-title">Material inventory</h1>', unsafe_allow_html=True)
    st.markdown(
        '<p class="subtitle">Track clinical materials, storage locations, and supply status across active studies.</p>',
        unsafe_allow_html=True,
    )

    try:
        materials = load_materials()
    except RuntimeError as exc:
        st.error(str(exc))
        st.stop()

    metric_columns = st.columns(4)
    metric_columns[0].metric("Cataloged materials", len(materials))
    metric_columns[1].metric(
        "Ready to dispense",
        sum(item["status"] == "In stock" for item in materials),
    )
    metric_columns[2].metric(
        "Need attention",
        sum(item["status"] != "In stock" for item in materials),
    )
    metric_columns[3].metric("Inventory state", "Verified")
    st.markdown(
        '<div class="validation">Last inventory reconciliation completed today at 08:42.</div>',
        unsafe_allow_html=True,
    )

    filter_columns = st.columns([3, 1])
    query = filter_columns[0].text_input(
        "Search inventory",
        placeholder="Search materials, category, or lot",
        label_visibility="collapsed",
    )
    status = filter_columns[1].selectbox(
        "Filter by status",
        ["All statuses", "In stock", "Low stock", "Reorder"],
        label_visibility="collapsed",
    )

    normalized_query = query.strip().casefold()
    filtered_materials = [
        material
        for material in materials
        if normalized_query
        in f"{material['name']} {material['category']} {material['lot_number']}".casefold()
        and (status == "All statuses" or material["status"] == status)
    ]
    st.caption(f"{len(filtered_materials)} results")

    if not filtered_materials:
        st.info("No materials match the current search and status filters.")
        return

    for row_start in range(0, len(filtered_materials), 3):
        columns = st.columns(3)
        for column, material in zip(
            columns,
            filtered_materials[row_start : row_start + 3],
        ):
            with column:
                render_material_card(material)