import os
import psycopg2
from psycopg2.extras import execute_values
import pandas as pd
from dotenv import load_dotenv


def load_data():
    return pd.read_csv('asset_milestones.csv')


def split_people():
    data = load_data()
    people = pd.DataFrame(
        data["experts"].explode().dropna().tolist()).drop_duplicates()

    return people


def connect_to_db():
    load_dotenv()
    try:
        conn = psycopg2.connect(
            host=os.environ['DATABASE_URL'],
            dbname=os.environ['POSTGRES_DB'],
            user=os.environ['POSTGRES_USER'],
            password=os.environ['POSTGRES_PASSWORD'],
            port=os.environ['POSTGRES_PORT']
        )
    except Exception as e:
        raise
    return conn


def upload_data():
    data = load_data()
    conn = connect_to_db()
    with conn.cursor() as cur:

        people = split_people()
        execute_values(
            cur,
            "INSERT INTO people (person_name, person_email) VALUES %s ON CONFLICT DO NOTHING",
            list(people.itertuples(index=False, name=None)),
        )

        roles = pd.DataFrame(data["expert_in"].drop_duplicates())
        execute_values(
            cur,
            "INSERT INTO roles (role_name) VALUES %s ON CONFLICT DO NOTHING",
            list(roles.itertuples(index=False, name=None)),
        )

    conn.commit()
