# Supalogi — Normalisation Explanation

**Normalisation** means organising tables so the same fact is never stored twice.
This avoids wrong data and wasted space. Supalogi's design is in **3rd Normal Form (3NF)**.

## 1NF — First Normal Form
Every column holds a single value, and every row is unique.

- No column stores a list (e.g. we do NOT put all of a driver's trips in one cell).
- Each table has a primary key (`rider_id`, `driver_id`, `trip_id`, etc.).

## 2NF — Second Normal Form
Already in 1NF, and every non-key column depends on the **whole** key, not part of it.

- All our tables use a single-column key (like `trip_id`), so there are no "partial" keys to break this rule.
- A vehicle's details depend on `vehicle_id` only — not on a mix of columns.

## 3NF — Third Normal Form
Already in 2NF, and no non-key column depends on another non-key column.

- A `trip` stores `driver_id`, not the driver's name or phone. Driver details live only in `drivers`. Change a driver's phone once and every trip is correct.
- A `payment` stores `trip_id`, not the fare copied from the trip. The fare lives on `trips`.
- City details (name, country) live only in `cities`, referenced by `city_id`.

## Why it matters here
| Problem avoided | How the design avoids it |
|---|---|
| Update anomaly | Driver phone is stored once in `drivers`, not on every trip |
| Insert anomaly | A city can exist in `cities` before any trip uses it |
| Delete anomaly | Deleting a trip does not wipe out a driver or rider record |

## One deliberate exception (denormalisation)
`drivers.status` ('available' / 'on_trip') is a small cached value used for fast
driver-matching. It could be derived from active trips, but storing it directly
keeps the matching query (Portfolio 3) simple and fast. This is a conscious
trade-off, noted here for transparency.
