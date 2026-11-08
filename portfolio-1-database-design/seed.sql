-- Supalogi - sample data so the design can be tested
-- Run after schema.sql:  psql -U postgres -d supalogi -f seed.sql

INSERT INTO cities (name, country) VALUES
    ('Lagos', 'Nigeria'),
    ('Abuja', 'Nigeria'),
    ('Accra', 'Ghana');

INSERT INTO riders (full_name, email, phone) VALUES
    ('Feranmi Oluwase', 'feranmi@mail.com', '+2348010000001'),
    ('Olayide Abass',   'olayide@mail.com', '+2348010000002'),
    ('Dongo Manchi',    'dongo@mail.com',   '+2348010000003');

INSERT INTO drivers (full_name, email, phone, license_no, status) VALUES
    ('Seun Olajeyi',    'seun@mail.com',     '+2348020000001', 'LIC-001', 'available'),
    ('Tayo Makayu',     'tayo@mail.com',     '+2348020000002', 'LIC-002', 'available'),
    ('Chibuzor Emeka',  'chibuzor@mail.com', '+2348020000003', 'LIC-003', 'offline');

INSERT INTO vehicles (driver_id, plate_no, make, model, color, year) VALUES
    (1, 'LAG-123AA', 'Toyota',  'Corolla', 'Silver', 2019),
    (2, 'LAG-456BB', 'Honda',   'Civic',   'Black',  2021),
    (3, 'ACC-789CC', 'Kia',     'Rio',     'White',  2020);

-- Times follow the trip's real order: requested -> started -> ended
INSERT INTO trips (rider_id, driver_id, city_id, pickup_addr, dropoff_addr, status, fare, requested_at, started_at, ended_at) VALUES
    (1, 1, 1, 'Ikeja',  'Lekki',       'completed', 3500.00, now() - interval '130 minutes', now() - interval '2 hours', now() - interval '1 hour'),
    (2, 2, 1, 'Yaba',   'Victoria Is', 'completed', 4200.00, now() - interval '190 minutes', now() - interval '3 hours', now() - interval '2 hours'),
    (3, 1, 2, 'Wuse',   'Maitama',     'completed', 2800.00, now() - interval '1450 minutes', now() - interval '1 day', now() - interval '1400 minutes'),
    (1, NULL, 1, 'Surulere', 'Ikoyi',   'requested', NULL, now(), NULL, NULL);

INSERT INTO payments (trip_id, amount, method, status, paid_at) VALUES
    (1, 3500.00, 'card',   'paid', now() - interval '1 hour'),
    (2, 4200.00, 'wallet', 'paid', now() - interval '2 hour'),
    (3, 2800.00, 'cash',   'paid', now() - interval '1 day');

INSERT INTO ratings (trip_id, from_role, score, comment) VALUES
    (1, 'rider',  5, 'Smooth ride'),
    (1, 'driver', 4, 'Polite rider'),
    (2, 'rider',  4, NULL),
    (3, 'rider',  5, 'On time');
