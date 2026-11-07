-- Supalogi - Demo 2: ROLLBACK (Portfolio 3)
-- Trip 900003 ends, but the rider's card is declined.
-- Part A: the app sees the decline and cancels everything with ROLLBACK.
-- Part B: a bad value breaks a rule (CHECK constraint), so the database refuses
--         the whole transaction, not just the bad line.
--
-- Run setup.sql first. In pgAdmin, highlight one STEP at a time and press F5.

-- STEP 1: before
SELECT t.trip_id, t.status AS trip_status, t.fare, d.status AS driver_status,
       p.status AS payment_status
FROM trips t
JOIN drivers d ON d.driver_id = t.driver_id
LEFT JOIN payments p ON p.trip_id = t.trip_id
WHERE t.trip_id = 900003;

-- ---------------------------------------------------------------------------
-- Part A: manual ROLLBACK
-- ---------------------------------------------------------------------------

-- STEP 2: start ending the trip
BEGIN;
UPDATE trips
SET status = 'completed', fare = 2800.00, ended_at = now()
WHERE trip_id = 900003;

UPDATE drivers SET status = 'available' WHERE driver_id = 11;

-- STEP 3: inside the transaction the trip looks completed...
SELECT trip_id, status, fare FROM trips WHERE trip_id = 900003;

-- STEP 4: ...but the card is declined, so undo everything
ROLLBACK;

-- STEP 5: after - nothing changed, the trip is still ongoing
SELECT t.trip_id, t.status AS trip_status, t.fare, d.status AS driver_status,
       p.status AS payment_status
FROM trips t
JOIN drivers d ON d.driver_id = t.driver_id
LEFT JOIN payments p ON p.trip_id = t.trip_id
WHERE t.trip_id = 900003;

-- ---------------------------------------------------------------------------
-- Part B: automatic rollback on error
-- ---------------------------------------------------------------------------

-- STEP 6: the payment amount is negative, which breaks CHECK (amount >= 0).
-- The UPDATE works, then the INSERT fails with an error.
BEGIN;
UPDATE trips
SET status = 'completed', fare = 2800.00, ended_at = now()
WHERE trip_id = 900003;

INSERT INTO payments (trip_id, amount, method, status, paid_at)
VALUES (900003, -2800.00, 'card', 'paid', now());

-- STEP 7: end the failed transaction
-- (if pgAdmin already rolled back for you, this just shows a warning - that's fine)
ROLLBACK;

-- STEP 8: after - the UPDATE was undone too, the trip is still ongoing
SELECT t.trip_id, t.status AS trip_status, t.fare, d.status AS driver_status,
       p.status AS payment_status
FROM trips t
JOIN drivers d ON d.driver_id = t.driver_id
LEFT JOIN payments p ON p.trip_id = t.trip_id
WHERE t.trip_id = 900003;
