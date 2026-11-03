# Design decisions

## How to build and run
1. In your terminal run 
``` bash
docker compose up -d
```
2. To set up the raw data tables:
``` bash
docker compose exec -T postgres psql -U techtest -d assets < sql/schema.sql
```
3. To seed the raw data tables:
``` bash
\copy raw_asset_milestones FROM 'data/asset_milestones.csv' WITH (FORMAT CSV, HEADER TRUE);
```
``` bash
\copy raw_milestone_sequence FROM 'data/milestone_sequence.csv' WITH (FORMAT CSV, HEADER TRUE);
```


## Data model
![alt text](<Screenshot 2026-11-03 at 11.54.00.png>)


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
