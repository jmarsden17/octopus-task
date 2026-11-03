INSERT INTO funds (fund_name)
SELECT DISTINCT fund
FROM raw_asset_milestones
WHERE fund IS NOT NULL;

INSERT INTO portfolios (portfolio_name, fund_id)
SELECT DISTINCT r.portfolio, f.fund_id
FROM raw_asset_milestones r
JOIN funds f ON r.fund = f.fund_name
WHERE r.portfolio IS NOT NULL;

INSERT INTO asset_types (asset_type_name)
SELECT DISTINCT asset_type
FROM raw_asset_milestones
WHERE asset_type IS NOT NULL;

INSERT INTO technology_groups (technology_group_name)
SELECT DISTINCT technology_grouping_tier_1
FROM raw_asset_milestones
WHERE technology_grouping_tier_1 IS NOT NULL;

INSERT INTO technologies (technology_name, technology_group_id)
SELECT DISTINCT r.technology, tg.technology_group_id
FROM raw_asset_milestones r
JOIN technology_groups tg ON r.technology_grouping_tier_1 = tg.technology_group_name
WHERE r.technology IS NOT NULL;

INSERT INTO countries (country_name)
SELECT DISTINCT country_name
FROM raw_asset_milestones
WHERE country_name IS NOT NULL;

INSERT INTO companies (company_name)
SELECT DISTINCT company_registered_name
FROM raw_asset_milestones
WHERE company_registered_name IS NOT NULL;

INSERT INTO assets (asset_id, asset_type_id, asset_name, portfolio_id, technology_id, country_id, capacity_mw, company_id)
SELECT DISTINCT r.asset_id,
       at.asset_type_id,
       r.asset_name,
       p.portfolio_id,
       t.technology_id,
       c.country_id,
       r.capacity_mw,
       co.company_id
FROM raw_asset_milestones r
JOIN asset_types at ON r.asset_type = at.asset_type_name
JOIN portfolios p ON r.portfolio = p.portfolio_name
LEFT JOIN technologies t ON r.technology = t.technology_name
LEFT JOIN countries c ON r.country_name = c.country_name
JOIN companies co ON r.company_registered_name = co.company_name
WHERE r.asset_id IS NOT NULL;

INSERT INTO sequences (sequence)
SELECT DISTINCT sequence
FROM raw_milestone_sequence
WHERE sequence IS NOT NULL;

INSERT INTO lifecycle_phases (lifecycle_phase)
SELECT DISTINCT lifecycle_phase
FROM raw_milestone_sequence
WHERE lifecycle_phase IS NOT NULL;

INSERT INTO milestone_types (milestone_type)
SELECT DISTINCT milestone_type
FROM raw_asset_milestones
WHERE milestone_type IS NOT NULL;

INSERT INTO milestones (milestone_id, milestone_name, milestone_type_id, lifecycle_phase_id, sequence_id)
SELECT DISTINCT r.milestone_id,
       r.milestone_name,
       mt.milestone_type_id,
       lp.lifecycle_phase_id,
       s.sequence_id
FROM raw_asset_milestones r
JOIN milestone_types mt ON r.milestone_type = mt.milestone_type
JOIN lifecycle_phases lp ON r.lifecycle_phase = lp.lifecycle_phase
JOIN sequences s ON r.sequence = s.sequence
WHERE r.milestone_id IS NOT NULL;

INSERT INTO asset_milestones (asset_id, milestone_id, milestone_type_id, milestone_date)
SELECT DISTINCT r.asset_id,
       r.milestone_id,
       mt.milestone_type_id,
       r.milestone_date
FROM raw_asset_milestones r
JOIN milestone_types mt ON r.milestone_type = mt.milestone_type
WHERE r.asset_id IS NOT NULL AND r.milestone_id IS NOT NULL;

INSERT INTO asset_experts (asset_id, person_id, role_id)
SELECT DISTINCT r.asset_id,
       p.person_id,
       rl.role_id
FROM raw_asset_milestones r
JOIN persons p ON r.expert_name = p.person_name
JOIN roles rl ON r.expert_role = rl.role_name
WHERE r.asset_id IS NOT NULL AND r.expert_name IS NOT NULL AND r.expert_role IS NOT NULL;