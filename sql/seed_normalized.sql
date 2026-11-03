INSERT INTO funds (fund_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(fund), ''), 'null')
FROM raw_asset_milestones
WHERE NULLIF(NULLIF(btrim(fund), ''), 'null') IS NOT NULL;

INSERT INTO portfolios (portfolio_name, fund_id)
SELECT DISTINCT NULLIF(NULLIF(btrim(r.investment_portfolio), ''), 'null'), f.fund_id
FROM raw_asset_milestones r
JOIN funds f ON r.fund = f.fund_name
WHERE NULLIF(NULLIF(btrim(r.investment_portfolio), ''), 'null') IS NOT NULL;

INSERT INTO asset_types (asset_type_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(asset_type), ''), 'null')
FROM raw_asset_milestones
WHERE NULLIF(NULLIF(btrim(asset_type), ''), 'null') IS NOT NULL
ON CONFLICT (asset_type_name) DO NOTHING;

INSERT INTO technology_groups (technology_group_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(technology_grouping_tier_1), ''), 'null')
FROM raw_asset_milestones
WHERE NULLIF(NULLIF(btrim(technology_grouping_tier_1), ''), 'null') IS NOT NULL
ON CONFLICT (technology_group_name) DO NOTHING;

INSERT INTO technologies (technology_name, technology_group_id)
SELECT DISTINCT NULLIF(NULLIF(btrim(r.technology_name), ''), 'null'), tg.technology_group_id
FROM raw_asset_milestones r
JOIN technology_groups tg ON r.technology_grouping_tier_1 = tg.technology_group_name
WHERE NULLIF(NULLIF(btrim(r.technology_name), ''), 'null') IS NOT NULL;

INSERT INTO countries (country_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(country_name), ''), 'null')
FROM raw_asset_milestones
WHERE NULLIF(NULLIF(btrim(country_name), ''), 'null') IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO companies (company_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(company_registered_name), ''), 'null')
FROM raw_asset_milestones
WHERE NULLIF(NULLIF(btrim(company_registered_name), ''), 'null') IS NOT NULL
ON CONFLICT (company_name) DO NOTHING;

INSERT INTO assets (asset_id, asset_type_id, asset_name, portfolio_id, technology_id, country_id, capacity_mw, company_id)
SELECT DISTINCT NULLIF(NULLIF(btrim(r.asset_id), ''), 'null'),
       at.asset_type_id,
       NULLIF(NULLIF(btrim(r.asset), ''), 'null'),
       p.portfolio_id,
       t.technology_id,
       c.country_id,
       NULLIF(NULLIF(btrim(r.capacity_mw), ''), 'null')::NUMERIC(10, 2),
       co.company_id
FROM raw_asset_milestones r
JOIN asset_types at ON r.asset_type = at.asset_type_name
JOIN portfolios p ON r.investment_portfolio = p.portfolio_name
LEFT JOIN technologies t ON r.technology_name = t.technology_name
LEFT JOIN countries c ON r.country_name = c.country_name
JOIN companies co ON r.company_registered_name = co.company_name
WHERE NULLIF(NULLIF(btrim(r.asset_id), ''), 'null') IS NOT NULL;

INSERT INTO sequences (sequence_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(sequence), ''), 'null')::INT
FROM raw_milestone_sequence
WHERE NULLIF(NULLIF(btrim(sequence), ''), 'null') IS NOT NULL
ON CONFLICT (sequence_name) DO NOTHING;

INSERT INTO lifecycle_phases (lifecycle_phase_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(lifecycle_phase), ''), 'null')
FROM raw_milestone_sequence
WHERE NULLIF(NULLIF(btrim(lifecycle_phase), ''), 'null') IS NOT NULL
ON CONFLICT (lifecycle_phase_name) DO NOTHING;

INSERT INTO milestone_types (milestone_type_name)
SELECT DISTINCT NULLIF(NULLIF(btrim(milestone_type), ''), 'null')
FROM raw_asset_milestones
WHERE NULLIF(NULLIF(btrim(milestone_type), ''), 'null') IS NOT NULL
ON CONFLICT (milestone_type_name) DO NOTHING;

INSERT INTO milestones (
    milestone_id,
    milestone_name,
    sequence_id,
    asset_type_id,
    lifecycle_phase_id
)
SELECT DISTINCT
    btrim(r.milestone_id),
    btrim(r.milestone_name),
    s.sequence_id,
    at.asset_type_id,
    lp.lifecycle_phase_id
FROM raw_milestone_sequence AS r
JOIN sequences AS s
    ON s.sequence_name = btrim(r.sequence)::INT
JOIN asset_types AS at
    ON at.asset_type_name = btrim(r.applies_to)
JOIN lifecycle_phases AS lp
    ON lp.lifecycle_phase_name = btrim(r.lifecycle_phase)
ON CONFLICT (milestone_id) DO NOTHING;

INSERT INTO asset_milestones (
    asset_id,
    milestone_id,
    milestone_type_id,
    milestone_date
)
SELECT DISTINCT
    NULLIF(NULLIF(btrim(r.asset_id), ''), 'null'),
    m.milestone_id,
    mt.milestone_type_id,
    (NULLIF(NULLIF(btrim(r.milestone_date), ''), 'null')::timestamptz
        AT TIME ZONE 'UTC')::date
FROM raw_asset_milestones AS r
JOIN asset_types AS at
    ON at.asset_type_name = btrim(r.asset_type)
JOIN milestones AS m
    ON m.milestone_name = btrim(r.milestone_name)
    AND m.asset_type_id = at.asset_type_id
JOIN milestone_types AS mt
    ON mt.milestone_type_name = btrim(r.milestone_type)
WHERE NULLIF(NULLIF(btrim(r.asset_id), ''), 'null') IS NOT NULL
ON CONFLICT (asset_id, milestone_id, milestone_type_id) DO NOTHING;
