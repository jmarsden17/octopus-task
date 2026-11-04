# Design decisions

## How to build and run

1. Install requirements:
``` bash
pip install -r requirements.txt
```

2. Create `.env` file:
``` bash
touch .env
```

3. Copy these values into the `.env` file:

POSTGRES_USER=techtest
POSTGRES_PASSWORD=techtest
POSTGRES_DB=assets
POSTGRES_PORT=5432
DATABASE_URL=postgresql://techtest:techtest@localhost:5432/assets

### Set up and seed database
1. In your terminal run 
``` bash
docker compose up -d
```

2. To set up the raw data tables:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/schema.sql
```

3. To seed the raw data tables:
First run:
``` bash
psql postgresql://techtest:techtest@localhost:5432/assets
```
to enter postgres. 
Then, inside the postgres terminal run:
``` bash
\copy raw_asset_milestones FROM 'data/asset_milestones.csv' WITH (FORMAT CSV, HEADER TRUE);
```
and then run:
``` bash
\copy raw_milestone_sequence FROM 'data/milestone_sequence.csv' WITH (FORMAT CSV, HEADER TRUE);
```

4. Exit postgres with `\q`

5. Set up the triggers and functions by running:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/asset_history.sql
```
do this first so the history table fills out when seeding the data.

6. Seed the normalised tables with:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/seed_normalized.sql
```

### Run demo asset_history function
1. Carry out 'Set up and seed database' instructions

2. In the terminal run:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/asset_history_demo.sql
```
The example will show in the terminal.

### Set up and run app
1. Carry out 'Set up and seed database' instructions

2. In the terminal run:
``` bash
cd app
```
to enter the app folder.

3. Run in the terminal:
``` bash
uvicorn main:app --reload 
```
4. Navigate to:
``` bash
http://127.0.0.1:8000 
```
using either the link in the terminal or your own browser.

5. To close the app press CTRL+C

### Deleting the database
1. To delete the database enter:
``` bash
docker compose down -v
```
in the terminal.

## Data model
![alt text](erd.png)


## Status from milestones
- `rebuild_asset_status_history(asset_id)` rebuilds one asset's status history from
its Actual milestones. For each Actual milestone date, it finds the highest
sequence reached by that date and uses that milestone's lifecycle phase. It ignores the Forecast and Baseline milestones as required.

- Each period's has a `start_date` and `end_date`, and the current period has a `NULL` end date. The `asset_status_as_of(asset_id, as_of_date)` function uses those boundaries to
return the phase and its start date for the requested date, or no row if there is no
Actual milestone for that asset by then.

- The `asset_milestones_sync` AFTER trigger rebuilds the asset history after an insert,
update, or delete. If an update moves a milestone to another asset, it rebuilds
both assets histories. The `asset_milestones_no_future_actual` BEFORE trigger
raises an error if an Actual milestone is dated after `CURRENT_DATE`, though Forecast and Baseline dates are allowed to be in the future.

- `sql/asset_history_demo.sql` shows the trigger using an Actual asset,
`ASST_INFR_1073`, dated `2026-08-13`. The history changes from In Construction to
Operational at that date. Deleting the test milestone rebuilds the history back
to In Construction. The script prints the history before insertion, after
insertion, and after deletion. 

## Functions, views and indexes
- I would have liked to build some indexes and views to make querying easier and quicker for users if I had more time.
- The main functions I built were for the asset history table.

## The app
Usable endpoints are as follows:

| Method | Route | Purpose |
|---|---|---|
| GET | `/assets` | List assets with their current phase |
| GET | `/assets/{asset_id}` | One asset's details, milestones, status history and experts |
| POST | `/assets/{asset_id}/milestones` | Record a milestone |
| PATCH / DELETE | `/milestones/{id}` | Correct or delete a milestone |
| POST | `/assets/{asset_id}/experts` | Assign a person to a role |
| DELETE | `/experts/{id}` | Remove an assignment |

I used a HTML interface, as it was a simple and basic way to get a working interface. I did not have much time left, so I did not want to overcomplicate things.

## Data issues

- The raw csv uses `null` for missing data. I preserved the raw tables, then used `NULLIF` during normalization so these become SQL `NULL`. I didn't want to guess any missing data values, so would flag these null values.
- I used`SELECT DISTINCT` to remove duplicates when inserting normalized asset milestones and expert assignments.
- The milestone timestamps contain time components, but the model only needs dates. I cast the timestamps through `TIMESTAMPTZ`, then stored a `DATE`.
- The Platform event uses `First Transaction` as its source milestone ID, while the reference list uses `LIFE_MILE_1000`. I set the milestone name to 'First Transation', so the tables are consistent.
- I kept the infrastructure that had a capacity of zero. Again, I would also flag these values to a future user.
- Missing experts were not added in by me, I left these blank for a team member in the know to fill in with the API.
- The sequence value `10` occurs for both Infrastructure and Platform milestones. I kept this as other data like milestone name keeps these from overlapping.

## Assumptions
- The instructions said data should be 'normalised' so I used a 3NF style data model, rather than a star schema.
- Sequence numbers will not go beyond 90 or under 10.
- There is no expectation for me to correct or fill in any null values.
- Expert assignments that are missing are not my task to fill in.

## How you used AI tools
- I used VS Copilot and Cluade for this.
- Step 1 and 2: I mainly used AI to verify my ERD design.
- Step 2: Copilot didn't like that I used the string IDs given in the tables for asset and portfolio IDs, and would have preferred I used these alongside an integer ID generated as an identity. However, I disagreed here as by using strict UNIQUE and NOT NULL constraints the risk of a data integrity error is low, and it reduces overhead and complexity by not adding a second ID for each asset and portfolio to track and record.
- Step 3: I utilised Claude for step 3 quite significantly, as I haven't used SQL triggers before and have only used functions a few times. I mainly used it as a learning tool and to jog my memory around functions, though it was very helpful for the more complex syntax around the cascading CTEs, BEGIN - END statements, void returns and trigger command designs.
- Step 4 backend: I also used Claude a lot in this section. While FastAPI is similar, we used Flask for API design at Sigma Labs so Claude was really helpful in pointing out syntax differences and how to use Pydantic models here. I used agentic AI for the backend design, as I am pretty confident in writing and reviewing the endpoint Python and SQL queries. I reviewed what it produced and was happy with the output.
- Step 4 frontend: I used Claude here to generate a boilerplate HTML script to display the data. I was running very low on time and went with simple functionality over aesthetics.

## What you'd do with more time
- I would like to improve the frontend design, and add some more endpoints to the app. I feel this section is the one that suffered most due to the time constraints I was under.
- I would also have added views and indexes to the database. There are a lot of tables in there and I feel for business analysis some more work would need to be done before this was ready, as linking certain tables together here would take some complex join queries.
- The extension tasks would also be good additons to this project - especially some testing around the API endpoints.

## What you learned / researched

- SQL triggers were new to me coming into this, I am glad that they were included in this task since they seem like really powerful commands that would have a lot of uses.
- I know that FastAPI is a more popular tool than Flask, so I was happy to do some research there.
- Using ->> and json_array_elements to break down JSONs in CSVs was interesting to learn about.
- Learning how the industry uses and structures milestones, lifecycle phases and different types of assets was really interesting and informative.