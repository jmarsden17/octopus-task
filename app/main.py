import os
from contextlib import contextmanager
from datetime import date
from typing import Optional

import psycopg2
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from psycopg2 import errors
from psycopg2.extras import RealDictCursor

app = FastAPI()
load_dotenv()


@contextmanager
def db():
    conn = psycopg2.connect(
        os.environ["DATABASE_URL"], cursor_factory=RealDictCursor)
    try:
        with conn:
            with conn.cursor() as cur:
                yield cur
    except errors.UniqueViolation as e:
        raise HTTPException(409, f"Already exists ({e.diag.constraint_name})")
    except (errors.CheckViolation, errors.ForeignKeyViolation, errors.NotNullViolation) as e:
        raise HTTPException(409, e.diag.message_primary)
    finally:
        conn.close()


@app.get("/assets")
def list_assets():
    with db() as cur:
        cur.execute("""
            SELECT a.asset_id, a.asset_name,
                   lp.lifecycle_phase_name AS phase, h.start_date::date AS since
            FROM assets a
            LEFT JOIN asset_status_history h
                   ON h.asset_id = a.asset_id AND h.end_date IS NULL
            LEFT JOIN lifecycle_phases lp
                   ON lp.lifecycle_phase_id = h.lifecycle_phase_id
            ORDER BY a.asset_id""")
        return cur.fetchall()


@app.get("/assets/{asset_id}")
def get_asset(asset_id: str):
    with db() as cur:
        cur.execute("""
            SELECT a.asset_id, a.asset_name, a.asset_type_id, at.asset_type_name,
                   a.capacity_mw, p.portfolio_name, t.technology_name,
                   c.company_name, co.country_name
            FROM assets a
            JOIN asset_types at ON at.asset_type_id = a.asset_type_id
            JOIN portfolios p   ON p.portfolio_id   = a.portfolio_id
            JOIN technologies t ON t.technology_id  = a.technology_id
            JOIN companies c    ON c.company_id     = a.company_id
            JOIN countries co   ON co.country_id    = a.country_id
            WHERE a.asset_id = %s""", (asset_id,))
        asset = cur.fetchone()
        if not asset:
            raise HTTPException(404, "Asset not found")

        cur.execute("""
            SELECT am.asset_milestone_id, m.milestone_id, m.milestone_name,
                   mt.milestone_type_name, am.milestone_date::date AS milestone_date
            FROM asset_milestones am
            JOIN milestones m       ON m.milestone_id = am.milestone_id
            JOIN milestone_types mt ON mt.milestone_type_id = am.milestone_type_id
            JOIN sequences s        ON s.sequence_id = m.sequence_id
            WHERE am.asset_id = %s
            ORDER BY s.sequence_name, am.milestone_date""", (asset_id,))
        asset["milestones"] = cur.fetchall()

        cur.execute("""
            SELECT lp.lifecycle_phase_name AS phase,
                   h.start_date::date AS start_date, h.end_date::date AS end_date
            FROM asset_status_history h
            JOIN lifecycle_phases lp ON lp.lifecycle_phase_id = h.lifecycle_phase_id
            WHERE h.asset_id = %s ORDER BY h.start_date""", (asset_id,))
        asset["status_history"] = cur.fetchall()

        cur.execute("""
            SELECT ae.asset_expert_id, pe.person_name, pe.person_email, r.role_name
            FROM asset_experts ae
            JOIN people pe ON pe.person_id = ae.person_id
            JOIN roles r   ON r.role_id = ae.role_id
            WHERE ae.asset_id = %s ORDER BY r.role_name, pe.person_name""", (asset_id,))
        asset["experts"] = cur.fetchall()
        return asset


@app.get("/reference")
def reference():
    """Dropdown data for the frontend."""
    with db() as cur:
        cur.execute("""SELECT m.milestone_id, m.milestone_name, m.asset_type_id
                       FROM milestones m JOIN sequences s ON s.sequence_id = m.sequence_id
                       ORDER BY m.asset_type_id, s.sequence_name""")
        milestones = cur.fetchall()
        cur.execute(
            "SELECT milestone_type_id, milestone_type_name FROM milestone_types ORDER BY 1")
        types = cur.fetchall()
        cur.execute("SELECT role_id, role_name FROM roles ORDER BY role_name")
        roles = cur.fetchall()
        return {"milestones": milestones, "milestone_types": types, "roles": roles}


@app.post("/assets/{asset_id}/milestones")
def add_milestone(asset_id: str, milestone_id: str, milestone_date: str):
    pass


@app.patch("/milestones/{id}")
def update_milestone(id: str, milestone_date: str):
    pass


@app.post("/assets/{asset_id}/experts")
def add_expert(asset_id: str, expert_name: str):
    pass


@app.delete("/experts/{id}")
def delete_expert(id: str):
    pass


app.mount("/", StaticFiles(directory="static", html=True), name="static")
