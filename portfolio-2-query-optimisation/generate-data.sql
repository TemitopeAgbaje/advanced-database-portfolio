-- Supalogi - bulk test data (Portfolio 2: Query Processing and Optimisation)
-- Fills the Portfolio 1 tables with enough rows for query plans and indexes to matter.
-- Replaces any existing data. Run after ../portfolio-1-database-design/schema.sql:
--   psql -U postgres -d supalogi -f generate-data.sql

TRUNCATE ratings, payments, trips, vehicles, drivers, riders, cities RESTART IDENTITY CASCADE;

SELECT setseed(0.42);  -- same "random" data on every run

INSERT INTO cities (name, country) VALUES
    ('Lagos', 'Nigeria'),
    ('Abuja', 'Nigeria'),
    ('Port Harcourt', 'Nigeria'),
    ('Ibadan', 'Nigeria'),
    ('Accra', 'Ghana'),
    ('Kumasi', 'Ghana');

-- 20,000 riders
INSERT INTO riders (full_name, email, phone, created_at)
SELECT 'Rider ' || i,
       'rider' || i || '@mail.com',
       '+23480' || lpad(i::text, 8, '0'),
       now() - random() * interval '365 days'
FROM generate_series(1, 20000) AS i;

-- 1,500 drivers
INSERT INTO drivers (full_name, email, phone, license_no, status, created_at)
SELECT 'Driver ' || i,
       'driver' || i || '@mail.com',
       '+23481' || lpad(i::text, 8, '0'),
       'LIC-' || lpad(i::text, 6, '0'),
       (ARRAY['offline', 'available', 'on_trip'])[1 + floor(random() * 3)::int],
       now() - random() * interval '365 days'
FROM generate_series(1, 1500) AS i;

-- one vehicle per driver
INSERT INTO vehicles (driver_id, plate_no, make, model, color, year)
SELECT i,
       'SPL-' || lpad(i::text, 5, '0'),
       (ARRAY['Toyota', 'Honda', 'Kia', 'Hyundai'])[1 + i % 4],
       (ARRAY['Corolla', 'Civic', 'Rio', 'Elantra'])[1 + i % 4],
       (ARRAY['Black', 'Silver', 'White', 'Blue', 'Red'])[1 + floor(random() * 5)::int],
       2012 + i % 12
FROM generate_series(1, 1500) AS i;

-- 200,000 past trips over the last 180 days: ~88% completed, ~12% cancelled.
-- The inner query picks random values once per trip so the outer query can reuse them.
INSERT INTO trips (rider_id, driver_id, city_id, pickup_addr, dropoff_addr,
                   status, fare, requested_at, started_at, ended_at)
SELECT rider_id,
       CASE WHEN cancelled THEN NULL ELSE driver_id END,
       city_id,
       areas[city_id][1 + p],
       areas[city_id][1 + (p + hop) % 4],
       CASE WHEN cancelled THEN 'cancelled' ELSE 'completed' END,
       CASE WHEN cancelled THEN NULL ELSE fare END,
       requested_at,
       CASE WHEN cancelled THEN NULL ELSE requested_at + wait END,
       CASE WHEN cancelled THEN NULL ELSE requested_at + wait + ride END
FROM (
    SELECT 1 + floor(random() * 20000)::int            AS rider_id,
           1 + floor(random() * 1500)::int             AS driver_id,
           1 + floor(random() * 6)::int                AS city_id,
           floor(random() * 4)::int                    AS p,     -- pickup area
           1 + floor(random() * 3)::int                AS hop,   -- dropoff is a different area
           random() < 0.12                             AS cancelled,
           round((1500 + random() * 7500)::numeric, -1) AS fare,
           now() - random() * interval '180 days'      AS requested_at,
           (2 + random() * 13) * interval '1 minute'   AS wait,
           (10 + random() * 50) * interval '1 minute'  AS ride
    FROM generate_series(1, 200000)
) AS t,
LATERAL (SELECT ARRAY[
    ARRAY['Ikeja', 'Lekki', 'Yaba', 'Surulere'],             -- Lagos
    ARRAY['Wuse', 'Maitama', 'Garki', 'Gwarinpa'],           -- Abuja
    ARRAY['Old GRA', 'Rumuola', 'Trans-Amadi', 'Choba'],     -- Port Harcourt
    ARRAY['Bodija', 'Dugbe', 'Challenge', 'Mokola'],         -- Ibadan
    ARRAY['Osu', 'Airport City', 'East Legon', 'Madina'],    -- Accra
    ARRAY['Adum', 'Asokwa', 'Bantama', 'Suame']              -- Kumasi
] AS areas) AS a;

-- 60 live requests from the last 10 minutes, still waiting for a driver (10 per city)
INSERT INTO trips (rider_id, city_id, pickup_addr, dropoff_addr, status, requested_at)
SELECT 1 + floor(random() * 20000)::int,
       1 + i % 6,
       areas[1 + i % 6][1 + i % 4],
       areas[1 + i % 6][1 + (i + 1) % 4],
       'requested',
       now() - random() * interval '10 minutes'
FROM generate_series(1, 60) AS i,
LATERAL (SELECT ARRAY[
    ARRAY['Ikeja', 'Lekki', 'Yaba', 'Surulere'],
    ARRAY['Wuse', 'Maitama', 'Garki', 'Gwarinpa'],
    ARRAY['Old GRA', 'Rumuola', 'Trans-Amadi', 'Choba'],
    ARRAY['Bodija', 'Dugbe', 'Challenge', 'Mokola'],
    ARRAY['Osu', 'Airport City', 'East Legon', 'Madina'],
    ARRAY['Adum', 'Asokwa', 'Bantama', 'Suame']
] AS areas) AS a;

-- one payment per completed trip: ~95% paid, ~5% failed
INSERT INTO payments (trip_id, amount, method, status, paid_at)
SELECT trip_id,
       fare,
       (ARRAY['card', 'cash', 'wallet'])[1 + floor(random() * 3)::int],
       CASE WHEN failed THEN 'failed' ELSE 'paid' END,
       CASE WHEN failed THEN NULL ELSE ended_at END
FROM (
    SELECT trip_id, fare, ended_at, random() < 0.05 AS failed
    FROM trips
    WHERE status = 'completed'
) AS t;

-- ratings: ~70% of riders and ~50% of drivers rate a completed trip
INSERT INTO ratings (trip_id, from_role, score, created_at)
SELECT trip_id,
       from_role,
       CASE WHEN r < 0.05 THEN 1
            WHEN r < 0.10 THEN 2
            WHEN r < 0.25 THEN 3
            WHEN r < 0.55 THEN 4
            ELSE 5 END,
       ended_at + interval '5 minutes'
FROM (
    SELECT t.trip_id, t.ended_at, roles.from_role, random() AS r, random() AS keep, roles.share
    FROM trips t
    CROSS JOIN (VALUES ('rider', 0.7), ('driver', 0.5)) AS roles(from_role, share)
    WHERE t.status = 'completed'
) AS x
WHERE keep < share;

-- refresh table statistics so the query planner knows the new sizes
ANALYZE;

SELECT 'riders' AS table_name, count(*) FROM riders
UNION ALL SELECT 'drivers',  count(*) FROM drivers
UNION ALL SELECT 'trips',    count(*) FROM trips
UNION ALL SELECT 'payments', count(*) FROM payments
UNION ALL SELECT 'ratings',  count(*) FROM ratings;
