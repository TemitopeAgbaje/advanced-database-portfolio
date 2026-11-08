# Portfolio 3 — Transactions and Concurrency

**Case study:** Supalogi (see [case-study.md](../case-study.md)). This portfolio uses the
tables from [Portfolio 1](../portfolio-1-database-design/) and the data from
[Portfolio 2](../portfolio-2-query-optimisation/).

## Files
| File | What it is |
|---|---|
| `setup.sql` | Creates 4 demo trips (IDs 900001–900004). Run before each demo to reset. |
| `1-commit.sql` | Ending a trip: trip, payment and driver updated together, then `COMMIT` |
| `2-rollback.sql` | A declined card: `ROLLBACK` by hand, and automatic rollback when a rule is broken |
| `3-double-booking.sql` | Two drivers accept the same ride: the lost update problem, fixed with `SELECT ... FOR UPDATE` |
| `4-isolation.sql` | `READ COMMITTED` vs `REPEATABLE READ` while a fare is being corrected |

## The demos
| # | Supalogi situation | Concept |
|---|---|---|
| 1 | A trip ends: mark it completed, record the payment, free the driver | Atomicity, `COMMIT` |
| 2 | The rider's card is declined halfway through | `ROLLBACK`, automatic rollback on error |
| 3 | Two drivers tap "accept" on the same request at the same moment | Lost update, row locking |
| 4 | An analyst reads a fare while support changes it | Isolation levels, non-repeatable read, serialization error |

## How to run
Needs the Portfolio 2 data loaded (`generate-data.sql`).

1. In pgAdmin: **Servers → PostgreSQL 15 → Databases → supalogi**, right-click → **Query Tool**.
2. Open `setup.sql` and press **F5**.
3. Open a demo file. Highlight one `STEP` at a time and press **F5**.
4. Demos 3 and 4 need **two** Query Tool tabs (open the Query Tool twice). Each tab is a
   separate connection, like two different users. Each step says which tab to use.

## Testing
| Test | Evidence |
|---|---|
| Demo trips created | [1-setup.png](screenshots/1-setup.png) |
| Commit: all three changes saved | [2-commit-after.png](screenshots/2-commit-after.png) |
| Rollback: trip unchanged after `ROLLBACK` | [3-rollback-after.png](screenshots/3-rollback-after.png) |
| Rollback on error: CHECK constraint stops the transaction | [4-rollback-error.png](screenshots/4-rollback-error.png) |
| Lost update: driver 20's accept overwritten by driver 21 | [5-lost-update.png](screenshots/5-lost-update.png) |
| Lock: Tab B waiting for Tab A | [6-lock-waiting.png](screenshots/6-lock-waiting.png) |
| Lock: driver 20 keeps the ride | [7-lock-result.png](screenshots/7-lock-result.png) |
| Read committed: fare changes inside one transaction | [8-read-committed.png](screenshots/8-read-committed.png) |
| Repeatable read: fare stays the same | [9-repeatable-read.png](screenshots/9-repeatable-read.png) |
| Repeatable read: update refused | [10-serialize-error.png](screenshots/10-serialize-error.png) |

## What I found

**1. Commit.** When a trip ends, the trip, payment and driver tables all need to update.
If only one updated, the data wouldn't match (e.g. a completed trip with no payment).
A transaction makes sure they all update together, or none do.

**2. Rollback.** A transaction is all or nothing. When the payment had an error, the whole
transaction group was cancelled, so the trip update was undone too.

**3. Double booking.** Without a lock, both drivers saw the ride as free, and driver 21
overwrote driver 20 (a lost update). With `FOR UPDATE`, driver 21 had to wait until
driver 20 finished, then saw the ride was already taken.

**4. Isolation.** In read committed, Tab A saw the fare change from 3000 to 4500 inside the
same transaction. In repeatable read, Tab A kept seeing 3000, like a photo, and the
database blocked its update because the data had changed.
