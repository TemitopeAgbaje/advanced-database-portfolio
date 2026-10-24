-- Supalogi - before/after optimisation tests (Portfolio 2)
-- For each slow query: show the execution plan, add an index (or a materialized view),
-- then show the plan again. Run after generate-data.sql:
--   psql -U postgres -d supalogi -f optimisation.sql
-- Safe to re-run: it removes its own indexes first so "before" is always a true before.

DROP INDEX IF EXISTS idx_trips_rider_requested;
DROP INDEX IF EXISTS idx_trips_driver_requested;
DROP INDEX IF EXISTS idx_trips_waiting;
DROP MATERIALIZED VIEW IF EXISTS city_monthly_stats;

-- ---------------------------------------------------------------------------
-- Optimisation 1: rider trip history (Q1)
-- Composite index: find one rider's trips, already sorted newest first.
-- ---------------------------------------------------------------------------
\echo '=== Q1 BEFORE ==='
EXPLAIN ANALYZE
SELECT trip_id, requested_at, pickup_addr, dropoff_addr, status, fare
FROM trips
WHERE rider_id = 4242
ORDER BY requested_at DESC
LIMIT 20;

CREATE INDEX idx_trips_rider_requested ON trips (rider_id, requested_at DESC);

\echo '=== Q1 AFTER ==='
EXPLAIN ANALYZE
SELECT trip_id, requested_at, pickup_addr, dropoff_addr, status, fare
FROM trips
WHERE rider_id = 4242
ORDER BY requested_at DESC
LIMIT 20;

-- ---------------------------------------------------------------------------
-- Optimisation 2: one driver's weekly earnings (Q2)
-- Composite index: jump to one driver, then only their trips in the date range.
-- ---------------------------------------------------------------------------
\echo '=== Q2 BEFORE ==='
EXPLAIN ANALYZE
SELECT count(*), sum(p.amount)
FROM trips t
JOIN payments p ON p.trip_id = t.trip_id
WHERE t.driver_id = 77
  AND t.requested_at >= now() - interval '7 days'
  AND p.status = 'paid';

CREATE INDEX idx_trips_driver_requested ON trips (driver_id, requested_at);

\echo '=== Q2 AFTER ==='
EXPLAIN ANALYZE
SELECT count(*), sum(p.amount)
FROM trips t
JOIN payments p ON p.trip_id = t.trip_id
WHERE t.driver_id = 77
  AND t.requested_at >= now() - interval '7 days'
  AND p.status = 'paid';

-- ---------------------------------------------------------------------------
-- Optimisation 3: matching queue (Q3)
-- Partial index: only indexes the few trips still waiting, not all 200,000.
-- ---------------------------------------------------------------------------
\echo '=== Q3 BEFORE ==='
EXPLAIN ANALYZE
SELECT trip_id, rider_id, pickup_addr, requested_at
FROM trips
WHERE status = 'requested' AND city_id = 1
ORDER BY requested_at
LIMIT 10;

CREATE INDEX idx_trips_waiting ON trips (city_id, requested_at) WHERE status = 'requested';

\echo '=== Q3 AFTER ==='
EXPLAIN ANALYZE
SELECT trip_id, rider_id, pickup_addr, requested_at
FROM trips
WHERE status = 'requested' AND city_id = 1
ORDER BY requested_at
LIMIT 10;

-- ---------------------------------------------------------------------------
-- Optimisation 4: monthly city report (Q5)
-- This query reads every trip, so no index can help. Instead, a materialized view
-- stores the finished answer, and is refreshed on a schedule (e.g. nightly).
-- ---------------------------------------------------------------------------
\echo '=== Q5 BEFORE (live query over all trips) ==='
EXPLAIN ANALYZE
SELECT c.name, date_trunc('month', t.requested_at)::date AS month, count(*),
       round(100.0 * count(*) FILTER (WHERE t.status = 'cancelled') / count(*), 1)
FROM trips t
JOIN cities c ON c.city_id = t.city_id
GROUP BY c.name, month;

CREATE MATERIALIZED VIEW city_monthly_stats AS
SELECT c.name                                   AS city,
       date_trunc('month', t.requested_at)::date AS month,
       count(*)                                 AS trips,
       round(100.0 * count(*) FILTER (WHERE t.status = 'cancelled') / count(*), 1) AS cancel_rate_pct
FROM trips t
JOIN cities c ON c.city_id = t.city_id
GROUP BY c.name, month;

\echo '=== Q5 AFTER (reading the materialized view) ==='
EXPLAIN ANALYZE
SELECT * FROM city_monthly_stats ORDER BY city, month;

-- ---------------------------------------------------------------------------
-- Not every query needs an index: Q4 reads about 1/6 of all trips, so a full
-- scan is still the cheapest plan. The planner ignores our indexes here.
-- ---------------------------------------------------------------------------
\echo '=== Q4 (indexes exist, but a full scan is still chosen) ==='
EXPLAIN ANALYZE
SELECT d.driver_id, d.full_name, count(*), sum(p.amount) AS earnings
FROM trips t
JOIN payments p ON p.trip_id = t.trip_id
JOIN drivers d  ON d.driver_id = t.driver_id
WHERE p.status = 'paid'
  AND t.requested_at >= now() - interval '30 days'
GROUP BY d.driver_id, d.full_name
ORDER BY earnings DESC
LIMIT 10;

-- ---------------------------------------------------------------------------
-- The cost of indexes: they take disk space and slow down every INSERT/UPDATE.
-- ---------------------------------------------------------------------------
\echo '=== Index sizes vs table size ==='
SELECT relname AS name,
       pg_size_pretty(pg_relation_size(oid)) AS size
FROM pg_class
WHERE relname IN ('trips', 'idx_trips_rider_requested', 'idx_trips_driver_requested', 'idx_trips_waiting')
ORDER BY pg_relation_size(oid) DESC;
