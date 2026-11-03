CREATE OR REPLACE FUNCTION rebuild_asset_status_history(p_asset_id VARCHAR)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM asset_status_history WHERE asset_id = p_asset_id;

    INSERT INTO asset_status_history (asset_id, lifecycle_phase_id, start_date, end_date)
    WITH actuals AS (
        SELECT am.milestone_date::date AS d,
               s.sequence_name      AS seq,
               m.lifecycle_phase_id    AS phase
        FROM asset_milestones am
        JOIN milestone_types mt ON mt.milestone_type_id = am.milestone_type_id
        JOIN milestones m       ON m.milestone_id = am.milestone_id
        JOIN sequences s        ON s.sequence_id = m.sequence_id
        WHERE am.asset_id = p_asset_id
          AND mt.milestone_type_name = 'Actual'
    ),
    reached AS (
        -- for each date something happened, the furthest-along milestone reached by then
        SELECT dt.d, best.phase
        FROM (SELECT DISTINCT d FROM actuals) dt
        CROSS JOIN LATERAL (
            SELECT a.phase
            FROM actuals a
            WHERE a.d <= dt.d
            ORDER BY a.seq DESC
            LIMIT 1
        ) best
    ),
    changes AS (
        SELECT d, phase, lag(phase) OVER (ORDER BY d) AS prev_phase
        FROM reached
    ),
    starts AS (
        -- keep only the dates where the phase actually changes
        SELECT d, phase FROM changes
        WHERE prev_phase IS DISTINCT FROM phase
    )
    SELECT p_asset_id, phase, d, lead(d) OVER (ORDER BY d)
    FROM starts;
END;
$$;

