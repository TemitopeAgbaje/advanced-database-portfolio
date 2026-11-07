-- Supalogi - demo trips for transactions and concurrency (Portfolio 3)
-- Creates 4 trips with fixed IDs so every demo starts from the same state.
-- Needs the Portfolio 2 data (generate-data.sql) to be loaded first.
-- Safe to re-run: run it again before each demo to reset.
--   pgAdmin: open this file in the Query Tool and press F5

DELETE FROM ratings  WHERE trip_id BETWEEN 900001 AND 900004;
DELETE FROM payments WHERE trip_id BETWEEN 900001 AND 900004;
DELETE FROM trips    WHERE trip_id BETWEEN 900001 AND 900004;

INSERT INTO trips (trip_id, rider_id, driver_id, city_id, pickup_addr, dropoff_addr,
                   status, fare, requested_at, started_at, ended_at) VALUES
    -- Demo 3: a new request in Lagos, waiting for a driver
    (900001, 101, NULL, 1, 'Ikeja', 'Lekki',    'requested', NULL,
        now() - interval '2 minutes', NULL, NULL),
    -- Demo 1: a trip in progress that is about to end
    (900002, 102, 10,   1, 'Yaba',  'Surulere', 'ongoing',   NULL,
        now() - interval '40 minutes', now() - interval '30 minutes', NULL),
    -- Demo 2: another trip in progress (its payment will fail)
    (900003, 103, 11,   2, 'Wuse',  'Garki',    'ongoing',   NULL,
        now() - interval '35 minutes', now() - interval '25 minutes', NULL),
    -- Demo 4: a finished trip whose fare gets corrected
    (900004, 104, 12,   5, 'Osu',   'Madina',   'completed', 3000.00,
        now() - interval '2 hours', now() - interval '110 minutes', now() - interval '80 minutes');

UPDATE drivers SET status = 'on_trip'   WHERE driver_id IN (10, 11);
UPDATE drivers SET status = 'available' WHERE driver_id IN (12, 20, 21);

SELECT trip_id, status, driver_id, fare FROM trips WHERE trip_id BETWEEN 900001 AND 900004 ORDER BY trip_id;
