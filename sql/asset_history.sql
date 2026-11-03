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


-- keeps status history in sync
CREATE OR REPLACE FUNCTION trg_asset_milestones_sync()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        PERFORM rebuild_asset_status_history(NEW.asset_id);
    END IF;
    IF TG_OP = 'DELETE'
       OR (TG_OP = 'UPDATE' AND OLD.asset_id IS DISTINCT FROM NEW.asset_id) THEN
        PERFORM rebuild_asset_status_history(OLD.asset_id);
    END IF;
    RETURN NULL;  -- return value is ignored for AFTER triggers
END;
$$;

CREATE TRIGGER asset_milestones_sync
AFTER INSERT OR UPDATE OR DELETE ON asset_milestones
FOR EACH ROW EXECUTE FUNCTION trg_asset_milestones_sync();


-- rejects future Actuals
CREATE OR REPLACE FUNCTION trg_reject_future_actual()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_type_name VARCHAR;
BEGIN
    SELECT milestone_type_name INTO v_type_name
    FROM milestone_types WHERE milestone_type_id = NEW.milestone_type_id;

    IF v_type_name = 'Actual' AND NEW.milestone_date::date > CURRENT_DATE THEN
        RAISE EXCEPTION
            'Actual milestone % for asset % cannot be dated in the future (%)',
            NEW.milestone_id, NEW.asset_id, NEW.milestone_date::date
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER asset_milestones_no_future_actual
BEFORE INSERT OR UPDATE ON asset_milestones
FOR EACH ROW EXECUTE FUNCTION trg_reject_future_actual();

CREATE OR REPLACE FUNCTION asset_status_as_of(p_asset_id VARCHAR, p_as_of DATE)
RETURNS TABLE (lifecycle_phase_name VARCHAR, since DATE)
LANGUAGE sql STABLE
AS $$
    SELECT lp.lifecycle_phase_name, h.start_date::date
    FROM asset_status_history h
    JOIN lifecycle_phases lp ON lp.lifecycle_phase_id = h.lifecycle_phase_id
    WHERE h.asset_id = p_asset_id
      AND h.start_date <= p_as_of
      AND (h.end_date IS NULL OR p_as_of < h.end_date);
$$;