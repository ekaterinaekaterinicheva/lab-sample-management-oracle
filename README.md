# Lab Sample Management — Oracle Database Project

This is a small Oracle Database project that models the core workflow of a testing
laboratory: a client submits a sample, it goes through one or more tests,
results come back, and the client receives an invoice.

This project was created to apply and demonstrate SQL/PL-SQL and relational
database design skills in the context of an **application support** role.

## Why this project exists

Most "database practice projects" are either a tutorial clone (library,
blog, e-commerce cart) or an abstract schema with no real-world logic
behind it. I wanted something closer to what a support engineer at a
company that runs its own internal database actually deals with: a schema with real constraints, some PL/SQL blocks that enforce business rules, automate tasks and a set of queries
for investigating a support ticket.

So, this project is deliberately built around the following:
1. A schema and data model realistic enough to hold the process it
   represents (sample intake -> testing -> results -> invoice).
2. A number of "support tickets" with queries that answer them
   — because reading data and troubleshooting is most of what the
   day-to-day of this kind of role looks like.

## What this project is NOT

- Not a deployable application — there is no front end, no API.
- Not an attempt to model every case a real lab system would need —
  the scope is intentionally small enough.

## Repository structure

```
lab-sample-management-oracle/
├── README.md
├── docs/
│   ├── er-diagram.drawio      -- entity relationship diagram (completed using draw.io)
│   └── constraints.md         -- explanation of every CHECK rule and why it exists
├── sql/
│   ├── schema.sql             -- table definitions (DDL)
│   ├── constraints_indexes.sql  -- supporting indexes + reasoning
│   ├── seed_data.sql          -- small, realistic sample dataset
│   └── plsql_objects.sql      -- triggers, procedures, functions, views
└── queries/
    └── support_scenarios.sql   -- read-only queries, written as support tickets
```

## The business process being modeled

A client sends in a sample (soil, water, food, etc.) as part of an order.
The lab runs one or more types of tests on it (heavy
metals, microbiology, etc.), records the results, and bills
the client. Samples have a testing deadline (`expiry_date`); results can
come back passing or failing a defined limit; and a test can be re-run,
which is why one test can end up with more than one recorded result over
time.

## Data model — relationship logic

```
CLIENTS -> ORDERS (1:N) — one client can place multiple orders.

LABS -> ORDERS (1:N) — one laboratory can process many orders.

ORDERS -> SAMPLES (1:N) — one order can include multiple samples.

ORDERS -> INVOICES (1:N) — one order can be linked to multiple invoices.

SAMPLES -> SAMPLE_TESTS <- TEST_TYPES — this is an M:N junction table
which connects three entities. One sample is subjected to multiple types
of tests, and one test type is applied to many samples.

SAMPLE_TESTS -> TEST_RESULTS (1:N) — one test can be executed multiple
times / produce many outcomes.

Note: (1:N) means a one-to-many relationship; M:N means a many-to-many
relationship.
```

The reasoning behind the constraints enforcing this model (e.g., why
deletes are restricted) is written out in **[docs/constraints.md](docs/constraints.md)**.

## What I built, and why

### Schema and constraints (`schema.sql`, `constraints_indexes.sql`)

Eight tables, all primary keys as `IDENTITY` columns, with
`NOT NULL` foreign keys and `CHECK` constraints enforcing valid status
values and logical date ordering. No `ON DELETE CASCADE` anywhere --
deletes are intentionally restricted, because in a lab environment,
historical records must be permanent. They should never be lost as a side effect of deleting an unrelated row.

Oracle does **not** automatically index foreign key columns — only primary keys and unique constraints get an index for free. `constraints_indexes.sql` adds indexes on every FK
column that didn't already have one, plus a few extra indexes on columns
that the support queries below actually filter on (`samples.status`,
`samples.expiry_date`, `orders.status`, `invoices.payment_status`).

### PL/SQL objects (`plsql_objects.sql`)

| Object | Type | What it does | Why it exists |
|---|---|---|---|
| `trg_test_results_limits` | Trigger | Automatically sets `is_within_limits` (PASS/FAIL) on a new result by looking up the allowed threshold for that test type, unless a value was already supplied manually | Removes a manual call and keeps PASS/FAIL consistent regardless of who enters the result |
| `mark_expired_samples` | Procedure | Finds samples whose testing deadline has passed but which were never finished, and changes their status to `EXPIRED` | Models the kind of daily maintenance job that keeps data accurate without someone doing it by hand |
| `get_sample_test_history` | Function | Given a `sample_test_id`, returns a summary: how many results exist and what the most recent one was | Built specifically to answer "why does this sample have conflicting results" — a kind of question a client / colleague might ask on a ticket |
| `v_overdue_invoices` | View | Pre-joined, pre-filtered list of unpaid invoices past their due date | Saves re-writing the same multi-table JOIN every time someone needs this |
| `v_pending_samples_without_tests` | View | Samples that have been received but have no test requested yet | Exposes a "stuck" state that's easy to miss with a normal query |

`mark_expired_samples` also includes error handling: if something
unexpected goes wrong in the middle of update, it rolls back the change and writes
what happened to the `error_log`.

### Support ticket queries (`queries/support_scenarios.sql`)

Seven queries, each framed the way an actual ticket would be phrased,
followed by the query that answers it:

| # | "Ticket" | How it's answered |
|---|---|---|
| 1 | *"I was told my test failed, then passed on retest - what happened?"* | All results for one `sample_test_id`, ordered chronologically |
| 2 | *"List every finished test that came back out of limits, with enough context to know who to contact."* | A 5-table `JOIN` chain: result -> test -> sample -> order -> client |
| 3 | *"Show me what it's about to mark EXPIRED."* | Same filtering logic as `mark_expired_samples`, written as a read-only preview |
| 4 | *"When does testing actually start on my sample?"* | Built on the `v_pending_samples_without_tests` view |
| 5 | *"Which clients still owe us money, most overdue first?"* | Built on the `v_overdue_invoices` view |
| 6 | *"Pull up everything on record for this client."* | A handful of `LEFT JOIN`s — intentional, so that an order with no sample yet, or a sample with no test yet, still shows up instead of disappearing from the results |
| 7 | *"How many samples are in each status?"* | A `GROUP BY` / `COUNT(*)` summary |

The distinction between `JOIN` and `LEFT JOIN` in tickets #2 and #6 is
deliberate: ticket #2 only cares about complete results, so a
plain `JOIN` (which drops rows with no match) is needed there. Ticket #6
is meant to show a client's *whole* history, including orders that are
still incomplete, which is why `LEFT JOIN` is used there.

## How to run this

1. Set up an Oracle database.
2. Connect with Oracle SQL Developer.
3. Run the scripts in order:
   ```
   sql/schema.sql
   sql/constraints_indexes.sql
   sql/seed_data.sql
   sql/plsql_objects.sql
   ```
4. Explore with `queries/support_scenarios.sql`, or try the PL/SQL
   objects directly:
   ```sql
   EXEC mark_expired_samples;
   SELECT get_sample_test_history(1) FROM dual;
   SELECT * FROM v_overdue_invoices;
   ```

## What's not included in the project (and what I would add to improve it)

The following features are not included in the scope of this project:

- **No scheduling configured.** `mark_expired_samples` is
  written to be run on a schedule, but no `DBMS_SCHEDULER` job is set up
  in this project — it has to be called manually.
- **No automated tests.** A next step would be adding a few
  `utPLSQL` tests for the trigger and function, to check the PASS/FAIL
  logic and the retest-summary text without having to check it manually
  each time.
- **No least-privilege access model.** Everything here runs as a single
  schema owner. A production version would need separate roles
  (e.g. a read-only role for reporting queries, so a support query can
  never accidentally become an `UPDATE`).
- **Small dataset.** 10 rows of seed data per table is enough to
  demonstrate the logic, but doesn't test how any of this holds
  up at real volume.

## Tech

Oracle Database (developed and tested against Oracle Database Free 23ai)
· SQL · PL/SQL