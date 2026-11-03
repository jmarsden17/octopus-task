SELECT h.asset_id, lp.lifecycle_phase_name, h.start_date, h.end_date
FROM asset_status_history h
JOIN lifecycle_phases lp ON lp.lifecycle_phase_id = h.lifecycle_phase_id
WHERE h.asset_id = 'ASST_INFR_1073'
ORDER BY h.start_date;

INSERT INTO asset_milestones (milestone_type_id, asset_id, milestone_id, milestone_date)
VALUES (
  (SELECT milestone_type_id FROM milestone_types WHERE milestone_type_name = 'Actual'),
  'ASST_INFR_1073',
  (SELECT milestone_id FROM milestones WHERE milestone_name ILIKE 'Commercial Operation%'
     AND asset_type_id = (SELECT asset_type_id FROM assets WHERE asset_id = 'ASST_INFR_1073')),
  '2026-08-13'
);

SELECT h.asset_id, lp.lifecycle_phase_name, h.start_date, h.end_date
FROM asset_status_history h
JOIN lifecycle_phases lp ON lp.lifecycle_phase_id = h.lifecycle_phase_id
WHERE h.asset_id = 'ASST_INFR_1073'
ORDER BY h.start_date;
-- expect In Construction ... end 2026-08-13, then Operational from 2026-08-13

-- delete it again
DELETE FROM asset_milestones
WHERE asset_id = 'ASST_INFR_1073'
  AND milestone_date::date = '2026-08-13'
  AND milestone_type_id = (SELECT milestone_type_id FROM milestone_types WHERE milestone_type_name = 'Actual');

SELECT h.asset_id, lp.lifecycle_phase_name, h.start_date, h.end_date
FROM asset_status_history h
JOIN lifecycle_phases lp ON lp.lifecycle_phase_id = h.lifecycle_phase_id
WHERE h.asset_id = 'ASST_INFR_1073'
ORDER BY h.start_date;
-- back to In Construction with end_date NULL