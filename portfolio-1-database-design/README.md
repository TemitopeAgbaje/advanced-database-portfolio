# Portfolio 1 — Database Design and Modelling

**Case study:** Supalogi, a ride-hailing platform that connects riders to drivers,
handles trips and payments, and collects ratings. Full description: [case-study.md](../case-study.md).

## Files
| File | What it is |
|---|---|
| `schema.dbml` | ER diagram source — paste into [dbdiagram.io](https://dbdiagram.io) to view/export the picture |
| `schema.sql` | PostgreSQL tables with keys, foreign keys, and constraints |
| `seed.sql` | Sample data to test the design |
| `normalisation.md` | Explanation of 1NF → 3NF |

## Tables
- **cities** — regions (used later for sharding)
- **riders** — people booking trips
- **drivers** — people driving
- **vehicles** — each driver's car
- **trips** — a booking linking one rider + one driver + one city
- **payments** — one payment per trip
- **ratings** — rider and driver each rate a trip once

## How to run
```bash
createdb -U postgres supalogi
psql -U postgres -d supalogi -f schema.sql
psql -U postgres -d supalogi -f seed.sql
```

## ER diagram
Paste `schema.dbml` into https://dbdiagram.io, then export the diagram as PNG and
save it here as `er-diagram.png` for the submission.
