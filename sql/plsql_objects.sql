--------------------------------------------------------------------------
-- plsql_objects.sql
-- Lab Sample Management — PL/SQL support objects
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- 0a A schema addition needed for the trigger below
--
-- TEST_TYPES doesn't have a "safe limit" column. However, we need one
-- so the trigger below has something to compare a result against.
--------------------------------------------------------------------------
ALTER TABLE test_types ADD max_allowed_value NUMBER;

-- Example thresholds matching the seed data in seed_data.sql
UPDATE test_types SET max_allowed_value = 0.05 WHERE test_name = 'Pesticide Residue Screening';
UPDATE test_types SET max_allowed_value = 0.10 WHERE test_name = 'Heavy Metals Analysis';
UPDATE test_types SET max_allowed_value = 200   WHERE test_name = 'Microbiological Contamination';
UPDATE test_types SET max_allowed_value = NULL  WHERE test_name = 'Nutrient Composition'; -- no pass/fail limit
UPDATE test_types SET max_allowed_value = 0.9   WHERE test_name = 'GMO Detection';
UPDATE test_types SET max_allowed_value = 5      WHERE test_name = 'Mycotoxin Analysis';
COMMIT;

--------------------------------------------------------------------------
-- 0b. A error-logging table
--
-- This is the 'catch block', recording what happened and when.
-- A support engineer can look here when a scheduled job misbehaves.
--------------------------------------------------------------------------
CREATE TABLE error_log (
    log_id          NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    proc_name       VARCHAR2(100),
    error_message   VARCHAR2(4000),
    logged_at       TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_error_log PRIMARY KEY (log_id)
);

--------------------------------------------------------------------------
-- 1. TRIGGER: trg_test_results_limits
--
-- WHAT TRIGGER DOES: when a new lab result is inserted, if nobody filled
-- in is_within_limits by hand, the trigger looks up the maximum
-- allowed value for that test type and decides PASS (1) or FAIL (0)
-- automatically.
--------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_test_results_limits
BEFORE INSERT ON test_results
FOR EACH ROW
DECLARE
    -- A variable to temporarily hold the threshold we look up.
    v_max_allowed  test_types.max_allowed_value%TYPE;
    -- %TYPE means "give this variable the exact same data type as that
    -- column" -- if the column ever changes type, this still matches.
BEGIN
    -- Only step in if the caller didn't already specify a value.
    -- This lets manual overrides still work.
    IF :NEW.is_within_limits IS NULL THEN

        BEGIN
            -- Walk from the new result, via sample_tests, to test_types,
            -- to find the allowed maximum for this specific test.
            SELECT tt.max_allowed_value
              INTO v_max_allowed
              FROM sample_tests st
              JOIN test_types tt ON tt.test_type_id = st.test_type_id
             WHERE st.sample_test_id = :NEW.sample_test_id;

        EXCEPTION
            -- NO_DATA_FOUND is Oracle's built-in exception for "a SELECT
            -- INTO found zero rows". Here that would mean the
            -- sample_test_id doesn't exist, which the foreign key
            -- constraint should already prevent -- but handling it
            -- explicitly avoids the trigger crashing in an edge case.
            WHEN NO_DATA_FOUND THEN
                v_max_allowed := NULL;
        END;

        IF v_max_allowed IS NULL THEN
            -- No threshold defined for this test type - leave the flag blank.
            :NEW.is_within_limits := NULL;
        ELSIF :NEW.result_value <= v_max_allowed THEN
            :NEW.is_within_limits := 1;
        ELSE
            :NEW.is_within_limits := 0;
        END IF;

    END IF;
END;
/

--------------------------------------------------------------------------
-- 2. PROCEDURE: mark_expired_samples
--
-- WHAT PROCEDURE DOES: marks every sample whose expiry_date has already
-- passed but which was never finished (status is not yet ANALYZED or
-- already EXPIRED), and flips its status to EXPIRED.
--------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE mark_expired_samples
IS
    v_rows_updated NUMBER;
BEGIN
    UPDATE samples
       SET status = 'EXPIRED'
     WHERE expiry_date < SYSDATE
       AND status NOT IN ('ANALYZED', 'EXPIRED');

    -- SQL%ROWCOUNT means how many rows the statement above actually affected.
    -- It is useful for logging/auditing what a procedure did.
    v_rows_updated := SQL%ROWCOUNT;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(v_rows_updated || ' sample(s) marked as EXPIRED.');

EXCEPTION
    -- WHEN OTHERS catches any error not specifically handled above.
    -- SQLERRM gives the human-readable Oracle error message.
    -- One undoes any change and writes the failure to error_log.
    WHEN OTHERS THEN
        ROLLBACK;
        INSERT INTO error_log (proc_name, error_message)
        VALUES ('mark_expired_samples', SQLERRM);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('mark_expired_samples failed -- see error_log.');
END;
/

--------------------------------------------------------------------------
-- 3. FUNCTION: get_sample_test_history
--
-- WHAT FUNCTION DOES: given a sample_test_id, summarizes how many results
-- have been recorded for it and what the most recent one was.
--------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_sample_test_history(
    p_sample_test_id IN test_results.sample_test_id%TYPE
) RETURN VARCHAR2
IS
    v_result_count   NUMBER;
    v_latest_value   test_results.result_value%TYPE;
    v_latest_flag    test_results.is_within_limits%TYPE;
    v_summary        VARCHAR2(200);
BEGIN
    SELECT COUNT(*)
      INTO v_result_count
      FROM test_results
     WHERE sample_test_id = p_sample_test_id;

    IF v_result_count = 0 THEN
        RETURN 'No results recorded yet for sample_test_id ' || p_sample_test_id || '.';
    END IF;

    -- Get the most recent result specifically (ORDER BY ... FETCH FIRST
    -- 1 ROW ONLY is the modern, readable way to do "top 1 row" in
    -- Oracle -- available from 12c onward, same as the IDENTITY columns
    -- used in schema.sql).
    SELECT result_value, is_within_limits
      INTO v_latest_value, v_latest_flag
      FROM test_results
     WHERE sample_test_id = p_sample_test_id
     ORDER BY analyzed_date DESC
     FETCH FIRST 1 ROW ONLY;

    v_summary := v_result_count || ' result(s) recorded. Latest value: '
                 || v_latest_value || ' ('
                 || CASE v_latest_flag
                        WHEN 1 THEN 'PASS'
                        WHEN 0 THEN 'FAIL'
                        ELSE 'not evaluated'
                    END
                 || ').';

    RETURN v_summary;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'sample_test_id ' || p_sample_test_id || ' not found.';
END;
/


--------------------------------------------------------------------------
-- 4. VIEW: v_overdue_invoices
--
-- WHAT VIEW IS: a saved SELECT query that behaves like a table. You
-- don't store any data in it -- every time you query the view, Oracle
-- re-runs the underlying SELECT.
--------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_overdue_invoices AS
SELECT
    i.invoice_id,
    i.order_id,
    c.company_name,
    i.invoice_date,
    i.due_date,
    i.total_amount,
    i.payment_status,
    TRUNC(SYSDATE - i.due_date) AS days_overdue
FROM invoices i
JOIN orders  o ON o.order_id  = i.order_id
JOIN clients c ON c.client_id = o.client_id
WHERE i.payment_status != 'PAID'
  AND i.due_date < SYSDATE;

--------------------------------------------------------------------------
-- 5. VIEW: v_pending_samples_without_tests
--
-- WHAT THIS VIEW DOES: finds samples that have been received but don't
-- have a single row in sample_tests yet -- i.e. nobody has actually
-- requested a test for them. Example: sample 10 in the seed data ("client
-- asks: when does testing start?").
--
-- NOT EXISTS checks "is there at least one matching row in this other
-- table?" -- it's the cleanest way to express "has no related
-- rows", clearer to read here than a LEFT JOIN ... IS NULL would be.
--------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pending_samples_without_tests AS
SELECT
    s.sample_id,
    s.order_id,
    s.sample_type,
    s.received_date,
    s.status
FROM samples s
WHERE NOT EXISTS (
    SELECT 1
      FROM sample_tests st
     WHERE st.sample_id = s.sample_id
)
AND s.status != 'EXPIRED';