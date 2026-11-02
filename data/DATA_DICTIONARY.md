# Data dictionary

## `asset_milestones.csv`

52 rows, 16 columns. Grain: **one row per mention of a milestone for an asset**,
exported from a reporting system. The asset's details and its experts are
repeated on every one of its rows.

| Column | Description |
|---|---|
| `asset_id` | Asset identifier, e.g. `ASST_INFR_1001` |
| `asset` | Asset name |
| `asset_type` | `Infrastructure` (a physical asset) or `Platform` (a business / developer) |
| `fund` | Fund name (there is only one fund in this extract) |
| `investment_portfolio_id` | Portfolio identifier, e.g. `INVP_1001` |
| `investment_portfolio` | Portfolio name |
| `technology_name` | Technology, e.g. Onshore wind, Rooftop solar |
| `technology_grouping_tier_1` | The group a technology belongs to, e.g. Clean Power Generation |
| `country_name` | Country the asset is in |
| `capacity_mw` | Total capacity of the asset in megawatts (MW) |
| `company_registered_name` | Registered name of the project company that holds the asset |
| `milestone_id` | Milestone identifier, e.g. `LIFE_MILE_1021` |
| `milestone_name` | Milestone name, e.g. Commercial Operation Date (COD) |
| `milestone_type` | `Actual` (it happened), `Forecast` (it's expected) or `Baseline` (the originally planned date) |
| `milestone_date` | When the milestone happened or is expected, as a UTC timestamp, e.g. `2011-11-27T00:00:00.000Z` |
| `experts` | JSON array of the people responsible for the asset and their roles (see below) |

`experts` example:

```json
[{"employee_name":"Jonas Dorsey","email":"jonas.dorsey@meridian-energy.example",
  "expert_in":["Valuations Lead"]},
 {"employee_name":"Amira Marsh","email":"amira.marsh@meridian-energy.example",
  "expert_in":["Product Lead","Deal Lead"]}]
```

## `milestone_sequence.csv`

10 rows. The reference list of lifecycle milestones: the order they happen in,
and the lifecycle phase an asset is in once each one has actually happened. This
file is clean and is the source of truth for milestone IDs.

| Column | Description |
|---|---|
| `sequence` | Order within an asset type: a higher number is further along the lifecycle |
| `milestone_id` | Milestone identifier |
| `milestone_name` | Milestone name |
| `applies_to` | The asset type the milestone is used for: `Infrastructure` or `Platform` |
| `lifecycle_phase` | The phase an asset is in once this milestone has an Actual date |
