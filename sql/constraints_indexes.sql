--------------------------------------------------------------------------
-- 02_constraints_indexes.sql
-- Lab Sample Management — supporting indexes
--
-- Oracle does NOT automatically index foreign key columns it only
-- indexes PRIMARY KEY and UNIQUE-constrained columns automatically.
--
-- Support indexes support the diagnostic queries an application-support
-- engineer would run day to day (see support_scenarios.sql).
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- 1. Foreign key indexes
--------------------------------------------------------------------------

-- ORDERS references CLIENTS and LABS
CREATE INDEX idx_orders_client_id ON orders (client_id);
CREATE INDEX idx_orders_lab_id    ON orders (lab_id);

-- SAMPLES references ORDERS
CREATE INDEX idx_samples_order_id ON samples (order_id);

-- SAMPLE_TESTS references SAMPLES and TEST_TYPES
CREATE INDEX idx_sample_tests_test_type_id ON sample_tests (test_type_id);

-- TEST_RESULTS references SAMPLE_TESTS
CREATE INDEX idx_test_results_sample_test_id ON test_results (sample_test_id);

-- INVOICES references ORDERS
CREATE INDEX idx_invoices_order_id ON invoices (order_id);

--------------------------------------------------------------------------
-- 2. Support indexes
--------------------------------------------------------------------------

-- Frequently used to find samples approaching or past their testing deadline
-- (e.g. "list all samples that expired before being analyzed").
CREATE INDEX idx_samples_expiry_date ON samples (expiry_date);

-- Frequently filtered when triaging tickets like "which samples are stuck
-- in TESTING" or "how many samples are still RECEIVED and untouched".
CREATE INDEX idx_samples_status ON samples (status);

-- Frequently filtered when checking order stuck orders.
CREATE INDEX idx_orders_status ON orders (status);

-- Frequently filtered when checking overdue payments.
CREATE INDEX idx_invoices_payment_status ON invoices (payment_status);