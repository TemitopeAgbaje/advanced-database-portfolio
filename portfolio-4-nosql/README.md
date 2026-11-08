# Portfolio 4 — NoSQL and Advanced Data Models

**Case study:** Supalogi (see [case-study.md](../case-study.md)), the same ride-hailing
platform as Portfolios 1–3, modelled in **MongoDB** (a document database).

## Files
| File | What it is |
|---|---|
| `load-data.js` | Creates the `supalogi` database: 200 riders, 60 drivers, 5,000 trips, plus indexes |
| `queries.js` | Six queries that show what the document model is good at |
| `queries-output.txt` | Output from my run of `queries.js` |

## The document model
Three collections instead of seven tables.

| Collection | One document is… | What is embedded inside it |
|---|---|---|
| `riders` | one rider | saved places (only some riders have them) |
| `drivers` | one driver | their vehicle, their live location (GeoJSON point) |
| `trips` | one whole trip | rider and driver name, pickup and dropoff, payment, ratings, status history |

A trip document looks like this (trip 1, shortened):
```js
{
  _id: 1, city: 'Lagos', status: 'completed',
  rider:  { id: 1, name: 'Feranmi Oluwase' },
  driver: { id: 1, name: 'Seun Olajeyi', plate: 'SPL-00001' },
  pickup: { area: 'Yaba', location: { type: 'Point', coordinates: [3.3792, 6.5095] } },
  fare: 4200,
  payment: { method: 'card', status: 'paid' },
  ratings: [ { from: 'rider', score: 5, comment: 'Smooth ride' }, { from: 'driver', score: 5 } ],
  status_history: [ { status: 'requested', at: ... }, { status: 'completed', at: ... } ]
}
```

### Embed or reference?
| Data | Choice | Reason |
|---|---|---|
| Payment, ratings, status history | Embedded in the trip | Always read with the trip; a trip has at most one payment and two ratings |
| Vehicle, live location | Embedded in the driver | One car per driver; location is read with the driver when matching |
| Rider and driver on a trip | Small copy (id + name) embedded, full profile in its own collection | The trip keeps a record of who rode; the profile can change without rewriting every trip |

### Compared with the PostgreSQL design (Portfolio 1)
| PostgreSQL | MongoDB |
|---|---|
| 7 tables, joined with foreign keys | 3 collections, related data embedded |
| Showing one trip needs 5 joins | One `findOne` |
| Every row has the same columns (NULL when empty) | Fields can be left out (cancelled trips have no `payment`) |
| Adding a field needs `ALTER TABLE` | Just add it (trip 2 has `stops` and `promo_code`) |

## The queries
| # | Supalogi question | MongoDB feature |
|---|---|---|
| Q1 | Show one trip with everything | Embedded document, no joins |
| Q2 | Nearest available drivers to a rider | `2dsphere` index, `$geoNear` |
| Q3 | A rider's latest trips | Compound index, `explain()`: COLLSCAN vs IXSCAN |
| Q4 | Trips and revenue per city | Aggregation pipeline (`$match`, `$group`) |
| Q5 | Trips with extra stops; trips with no payment | Flexible schema, `$exists` |
| Q6 | Two drivers accept the same ride | Atomic single-document update (`findOneAndUpdate`) |

## How to run
MongoDB must be running locally.

```bash
mongosh supalogi load-data.js
mongosh supalogi queries.js | tee queries-output.txt
```

## Testing
| Test | Evidence |
|---|---|
| Data loaded (counts) | [1-data-loaded.png](screenshots/1-data-loaded.png) |
| Q1 one full trip document (no joins) | [2-trip-document.png](screenshots/2-trip-document.png), [2-trip-document-2.png](screenshots/2-trip-document-2.png) |
| Q2 nearest drivers | [3-nearest-drivers.png](screenshots/3-nearest-drivers.png) |
| Q3 index vs full scan | [4-index-vs-scan.png](screenshots/4-index-vs-scan.png) |
| Q4 revenue per city | [5-aggregation.png](screenshots/5-aggregation.png) |
| Q5 flexible schema | [6-flexible-schema.png](screenshots/6-flexible-schema.png) |
| Q6 only one driver gets the ride | [7-atomic-accept.png](screenshots/7-atomic-accept.png) |

## What I found
- **One trip, no joins (Q1):** In PostgreSQL, showing one trip needed 5 joins. MongoDB
  needs fewer reads because everything is connected and added inside the trip document.
- **Nearest driver (Q2):** Finding the nearest driver means the rider waits less and the
  driver drives a shorter distance to pick them up.
- **Index (Q3):** Without the index MongoDB read all 5,000 trips to find 5. With the index it
  read only 5 (13 ms down to 0 ms), the same idea as Portfolio 2.
- **Flexible schema (Q5):** Adding something new to some trips, like stops or a promo code,
  is easy because MongoDB is flexible and uses documents. Cancelled trips simply have no
  payment field (546 cancelled = 546 with no payment).
- **Double booking (Q6):** In Portfolio 3 I needed BEGIN, a lock and ROLLBACK. In MongoDB it
  was one step, because the update only works if the ride is still requested. Seun got the
  ride and Chibuzor got "ride already taken".
- **Downside:** The rider's name is copied into every trip, and the copy does not update on
  its own. But the trip also keeps the rider's id, so we can always look up the right name.
- **Which one for Supalogi:** Both. PostgreSQL for payments, where money must be exact and
  safe (Portfolio 3), and MongoDB for trips and finding nearby drivers, where speed and
  flexibility matter.
