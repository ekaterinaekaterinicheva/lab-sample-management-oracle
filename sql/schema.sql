--------------------------------------------------------------------------
-- schema.sql
-- Lab Sample Management — Oracle Database DDL
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- CLIENTS
--------------------------------------------------------------------------
CREATE TABLE clients (
    client_id       NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    company_name    VARCHAR2(200)   NOT NULL,
    contact_email   VARCHAR2(100),
    phone           VARCHAR2(50),
    country         VARCHAR2(100),
    CONSTRAINT pk_clients PRIMARY KEY (client_id)
);

COMMENT ON TABLE clients IS 'Companies that order lab analyses.';

--------------------------------------------------------------------------
-- LABS
--------------------------------------------------------------------------
CREATE TABLE labs (
    lab_id      NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    lab_name    VARCHAR2(200)   NOT NULL,
    city        VARCHAR2(100),
    country     VARCHAR2(100),
    CONSTRAINT pk_labs PRIMARY KEY (lab_id)
);

COMMENT ON TABLE labs IS 'Laboratories that process orders.';

--------------------------------------------------------------------------
-- ORDERS
--------------------------------------------------------------------------
CREATE TABLE orders (
    order_id    NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    client_id   NUMBER          NOT NULL,
    lab_id      NUMBER          NOT NULL,
    order_date  DATE            NOT NULL,
    status      VARCHAR2(50)    NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_client
        FOREIGN KEY (client_id) REFERENCES clients (client_id),
    CONSTRAINT fk_orders_lab
        FOREIGN KEY (lab_id) REFERENCES labs (lab_id),
    CONSTRAINT ck_orders_status
        CHECK (status IN ('NEW', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
);

COMMENT ON TABLE orders IS 'One analysis order placed by a client and assigned to a lab.';

--------------------------------------------------------------------------
-- SAMPLES
--------------------------------------------------------------------------
CREATE TABLE samples (
    sample_id       NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    order_id        NUMBER          NOT NULL,
    sample_type     VARCHAR2(100),
    collection_date DATE            NOT NULL,
    received_date   DATE,
    expiry_date     DATE,
    status          VARCHAR2(50)    NOT NULL,
    CONSTRAINT pk_samples PRIMARY KEY (sample_id),
    CONSTRAINT fk_samples_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT ck_samples_status
        CHECK (status IN ('RECEIVED', 'TESTING', 'ANALYZED', 'EXPIRED')),
    CONSTRAINT ck_samples_received_after_collection
        CHECK (received_date IS NULL OR received_date >= collection_date),
    CONSTRAINT ck_samples_expiry_after_received
        CHECK (expiry_date IS NULL OR received_date IS NULL
               OR expiry_date >= received_date)
);

COMMENT ON TABLE samples IS 'Physical samples collected for an order.';

--------------------------------------------------------------------------
-- TEST_TYPES (reference table)
--------------------------------------------------------------------------
CREATE TABLE test_types (
    test_type_id    NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    test_name       VARCHAR2(200)   NOT NULL,
    unit_of_measure VARCHAR2(50),
    default_price   NUMBER(10,2),
    CONSTRAINT pk_test_types PRIMARY KEY (test_type_id),
    CONSTRAINT ck_test_types_price
        CHECK (default_price IS NULL OR default_price >= 0)
);

COMMENT ON TABLE test_types IS 'A list of test types the lab can perform.';

--------------------------------------------------------------------------
-- SAMPLE_TESTS (this is the bridge table between SAMPLES and TEST_TYPES)
--------------------------------------------------------------------------
CREATE TABLE sample_tests (
    sample_test_id  NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    sample_id       NUMBER          NOT NULL,
    test_type_id    NUMBER          NOT NULL,
    requested_date  DATE            NOT NULL,
    status          VARCHAR2(50)    NOT NULL,
    CONSTRAINT pk_sample_tests PRIMARY KEY (sample_test_id),
    CONSTRAINT fk_sample_tests_sample
        FOREIGN KEY (sample_id) REFERENCES samples (sample_id),
    CONSTRAINT fk_sample_tests_type
        FOREIGN KEY (test_type_id) REFERENCES test_types (test_type_id),
    CONSTRAINT ck_sample_tests_status
        CHECK (status IN ('PENDING', 'IN_PROGRESS', 'DONE')),
    -- It blocks an accidental duplicate request for the same test on the same day.
    CONSTRAINT uq_sample_tests_no_same_day_dup
        UNIQUE (sample_id, test_type_id, requested_date)
);

COMMENT ON TABLE sample_tests IS 'A specific test requested for a specific sample.';

--------------------------------------------------------------------------
-- TEST_RESULTS
--------------------------------------------------------------------------
CREATE TABLE test_results (
    result_id           NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    sample_test_id      NUMBER          NOT NULL,
    result_value        NUMBER,
    result_unit         VARCHAR2(50),
    is_within_limits    NUMBER(1),
    analyzed_by         VARCHAR2(200),
    analyzed_date       DATE,
    CONSTRAINT pk_test_results PRIMARY KEY (result_id),
    CONSTRAINT fk_test_results_sample_test
        FOREIGN KEY (sample_test_id) REFERENCES sample_tests (sample_test_id),
    CONSTRAINT ck_test_results_within_limits
        CHECK (is_within_limits IN (0, 1))
);

COMMENT ON TABLE test_results IS 'Result of one performed test. 1:N from sample_tests to allow retests.';

--------------------------------------------------------------------------
-- INVOICES
--------------------------------------------------------------------------
CREATE TABLE invoices (
    invoice_id      NUMBER
        GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    order_id        NUMBER          NOT NULL,
    invoice_date    DATE            NOT NULL,
    due_date        DATE,
    total_amount    NUMBER(10,2)    NOT NULL,
    payment_status  VARCHAR2(20)    NOT NULL,
    CONSTRAINT pk_invoices PRIMARY KEY (invoice_id),
    CONSTRAINT fk_invoices_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT ck_invoices_amount
        CHECK (total_amount >= 0),
    CONSTRAINT ck_invoices_payment_status
        CHECK (payment_status IN ('UNPAID', 'PAID', 'OVERDUE'))
);

COMMENT ON TABLE invoices IS 'An invoice generated for an order.';

--------------------------------------------------------------------------
-- Notes
--------------------------------------------------------------------------
-- 1. No ON DELETE clause is specified on any foreign key. Oracle's default
--    behavior without ON DELETE CASCADE/SET NULL is to block ("restrict")
--    the delete of a parent row while child rows exist — which matches the
--    "never silently lose lab data" design decision described in
--    docs/constraints.md.
--
-- 2. Indexes on foreign key columns (client_id, lab_id, order_id,
--    sample_id, test_type_id, sample_test_id) are defined separately in
--    02_constraints_indexes.sql — Oracle does not create them
--    automatically for FK columns, unlike the primary key columns above.
--------------------------------------------------------------------------