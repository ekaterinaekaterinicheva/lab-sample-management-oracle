-- Lab Sample Management — sample test data

-- All PK columns use GENERATED ALWAYS AS IDENTITY starting
-- at 1, so the IDs match the order rows are inserted in.
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- CLIENTS (10)
--------------------------------------------------------------------------
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('Fresh Foods GmbH', 'quality@fresh.de', '+490000000000', 'Germany');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('GreenValley Farms Ltd', 'lab@greenvalley.pl', '+48000000000', 'Poland');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('Nordic Water Solutions AS', 'contact@nordicwater.no', '+47000000000', 'Norway');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('BioHarvest Cooperative', 'info@bioharvest.fr', '+33000000000', 'France');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('Terra Pura Agricultural SL', 'calidad@terrapura.es', '+34000000000', 'Spain');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('CleanSoil Environmental BV', 'info@cleansoil.nl', '+31000000000', 'Netherlands');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('Alpine Dairy Products AG', 'qs@alpinedairy.at', '+43000000000', 'Austria');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('Danube Grain Trading SRL', 'office@danubegrain.ro', '+40000000000', 'Romania');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('EcoTest Consulting srl', 'lab@ecotest.it', '+39000000000', 'Italy');
INSERT INTO clients (company_name, contact_email, phone, country) VALUES
    ('Baltic Fisheries Group', 'quality@balticfish.lv', '+37100000000', 'Latvia');

--------------------------------------------------------------------------
-- LABS (5)
--------------------------------------------------------------------------
INSERT INTO labs (lab_name, city, country) VALUES
    ('BioLab Munich', 'Munich', 'Germany');
INSERT INTO labs (lab_name, city, country) VALUES
    ('BioLab Warsaw', 'Warsaw', 'Poland');
INSERT INTO labs (lab_name, city, country) VALUES
    ('BioLab Lyon', 'Lyon', 'France');
INSERT INTO labs (lab_name, city, country) VALUES
    ('BioLab Madrid', 'Madrid', 'Spain');
INSERT INTO labs (lab_name, city, country) VALUES
    ('BioLab Rotterdam', 'Rotterdam', 'Netherlands');

--------------------------------------------------------------------------
-- TEST_TYPES (6)
--------------------------------------------------------------------------
INSERT INTO test_types (test_name, unit_of_measure, default_price) VALUES
    ('Pesticide Residue Screening', 'mg/kg', 85.00);
INSERT INTO test_types (test_name, unit_of_measure, default_price) VALUES
    ('Heavy Metals Analysis', 'mg/kg', 65.00);
INSERT INTO test_types (test_name, unit_of_measure, default_price) VALUES
    ('Microbiological Contamination', 'CFU/g', 45.00);
INSERT INTO test_types (test_name, unit_of_measure, default_price) VALUES
    ('Nutrient Composition', '%', 55.00);
INSERT INTO test_types (test_name, unit_of_measure, default_price) VALUES
    ('GMO Detection', '%', 95.00);
INSERT INTO test_types (test_name, unit_of_measure, default_price) VALUES
    ('Mycotoxin Analysis', 'ug/kg', 70.00);

--------------------------------------------------------------------------
-- ORDERS (10) -- client_id / lab_id below match insertion order above
--------------------------------------------------------------------------
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (1, 1, DATE '2026-01-10', 'COMPLETED');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (2, 2, DATE '2026-01-15', 'COMPLETED');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (3, 3, DATE '2026-02-02', 'IN_PROGRESS');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (4, 4, DATE '2026-02-20', 'COMPLETED');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (5, 5, DATE '2026-03-05', 'CANCELLED');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (6, 1, DATE '2026-03-18', 'IN_PROGRESS');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (7, 2, DATE '2026-04-01', 'NEW');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (8, 3, DATE '2026-04-14', 'COMPLETED');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (9, 4, DATE '2026-05-02', 'IN_PROGRESS');
INSERT INTO orders (client_id, lab_id, order_date, status) VALUES
    (10, 5, DATE '2026-05-20', 'NEW');

--------------------------------------------------------------------------
-- SAMPLES (10) -- one sample per order, order_id matches insertion order
--------------------------------------------------------------------------
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (1, 'FOOD', DATE '2026-01-08', DATE '2026-01-10', DATE '2026-01-20', 'ANALYZED');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (2, 'WATER', DATE '2026-01-13', DATE '2026-01-15', DATE '2026-01-25', 'ANALYZED');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (3, 'SOIL', DATE '2026-01-30', DATE '2026-02-02', DATE '2026-02-16', 'TESTING');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (4, 'FOOD', DATE '2026-02-18', DATE '2026-02-20', DATE '2026-03-02', 'ANALYZED');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (5, 'WATER', DATE '2026-03-03', DATE '2026-03-05', DATE '2026-03-19', 'EXPIRED');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (6, 'SOIL', DATE '2026-03-16', DATE '2026-03-18', DATE '2026-04-01', 'TESTING');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (7, 'FOOD', DATE '2026-03-30', DATE '2026-04-01', DATE '2026-04-15', 'RECEIVED');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (8, 'WATER', DATE '2026-04-10', DATE '2026-04-14', DATE '2026-04-28', 'ANALYZED');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (9, 'SOIL', DATE '2026-04-28', DATE '2026-05-02', DATE '2026-05-16', 'TESTING');
INSERT INTO samples (order_id, sample_type, collection_date, received_date, expiry_date, status) VALUES
    (10, 'FOOD', DATE '2026-05-18', DATE '2026-05-20', DATE '2026-06-03', 'RECEIVED');

--------------------------------------------------------------------------
-- SAMPLE_TESTS (10) -- sample_id 1 has two tests requested to show the
-- many-to-many relationship with test_types
--------------------------------------------------------------------------
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (1, 1, DATE '2026-01-10', 'DONE');          -- sample_test_id 1
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (1, 3, DATE '2026-01-10', 'DONE');          -- sample_test_id 2
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (2, 2, DATE '2026-01-15', 'DONE');          -- sample_test_id 3
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (3, 1, DATE '2026-02-02', 'IN_PROGRESS');   -- sample_test_id 4
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (4, 4, DATE '2026-02-20', 'DONE');          -- sample_test_id 5
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (5, 2, DATE '2026-03-05', 'PENDING');       -- sample_test_id 6
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (6, 6, DATE '2026-03-18', 'IN_PROGRESS');   -- sample_test_id 7
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (7, 1, DATE '2026-04-01', 'PENDING');       -- sample_test_id 8
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (8, 3, DATE '2026-04-14', 'DONE');          -- sample_test_id 9
INSERT INTO sample_tests (sample_id, test_type_id, requested_date, status) VALUES
    (9, 5, DATE '2026-05-02', 'IN_PROGRESS');   -- sample_test_id 10

--------------------------------------------------------------------------
-- TEST_RESULTS (10) -- sample_test_id 1 has two retest rows to show the
-- 1:N relationship: first two exceed the pesticide limit, the retest passes.
--------------------------------------------------------------------------
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (1, 0.08, 'mg/kg', 0, 'M. Keller', DATE '2026-01-16');
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (1, 0.09, 'mg/kg', 0, 'M. Keller', DATE '2026-01-18');   -- retest 1, failing
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (1, 0.02, 'mg/kg', 1, 'J. Novak', DATE '2026-01-20');    -- retest 2, passes
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (2, 120, 'CFU/g', 1, 'J. Novak', DATE '2026-01-17');
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (3, 0.015, 'mg/kg', 1, 'A. Dubois', DATE '2026-01-22');
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (5, 18.5, '%', 1, 'A. Dubois', DATE '2026-02-27');
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (9, 340, 'CFU/g', 0, 'P. Vermeer', DATE '2026-04-19');   -- final result, exceeds limit
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (4, 0.03, 'mg/kg', 1, 'M. Keller', DATE '2026-02-10');   -- preliminary reading, sample_test still IN_PROGRESS
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (7, 4.2, 'ug/kg', 1, 'J. Novak', DATE '2026-03-25');     -- preliminary reading
INSERT INTO test_results (sample_test_id, result_value, result_unit, is_within_limits, analyzed_by, analyzed_date) VALUES
    (10, 0.1, '%', 1, 'A. Dubois', DATE '2026-05-09');       -- preliminary reading

--------------------------------------------------------------------------
-- INVOICES (10) -- order_id matches insertion order above
--------------------------------------------------------------------------
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (1, DATE '2026-01-21', DATE '2026-02-04', 210.00, 'PAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (2, DATE '2026-01-26', DATE '2026-02-09', 150.00, 'PAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (3, DATE '2026-02-17', DATE '2026-03-03', 85.00, 'UNPAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (4, DATE '2026-03-03', DATE '2026-03-17', 175.00, 'PAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (5, DATE '2026-03-20', DATE '2026-04-03', 130.00, 'OVERDUE');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (6, DATE '2026-04-02', DATE '2026-04-16', 190.00, 'UNPAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (7, DATE '2026-04-02', DATE '2026-04-16', 85.00, 'UNPAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (8, DATE '2026-04-29', DATE '2026-05-13', 145.00, 'PAID');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (9, DATE '2026-05-17', DATE '2026-05-31', 95.00, 'OVERDUE');
INSERT INTO invoices (order_id, invoice_date, due_date, total_amount, payment_status) VALUES
    (10, DATE '2026-06-04', DATE '2026-06-18', 85.00, 'UNPAID');

COMMIT;