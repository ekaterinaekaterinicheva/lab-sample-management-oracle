# Integrity Constraints

This document describes the constraints enforced in the `lab-sample-management-oracle` schema and the reasoning behind each constraint. It complements the ER diagram (`er-diagram.drawio`), which shows solely the structure.

| Table | Constraint | Why? |
|---|---|---|
| `ORDERS.status` | `CHECK (status IN ('NEW','IN_PROGRESS','COMPLETED','CANCELLED'))` | Maintains status integrity throughout the workflow. |
| `SAMPLES.status` | `CHECK (status IN ('RECEIVED','TESTING','ANALYZED','EXPIRED'))` | Maintains status integrity throughout the workflow. |
| `SAMPLES` | `CHECK (received_date >= collection_date)` | A sample cannot be received by the lab before it was physically collected. |
| `SAMPLES` | `CHECK (expiry_date >= received_date)` | The testing deadline must be set after the sample is received. |
| `SAMPLE_TESTS` | `UNIQUE (sample_id, test_type_id, requested_date)` | Prevents the exact same test from being requested twice for the same sample on the same date. It is allowing a retest on a later date. |
| `INVOICES.total_amount` | `CHECK (total_amount >= 0)` | An invoice cannot have a negative amount. |
| `TEST_RESULTS.is_within_limits` | `CHECK (is_within_limits IN (0,1))` | Forces the column to only accept two possible values: 0 (Out of limits) or 1 (Within limits). |
| All foreign keys | `NOT NULL` + `FOREIGN KEY` | Prevents accidental deletion of a client, lab, order, or sample that still has dependent records. |
