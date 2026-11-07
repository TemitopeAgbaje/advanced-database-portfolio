-- Supalogi - Demo 3: concurrency problem and fix (Portfolio 3)
-- Ride request 900001 is shown to two drivers. Both tap "accept" at the same moment.
-- Only one of them should get the ride.
--
-- You need TWO pgAdmin Query Tool tabs (each tab is a separate connection):
--   Tab A = driver 20's app        Tab B = driver 21's app
-- Run each step in the tab it says, in order. Highlight the step and press F5.

-- ===========================================================================
-- Part 1: THE PROBLEM - lost update (both drivers think they got the ride)
-- ===========================================================================

-- STEP 0 (Tab A): reset - run setup.sql first

-- STEP 1 (Tab A): driver 20 checks the request
BEGIN;
SELECT trip_id, status, driver_id FROM trips WHERE trip_id = 900001;
-- shows: requested, no driver -> "I can take it"

-- STEP 2 (Tab B): driver 21 checks the same request at the same time
BEGIN;
SELECT trip_id, status, driver_id FROM trips WHERE trip_id = 900001;
-- also shows: requested, no driver -> "I can take it"

-- STEP 3 (Tab A): driver 20 accepts
UPDATE trips SET driver_id = 20, status = 'accepted' WHERE trip_id = 900001;
COMMIT;
-- driver 20's app says "Ride confirmed!"

-- STEP 4 (Tab B): driver 21 accepts too
UPDATE trips SET driver_id = 21, status = 'accepted' WHERE trip_id = 900001;
COMMIT;
-- driver 21's app also says "Ride confirmed!"

-- STEP 5 (either tab): who has the ride?
SELECT trip_id, status, driver_id FROM trips WHERE trip_id = 900001;
-- driver 21. Driver 20's update was silently overwritten (a "lost update"),
-- so driver 20 is now driving to a rider who isn't waiting for them.

-- ===========================================================================
-- Part 2: THE FIX - lock the row with SELECT ... FOR UPDATE
-- ===========================================================================

-- STEP 6 (Tab A): reset - run setup.sql again

-- STEP 7 (Tab A): driver 20 checks the request AND locks it
BEGIN;
SELECT trip_id, status, driver_id FROM trips WHERE trip_id = 900001 FOR UPDATE;

-- STEP 8 (Tab B): driver 21 tries the same
BEGIN;
SELECT trip_id, status, driver_id FROM trips WHERE trip_id = 900001 FOR UPDATE;
-- Tab B now WAITS (spinner, no result). The row is locked by Tab A.
-- Take a screenshot of Tab B waiting.

-- STEP 9 (Tab A): driver 20 accepts and commits, which releases the lock
UPDATE trips SET driver_id = 20, status = 'accepted' WHERE trip_id = 900001;
COMMIT;

-- Tab B finishes waiting by itself and shows: accepted, driver 20.
-- Driver 21's app sees the ride is already taken.

-- STEP 10 (Tab B): driver 21 gives up instead of overwriting
ROLLBACK;

-- STEP 11 (either tab): who has the ride?
SELECT trip_id, status, driver_id FROM trips WHERE trip_id = 900001;
-- driver 20, correctly. Nothing was overwritten.
