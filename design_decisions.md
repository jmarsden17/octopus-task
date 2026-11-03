# Design decisions

## How to build and run

1. Install requirements:
``` bash
pip install -r requirements.txt
```
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
docker compose exec -T postgres psql -U techtest -d assets < sql/asset_history.sql'
```
do this first so the history table fills out when seeding the data.

6. Seed the normalised tables with:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/seed_normalized.sql'
```

### Run demo asset_history function
1. Carry out 'Set up and seed database' instructions

2. In the terminal run:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/asset_history_demo.sql'
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

5. Usable endpoints are as follows:

| Method | Route | Purpose |
|---|---|---|
| GET | `/assets` | List assets with their current phase |
| GET | `/assets/{asset_id}` | One asset's details, milestones, status history and experts |
| POST | `/assets/{asset_id}/milestones` | Record a milestone |
| PATCH / DELETE | `/milestones/{id}` | Correct or delete a milestone |
| POST | `/assets/{asset_id}/experts` | Assign a person to a role |
| DELETE | `/experts/{id}` | Remove an assignment |

6. To close the app press CTRL+C

### Deleting the database
1. To delete the database enter:
``` bash
docker compose down -v
```
in the terminal.

## Data model
![alt text](erd.png)


## Status from milestones
<!-- How your status history table works, how the trigger keeps it up to date when
     milestones are added, changed or deleted, and how you reject bad milestones.
     Include the trigger example (record a milestone, show the history, delete it). -->

## Functions, views and indexes
<!-- What you built and why, and which queries each index helps -->

## The app
<!-- Your routes, your choice of frontend, where validation happens (API, database
     or both) and why, and how errors reach the user -->

## Data issues
<!-- For each known issue (and any you found): what you decided to do and why.
     Note any checkpoint results that changed as a result. -->

## Assumptions

- The instructions said data should be 'normalised' so I used a 3NF style data model, rather than a star schema.

## How you used AI tools
<!-- Which tools, what for, and anything you changed or rejected from their suggestions -->

## What you'd do with more time

## What you learned / researched
