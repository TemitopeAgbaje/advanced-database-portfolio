-- Supalogi - Demo 4: isolation levels (Portfolio 3)
-- An operations analyst is checking trip 900004's fare (Tab A) while a support agent
-- corrects it from 3000 to 4500 (Tab B).
-- The isolation level decides what the analyst sees while their transaction is open.
--
-- You need TWO pgAdmin Query Tool tabs:
--   Tab A = operations analyst      Tab B = support agent
-- Run each step in the tab it says, in order. Highlight the step and press F5.

-- ===========================================================================
-- Part 1: READ COMMITTED (PostgreSQL's default)
-- ===========================================================================

-- STEP 0 (Tab A): reset - run setup.sql first

-- STEP 1 (Tab A): start a transaction and read the fare
BEGIN;
SHOW transaction_isolation;
SELECT trip_id, fare FROM trips WHERE trip_id = 900004;
-- fare = 3000

-- STEP 2 (Tab B): support corrects the fare (saved straight away)
UPDATE trips SET fare = 4500.00 WHERE trip_id = 900004;

-- STEP 3 (Tab A): read the fare again, in the SAME transaction
SELECT trip_id, fare FROM trips WHERE trip_id = 900004;
-- fare = 4500. The same question gave two different answers inside one
-- transaction. This is a "non-repeatable read".
COMMIT;

-- ===========================================================================
-- Part 2: REPEATABLE READ
-- ===========================================================================

-- STEP 4 (Tab A): reset - run setup.sql again

-- STEP 5 (Tab A): start a REPEATABLE READ transaction and read the fare
BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;
SELECT trip_id, fare FROM trips WHERE trip_id = 900004;
-- fare = 3000

-- STEP 6 (Tab B): support corrects the fare again
UPDATE trips SET fare = 4500.00 WHERE trip_id = 900004;

-- STEP 7 (Tab A): read again
SELECT trip_id, fare FROM trips WHERE trip_id = 900004;
-- still 3000. Tab A keeps seeing the data as it was when its transaction
-- started (a "snapshot"), so its report stays consistent.

-- STEP 8 (Tab A): now try to add a 200 tip to the fare
UPDATE trips SET fare = fare + 200 WHERE trip_id = 900004;
-- ERROR: could not serialize access due to concurrent update
-- Tab A's snapshot is out of date (someone changed this row after it started),
-- so PostgreSQL refuses rather than write 3200 over the support agent's 4500.

-- STEP 9 (Tab A): end the failed transaction
ROLLBACK;

-- STEP 10 (either tab): the support agent's correction is safe
SELECT trip_id, fare FROM trips WHERE trip_id = 900004;
-- fare = 4500
