CREATE TABLE raw_asset_milestones
(   asset_id TEXT,
    asset TEXT,
    asset_type TEXT,
    fund TEXT,
    investment_portfolio_id TEXT,
    investment_portfolio TEXT,
    technology_name TEXT,
    technology_grouping_tier_1 TEXT,
    country_name TEXT,
    capacity_mw TEXT,
    company_registered_name TEXT,
    milestone_id TEXT,
    milestone_name TEXT,
    milestone_type TEXT,
    milestone_date TEXT,
    experts TEXT
);

CREATE TABLE raw_milestone_sequence (
    sequence TEXT,
    milestone_id TEXT,
    milestone_name TEXT,
    applies_to TEXT,
    lifecycle_phase TEXT
);

-- Run in terminal to load data into the tables from CSV files
-- \copy raw_asset_milestones FROM 'data/asset_milestones.csv' WITH (FORMAT CSV, HEADER TRUE);
-- \copy raw_milestone_sequence FROM 'data/milestone_sequence.csv' WITH (FORMAT CSV, HEADER TRUE);