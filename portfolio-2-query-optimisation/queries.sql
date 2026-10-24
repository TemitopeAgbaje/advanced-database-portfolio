-- Supalogi - business queries (Portfolio 2: Query Processing and Optimisation)
-- Each query answers a real question from the app or the operations team.
-- Run after generate-data.sql:
--   psql -U postgres -d supalogi -f queries.sql

\echo '=== Q1. Rider app: "Your trips" (latest 20 trips for one rider) ==='
SELECT trip_id, requested_at, pickup_addr, dropoff_addr, status, fare
FROM trips
WHERE rider_id = 4242
ORDER BY requested_at DESC
LIMIT 20;

\echo '=== Q2. Driver app: earnings for one driver in the last 7 days ==='
SELECT count(*)      AS paid_trips,
       sum(p.amount) AS earnings
FROM trips t
JOIN payments p ON p.trip_id = t.trip_id
WHERE t.driver_id = 77
  AND t.requested_at >= now() - interval '7 days'
  AND p.status = 'paid';

\echo '=== Q3. Matching service: oldest waiting requests in Lagos ==='
SELECT trip_id, rider_id, pickup_addr, requested_at
FROM trips
WHERE status = 'requested'
  AND city_id = 1
ORDER BY requested_at
LIMIT 10;

\echo '=== Q4. Operations: top 10 earning drivers in the last 30 days ==='
SELECT d.driver_id,
       d.full_name,
       count(*)      AS paid_trips,
       sum(p.amount) AS earnings
FROM trips t
JOIN payments p ON p.trip_id = t.trip_id
JOIN drivers d  ON d.driver_id = t.driver_id
WHERE p.status = 'paid'
  AND t.requested_at >= now() - interval '30 days'
GROUP BY d.driver_id, d.full_name
ORDER BY earnings DESC
LIMIT 10;

\echo '=== Q5. Operations: monthly trips and cancellation rate per city ==='
SELECT c.name                                   AS city,
       date_trunc('month', t.requested_at)::date AS month,
       count(*)                                 AS trips,
       round(100.0 * count(*) FILTER (WHERE t.status = 'cancelled') / count(*), 1) AS cancel_rate_pct
FROM trips t
JOIN cities c ON c.city_id = t.city_id
GROUP BY c.name, month
ORDER BY c.name, month;

\echo '=== Q6. Quality team: 10 lowest-rated drivers (at least 20 ratings) ==='
SELECT d.driver_id,
       d.full_name,
       round(avg(r.score), 2) AS avg_score,
       count(*)               AS ratings
FROM ratings r
JOIN trips t   ON t.trip_id = r.trip_id
JOIN drivers d ON d.driver_id = t.driver_id
WHERE r.from_role = 'rider'
GROUP BY d.driver_id, d.full_name
HAVING count(*) >= 20
ORDER BY avg_score
LIMIT 10;
