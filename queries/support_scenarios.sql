--------------------------------------------------------------------------
-- support_scenarios.sql
-- Lab Sample Management — application-support query log
--
-- These are read-only SELECT queries (no PL/SQL). Each one is written as
-- if it's answering a real support ticket, using the scenarios
-- deliberately built into seed_data.sql.
--------------------------------------------------------------------------


--------------------------------------------------------------------------
-- TICKET #1
-- Client says: "I was told my pesticide test failed, then I heard it
-- passed on a retest -- can you show me exactly what happened?"
--
-- Investigation: pull every result ever recorded for this one specific
-- sample_test_id, oldest first, so we can see the sequence of attempts
-- in the order they actually happened.
--------------------------------------------------------------------------
SELECT
    tr.result_id,
    tr.sample_test_id,
    tr.result_value,
    tr.result_unit,
    -- CASE here turns the raw 1/0/NULL flag into something a human
    -- (e.g. a colleague working with clients) can read and understand.
    CASE tr.is_within_limits
        WHEN 1 THEN 'PASS'
        WHEN 0 THEN 'FAIL'
        ELSE 'N/A'
    END AS verdict,
    tr.analyzed_by,
    tr.analyzed_date
FROM test_results tr
WHERE tr.sample_test_id = 1
-- ASC: Read this like a story -- what happened first, second, third, etc.
ORDER BY tr.analyzed_date ASC;


--------------------------------------------------------------------------
-- TICKET #2
-- Internal QA asks: "Give me a list of every FINISHED test that came
-- back outside the allowed limits, with enough context to know who to
-- contact about it."
--
-- Investigation: this needs data from 6 tables: the result,
-- which test it was, which sample, which order, which client, and 
-- the human-readable test name. Each JOIN below "attaches" one table.
--
-- st.status = 'DONE' matters here.
--------------------------------------------------------------------------
SELECT
    c.company_name,
    o.order_id,
    s.sample_id,
    s.sample_type,
    tt.test_name,
    tr.result_value,
    tr.result_unit,
    tr.analyzed_date
FROM test_results tr
JOIN sample_tests st ON st.sample_test_id = tr.sample_test_id
JOIN samples      s  ON s.sample_id       = st.sample_id
JOIN orders        o  ON o.order_id        = s.order_id
JOIN clients       c  ON c.client_id       = o.client_id
JOIN test_types    tt ON tt.test_type_id   = st.test_type_id
WHERE tr.is_within_limits = 0
  AND st.status = 'DONE'
ORDER BY tr.analyzed_date DESC;


--------------------------------------------------------------------------
-- TICKET #3
-- Lab manager asks: "Show me exactly which samples it's about to mark
-- as EXPIRED, and by how many days they're overdue."
--
-- Investigation: this is the SAME logic used inside the
-- mark_expired_samples procedure in plsql_objects.sql, but written as
-- a SELECT instead of an UPDATE.
--
-- TRUNC(SYSDATE - expiry_date) subtracts one date from another, which
-- in Oracle gives you a number of days. TRUNC() cuts off any leftover
-- fraction of a day (example: "5" instead of "5.37").
--------------------------------------------------------------------------
SELECT
    sample_id,
    order_id,
    sample_type,
    status,
    expiry_date,
    TRUNC(SYSDATE - expiry_date) AS days_past_expiry
FROM samples
WHERE expiry_date < SYSDATE
  AND status NOT IN ('ANALYZED', 'EXPIRED')
ORDER BY expiry_date ASC;


--------------------------------------------------------------------------
-- TICKET #4
-- Client says: "I gave you a sample a while ago -- when does testing
-- actually start?"
--
-- Investigation: reuse the v_pending_samples_without_tests view from
-- plsql_objects.sql (it already finds samples with 0 rows in sample_tests)
-- and join it to orders/clients so we now WHO to contact, not just which
-- sample is stuck.
--
-- Note: we can JOIN a view exactly like a normal table.
--------------------------------------------------------------------------
SELECT
    c.company_name,
    o.order_id,
    v.sample_id,
    v.sample_type,
    v.received_date,
    -- Same date-subtraction trick as ticket #3, just measuring
    -- "days since received" instead of "days past expiry".
    TRUNC(SYSDATE - v.received_date) AS days_waiting
FROM v_pending_samples_without_tests v
JOIN orders  o ON o.order_id  = v.order_id
JOIN clients c ON c.client_id = o.client_id
ORDER BY days_waiting DESC;


--------------------------------------------------------------------------
-- TICKET #5
-- Finance asks: "Which clients still owe us money, and who's the most
-- overdue?"
--
-- Investigation: v_overdue_invoices (from plsql_objects.sql) already
-- joins invoices -> orders -> clients and calculates days_overdue
-- so this query is just reading it, sorted by urgency.
--------------------------------------------------------------------------
SELECT *
FROM v_overdue_invoices
ORDER BY days_overdue DESC;


--------------------------------------------------------------------------
-- TICKET #6
-- Account department asks: "Pull up everything we've got on record for
-- client_id = 1 (every order, sample, test, result)".
--
-- Investigation: This uses LEFT JOIN instead of the plain JOIN.
-- A plain (inner) JOIN only keeps a row if a match exists on BOTH sides.
--------------------------------------------------------------------------
SELECT
    o.order_id,
    o.order_date,
    o.status      AS order_status,
    s.sample_id,
    s.sample_type,
    s.status      AS sample_status,
    tt.test_name,
    tr.result_value,
    CASE tr.is_within_limits
        WHEN 1 THEN 'PASS'
        WHEN 0 THEN 'FAIL'
        ELSE NULL
    END AS verdict
FROM orders o
LEFT JOIN samples      s  ON s.order_id        = o.order_id
LEFT JOIN sample_tests st ON st.sample_id      = s.sample_id
LEFT JOIN test_types   tt ON tt.test_type_id   = st.test_type_id
LEFT JOIN test_results tr ON tr.sample_test_id = st.sample_test_id
WHERE o.client_id = 1   -- swap this value to look up a different client
ORDER BY o.order_date, s.sample_id, tt.test_name;


--------------------------------------------------------------------------
-- TICKET #7
-- Team lead asks: "Give me a quick a snapshot: how many samples
-- are sitting in each status right now?"
--
-- Investigation: this one isn't about a single sample or client
-- it's a summary across the whole table. GROUP BY collects all rows
-- that share the same value in a column (`status`) into one group
-- per distinct value, and COUNT(*) counts how many rows ended up
-- in each group.
--------------------------------------------------------------------------
SELECT
    status,
    COUNT(*) AS sample_count
FROM samples
GROUP BY status
ORDER BY sample_count DESC;