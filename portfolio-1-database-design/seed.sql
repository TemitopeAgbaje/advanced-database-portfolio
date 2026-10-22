-- Supalogi - sample data so the design can be tested
-- Run after schema.sql:  psql -d supalogi -f seed.sql

INSERT INTO cities (name, country) VALUES
    ('Lagos', 'Nigeria'),
    ('Abuja', 'Nigeria'),
    ('Accra', 'Ghana');

INSERT INTO riders (full_name, email, phone) VALUES
    ('Ada Obi',     'ada@mail.com',   '+2348010000001'),
    ('Bola Ade',    'bola@mail.com',  '+2348010000002'),
    ('Chidi Nwosu', 'chidi@mail.com', '+2348010000003');

INSERT INTO drivers (full_name, email, phone, license_no, status) VALUES
    ('Emeka Udo',  'emeka@mail.com',  '+2348020000001', 'LIC-001', 'available'),
    ('Funke Ola',  'funke@mail.com',  '+2348020000002', 'LIC-002', 'available'),
    ('Kwame Mensah','kwame@mail.com',  '+2348020000003', 'LIC-003', 'offline');

INSERT INTO vehicles (driver_id, plate_no, make, model, color, year) VALUES
    (1, 'LAG-123AA', 'Toyota',  'Corolla', 'Silver', 2019),
    (2, 'LAG-456BB', 'Honda',   'Civic',   'Black',  2021),
    (3, 'ACC-789CC', 'Kia',     'Rio',     'White',  2020);

INSERT INTO trips (rider_id, driver_id, city_id, pickup_addr, dropoff_addr, status, fare, started_at, ended_at) VALUES
    (1, 1, 1, 'Ikeja',  'Lekki',       'completed', 3500.00, now() - interval '2 hour', now() - interval '1 hour'),
    (2, 2, 1, 'Yaba',   'Victoria Is', 'completed', 4200.00, now() - interval '3 hour', now() - interval '2 hour'),
    (3, 1, 2, 'Wuse',   'Maitama',     'completed', 2800.00, now() - interval '1 day',  now() - interval '1 day'),
    (1, NULL, 1, 'Surulere', 'Ikoyi',   'requested', NULL, NULL, NULL);

INSERT INTO payments (trip_id, amount, method, status, paid_at) VALUES
    (1, 3500.00, 'card',   'paid', now() - interval '1 hour'),
    (2, 4200.00, 'wallet', 'paid', now() - interval '2 hour'),
    (3, 2800.00, 'cash',   'paid', now() - interval '1 day');

INSERT INTO ratings (trip_id, from_role, score, comment) VALUES
    (1, 'rider',  5, 'Smooth ride'),
    (1, 'driver', 4, 'Polite rider'),
    (2, 'rider',  4, NULL),
    (3, 'rider',  5, 'On time');
