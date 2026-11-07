-- Supalogi - Demo 1: COMMIT (Portfolio 3)
-- Trip 900002 ends. Three changes must happen together:
--   1. the trip is marked completed
--   2. the payment is recorded
--   3. the driver becomes available again
-- If only some happened, the data would be wrong (e.g. a completed trip with no payment).
-- A transaction makes them all-or-nothing. COMMIT saves all three at once.
--
-- Run setup.sql first. In pgAdmin, highlight one STEP at a time and press F5.

-- STEP 1: before
SELECT t.trip_id, t.status AS trip_status, t.fare, d.status AS driver_status,
       p.status AS payment_status
FROM trips t
JOIN drivers d ON d.driver_id = t.driver_id
LEFT JOIN payments p ON p.trip_id = t.trip_id
WHERE t.trip_id = 900002;

-- STEP 2: end the trip (one transaction)
BEGIN;
UPDATE trips
SET status = 'completed', fare = 4200.00, ended_at = now()
WHERE trip_id = 900002;

INSERT INTO payments (trip_id, amount, method, status, paid_at)
VALUES (900002, 4200.00, 'card', 'paid', now());

UPDATE drivers SET status = 'available' WHERE driver_id = 10;
COMMIT;

-- STEP 3: after - all three changes are saved
SELECT t.trip_id, t.status AS trip_status, t.fare, d.status AS driver_status,
       p.status AS payment_status
FROM trips t
JOIN drivers d ON d.driver_id = t.driver_id
LEFT JOIN payments p ON p.trip_id = t.trip_id
WHERE t.trip_id = 900002;
