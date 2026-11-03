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

-- Run these commands through psql inside the Postgres container.
-- \copy raw_asset_milestones FROM '/data/asset_milestones.csv' WITH (FORMAT CSV, HEADER TRUE)
-- \copy raw_milestone_sequence FROM '/data/milestone_sequence.csv' WITH (FORMAT CSV, HEADER TRUE)

CREATE TABLE funds (
    fund_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fund_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE portfolios (
    portfolio_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    portfolio_name VARCHAR NOT NULL UNIQUE,
    fund_id INT NOT NULL,
    FOREIGN KEY (fund_id) REFERENCES funds(fund_id)
);

CREATE TABLE asset_types (
    asset_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_type_name VARCHAR NOT NULL UNIQUE
        CHECK (asset_type_name IN ('Infrastructure', 'Platform'))
);

CREATE TABLE technology_groups (
    technology_group_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    technology_group_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE technologies (
    technology_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    technology_name VARCHAR NOT NULL UNIQUE,
    technology_group_id INT NOT NULL,
    FOREIGN KEY (technology_group_id) REFERENCES technology_groups(technology_group_id)
);

CREATE TABLE countries (
    country_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE companies (
    company_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE assets (
    asset_id VARCHAR UNIQUE NOT NULL PRIMARY KEY,
    asset_type_id INT NOT NULL,
    asset_name VARCHAR NOT NULL,
    portfolio_id INT NOT NULL,
    technology_id INT,
    country_id INT,
    capacity_mw DECIMAL(10, 2) CHECK (capacity_mw IS NULL OR capacity_mw >= 0),
    company_id INT NOT NULL,
    CHECK (
        (technology_id IS NULL AND country_id IS NULL AND capacity_mw IS NULL)
        OR
        (technology_id IS NOT NULL AND country_id IS NOT NULL AND capacity_mw IS NOT NULL)
    ),
    FOREIGN KEY (asset_type_id) REFERENCES asset_types(asset_type_id),
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    FOREIGN KEY (technology_id) REFERENCES technologies(technology_id),
    FOREIGN KEY (country_id) REFERENCES countries(country_id),
    FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

CREATE TABLE sequences (
    sequence_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sequence_name INT NOT NULL UNIQUE CHECK (sequence_name BETWEEN 10 AND 90)
);

CREATE TABLE lifecycle_phases (
    lifecycle_phase_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lifecycle_phase_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE milestone_types (
    milestone_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    milestone_type_name VARCHAR NOT NULL UNIQUE
        CHECK (milestone_type_name IN ('Actual', 'Forecast', 'Baseline'))
);

CREATE TABLE milestones (
    milestone_id VARCHAR UNIQUE NOT NULL PRIMARY KEY,
    milestone_name VARCHAR NOT NULL,
    sequence_id INT NOT NULL,
    asset_type_id INT NOT NULL,
    lifecycle_phase_id INT NOT NULL,
    FOREIGN KEY (sequence_id) REFERENCES sequences(sequence_id),
    FOREIGN KEY (asset_type_id) REFERENCES asset_types(asset_type_id),
    FOREIGN KEY (lifecycle_phase_id) REFERENCES lifecycle_phases(lifecycle_phase_id)
);

CREATE TABLE asset_status_history (
    asset_status_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id VARCHAR NOT NULL,
    lifecycle_phase_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    CHECK (end_date IS NULL OR end_date >= start_date),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    FOREIGN KEY (lifecycle_phase_id) REFERENCES lifecycle_phases(lifecycle_phase_id)
);

CREATE TABLE asset_milestones (
    asset_milestone_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id VARCHAR NOT NULL,
    milestone_id VARCHAR NOT NULL,
    milestone_type_id INT NOT NULL,
    milestone_date DATE NOT NULL,
    UNIQUE (asset_id, milestone_id, milestone_type_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    FOREIGN KEY (milestone_id) REFERENCES milestones(milestone_id),
    FOREIGN KEY (milestone_type_id) REFERENCES milestone_types(milestone_type_id)
);

CREATE TABLE people (
    person_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_name VARCHAR NOT NULL,
    person_email VARCHAR NOT NULL UNIQUE
);

CREATE TABLE roles (
    role_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE asset_experts (
    asset_expert_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id VARCHAR NOT NULL,
    person_id INT NOT NULL,
    role_id INT NOT NULL,
    UNIQUE (asset_id, person_id, role_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    FOREIGN KEY (person_id) REFERENCES people(person_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);