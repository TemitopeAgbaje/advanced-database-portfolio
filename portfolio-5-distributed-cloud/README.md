# Portfolio 5 — Distributed and Cloud Database Exercise

**Case study:** Supalogi (see [case-study.md](../case-study.md)), the same ride-hailing
platform as Portfolios 1–4.

Supalogi cannot stop working because one server breaks: riders in Lagos, Abuja and Accra
book trips all day. This portfolio sets up a **MongoDB replica set** (three copies of the
data on three servers) on my laptop, then breaks it on purpose to show **replication**,
**availability** (failover) and **consistency**. **Sharding** and **cloud deployment** are
covered as a design for Supalogi.

## The setup
```
                  writes + reads
   Supalogi app ─────────────────▶  PRIMARY   (27021)
                                      │   copies every change
                          ┌───────────┴───────────┐
                          ▼                       ▼
                    SECONDARY (27022)       SECONDARY (27023)
```
- Three `mongod` servers, each with its own port and its own data folder (`~/supalogi-cluster`).
- They form one replica set called `supalogi-rs`.
- Only the **primary** takes writes. The two **secondaries** copy every change from it.
- If the primary stops, the other two **vote** and one of them becomes the new primary.
  A node needs votes from a **majority** (2 of 3) to become primary.

## Files
| File | What it does |
|---|---|
| `start-cluster.sh` | Starts the 3 nodes (only the ones that are not already running) |
| `stop-cluster.sh` | Switches all 3 nodes off |
| `cluster.js` | Shared settings and helpers used by the scripts below |
| `setup.js` | Joins the 3 nodes into one replica set and loads 300 trips |
| `check.js` | Shows each node, its role (PRIMARY / SECONDARY / DOWN) and how many trips it holds |
| `add-trip.js` | Books one new trip with write concern `majority` |
| `stop-primary.js` | Switches off the primary and shows the new primary |
| `two-down.js` | Switches off 2 of the 3 nodes and tries to book a trip |

## How to run
MongoDB must be installed. These use ports 27021–27023, so they do not touch the normal
MongoDB on 27017. Run from this folder:

```bash
bash start-cluster.sh
mongosh --nodb setup.js          # 1. replication
mongosh --nodb stop-primary.js   # 2. failover
mongosh --nodb add-trip.js       # 3. still working with one node down
bash start-cluster.sh            # 4. bring the node back...
mongosh --nodb check.js          #    ...and check it caught up
mongosh --nodb two-down.js       # 5. consistency: no majority, no writes (takes about 40 s)
bash start-cluster.sh
bash stop-cluster.sh             # switch everything off when finished
```

## Testing
| Demo | What it shows | Evidence |
|---|---|---|
| 1. Replication | One primary, two secondaries, all three hold the same 300 trips | [1-replication.png](screenshots/1-replication.png) |
| 2. Failover | The primary is switched off and a secondary becomes the new primary within seconds | [2-failover.png](screenshots/2-failover.png) |
| 3. Still available | With one node down, a new trip is still booked and copied | [3-still-working.png](screenshots/3-still-working.png) |
| 4. Node rejoins | The stopped node comes back as a secondary and catches up on the trip it missed | [4-node-rejoined.png](screenshots/4-node-rejoined.png) |
| 5. No majority | With 2 of 3 nodes down, the last node will not take writes, but reads still work | [5-no-majority.png](screenshots/5-no-majority.png) |

## Consistency
- **Write concern `majority`:** `add-trip.js` only reports "saved" once at least 2 of the 3
  nodes have the trip. If the primary crashes straight after, the trip is not lost,
  because another node already has it.
- **Reads from a secondary can be behind:** a secondary copies changes a moment after the
  primary. That is fine for reports (trips per city), but a rider's live trip status and
  payments should be read from the primary.
- **Consistency over availability (demo 5):** with only 1 of 3 nodes left, MongoDB refuses
  writes rather than risk two nodes each thinking they are the primary and saving
  different data. This is the CAP trade-off: during a network split you can keep the data
  consistent or keep accepting writes, not both.

## Sharding design for Supalogi
Replication copies **all** the data to every node. Sharding **splits** the data, so each
shard holds only part of it. This matters once Supalogi has too many trips for one server.

| Choice | Decision | Reason |
|---|---|---|
| Collection to shard | `trips` | It grows every day; riders and drivers stay small |
| Shard key | `{ city: 1, _id: 1 }` | Most queries are per city (matching, reports), so they go to one shard |
| Zones | Lagos and Abuja → Nigeria shards, Accra → Ghana shard | Keeps each country's data in that country's region (Nigeria Data Protection Act 2023, Ghana Data Protection Act 2012) and close to its users |
| Avoid a hot shard | `_id` in the key splits Lagos (the busiest city) into many chunks | Lagos trips can spread over several shards inside the Nigeria zone |

Each shard would itself be a 3-node replica set like the one in this portfolio, so
sharding gives scale and replication gives availability.

## Cloud deployment
- Run MongoDB as a managed service (for example MongoDB Atlas) with the three replica set
  members in **three different availability zones**, so one data centre failing works like
  demo 2.
- Keep **payments in PostgreSQL** (Portfolio 3) on a managed service with a standby copy
  for failover, because money needs strict transactions.
- Back up every day and test restoring, because replication copies mistakes too (a wrong
  delete is deleted on every node).

## What I found
- **Replication (demo 1):** We keep 3 copies of the data so that if one server stops,
  Supalogi is still working and up.
- **Failover (demo 2):** When the primary went down, 27022 became the new primary, and the
  riders didn't lose any trips (300 before, 300 after).
- **Catching up (demo 4):** 27021 was off when trip 301 was booked. When it came back, it
  restored the missing trip from the other nodes and had 301 trips too.
- **No majority (demo 5):** Refusing to save trips is bad, because it affects the user
  experience, but it stops two servers each acting as the primary and saving different
  trips, so the data stays correct.
- **Sharding:** Splitting Lagos, Abuja and Accra onto different servers means downtime is
  specific and only affects certain places, not every city at once.
