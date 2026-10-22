-- Supalogi - PostgreSQL schema (Portfolio 1: Database Design)
-- Run with: psql -U postgres -d supalogi -f schema.sql

DROP TABLE IF EXISTS ratings, payments, trips, vehicles, drivers, riders, cities CASCADE;

CREATE TABLE cities (
    city_id     SERIAL PRIMARY KEY,
    name        VARCHAR(80)  NOT NULL,
    country     VARCHAR(80)  NOT NULL
);

CREATE TABLE riders (
    rider_id    SERIAL PRIMARY KEY,
    full_name   VARCHAR(120) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    phone       VARCHAR(20)  NOT NULL UNIQUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE drivers (
    driver_id   SERIAL PRIMARY KEY,
    full_name   VARCHAR(120) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    phone       VARCHAR(20)  NOT NULL UNIQUE,
    license_no  VARCHAR(40)  NOT NULL UNIQUE,
    status      VARCHAR(20)  NOT NULL DEFAULT 'offline'
                CHECK (status IN ('offline', 'available', 'on_trip')),
    created_at  TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
    vehicle_id  SERIAL PRIMARY KEY,
    driver_id   INT NOT NULL REFERENCES drivers(driver_id),
    plate_no    VARCHAR(20) NOT NULL UNIQUE,
    make        VARCHAR(40) NOT NULL,
    model       VARCHAR(40) NOT NULL,
    color       VARCHAR(30),
    year        INT CHECK (year BETWEEN 1990 AND 2100)
);

CREATE TABLE trips (
    trip_id      SERIAL PRIMARY KEY,
    rider_id     INT NOT NULL REFERENCES riders(rider_id),
    driver_id    INT REFERENCES drivers(driver_id),   -- NULL until a driver accepts
    city_id      INT NOT NULL REFERENCES cities(city_id),
    pickup_addr  VARCHAR(200) NOT NULL,
    dropoff_addr VARCHAR(200) NOT NULL,
    status       VARCHAR(20)  NOT NULL DEFAULT 'requested'
                 CHECK (status IN ('requested','accepted','ongoing','completed','cancelled')),
    fare         DECIMAL(10,2) CHECK (fare >= 0),
    requested_at TIMESTAMP NOT NULL DEFAULT now(),
    started_at   TIMESTAMP,
    ended_at     TIMESTAMP,
    -- a trip can't start before it is requested, or end before it starts
    CHECK (started_at IS NULL OR started_at >= requested_at),
    CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE TABLE payments (
    payment_id  SERIAL PRIMARY KEY,
    trip_id     INT NOT NULL UNIQUE REFERENCES trips(trip_id),  -- one payment per trip
    amount      DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    method      VARCHAR(20) NOT NULL CHECK (method IN ('card','cash','wallet')),
    status      VARCHAR(20) NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','paid','failed','refunded')),
    paid_at     TIMESTAMP
);

CREATE TABLE ratings (
    rating_id   SERIAL PRIMARY KEY,
    trip_id     INT NOT NULL REFERENCES trips(trip_id),
    from_role   VARCHAR(10) NOT NULL CHECK (from_role IN ('rider','driver')),
    score       INT NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment     VARCHAR(300),
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (trip_id, from_role)   -- each side rates a trip only once
);
