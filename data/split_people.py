import os
import ast
import psycopg2
from psycopg2.extras import execute_values
import pandas as pd
from dotenv import load_dotenv


def load_data():
    df = pd.read_csv("asset_milestones.csv")

    df["experts"] = df["experts"].apply(lambda x: ast.literal_eval(x) if isinstance(x, str) else []
                                        )
    return df


def connect_to_db():
    load_dotenv()
    return psycopg2.connect(os.environ["DATABASE_URL"])


def split_experts():
    data = load_data()
    exploded = data.explode("experts").dropna(subset=["experts"])
    experts = pd.DataFrame(exploded["experts"].tolist(), index=exploded.index)
    experts["asset_id"] = exploded["asset_id"]

    experts = experts.explode("expert_in").dropna(subset=["expert_in"])
    experts["expert_in"] = experts["expert_in"].str.strip()
    return experts


def upload_data():
    experts = split_experts()
    conn = connect_to_db()

    with conn.cursor() as cur:
        people = experts[["employee_name", "email"]].drop_duplicates()
        execute_values(
            cur,
            "INSERT INTO people (person_name, person_email) VALUES %s ON CONFLICT DO NOTHING",
            list(people.itertuples(index=False, name=None)),
        )

        roles = experts[["expert_in"]].drop_duplicates()
        execute_values(
            cur,
            "INSERT INTO roles (role_name) VALUES %s ON CONFLICT DO NOTHING",
            list(roles.itertuples(index=False, name=None)),
        )

    conn.commit()
    conn.close()


if __name__ == "__main__":
    upload_data()
