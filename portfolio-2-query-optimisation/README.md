# Portfolio 2 — Query Processing and Optimisation

**Case study:** Supalogi (see [case-study.md](../case-study.md)). This portfolio uses the
tables designed in [Portfolio 1](../portfolio-1-database-design/).

## Files
| File | What it is |
|---|---|
| `generate-data.sql` | Fills the tables with ~200,000 realistic trips so performance can be measured |
| `queries.sql` | Six business queries from the rider app, driver app, matching service and operations team |
| `optimisation.sql` | Before/after execution plans for each optimisation |
| `performance-analysis.md` | Results, what the plans show, and the trade-offs |

## The queries
| # | Who asks | Question | SQL features |
|---|---|---|---|
| Q1 | Rider app | My latest 20 trips | `WHERE`, `ORDER BY`, `LIMIT` |
| Q2 | Driver app | My earnings this week | `JOIN`, aggregate |
| Q3 | Matching service | Oldest waiting requests in a city | Filter on status, `ORDER BY` |
| Q4 | Operations | Top 10 earning drivers this month | 3-table `JOIN`, `GROUP BY` |
| Q5 | Operations | Trips and cancellation rate per city per month | `date_trunc`, `FILTER`, `GROUP BY` |
| Q6 | Quality team | Lowest-rated drivers | `JOIN`, `GROUP BY`, `HAVING` |

## How to run
Run from this folder. Note: `generate-data.sql` replaces the small Portfolio 1 sample data.

```bash
psql -U postgres -d supalogi -f ../portfolio-1-database-design/schema.sql
psql -U postgres -d supalogi -f generate-data.sql
psql -U postgres -d supalogi -f queries.sql
psql -U postgres -d supalogi -f optimisation.sql
```

## Optimisations
| Query | Technique |
|---|---|
| Q1 | Composite index on `trips (rider_id, requested_at DESC)` |
| Q2 | Composite index on `trips (driver_id, requested_at)` |
| Q3 | Partial index on waiting trips only |
| Q5 | Materialized view `city_monthly_stats` |
| Q4 | None — shown as a case where an index does not help |

Full results and explanation: [performance-analysis.md](performance-analysis.md).

## Testing
| Test | Evidence |
|---|---|
| Data generated (row counts) | [1-data-generated.png](screenshots/1-data-generated.png) |
| Query results | [2-query-results.png](screenshots/2-query-results.png) |
| Q1 plan before / after index | [3-q1-before-after.png](screenshots/3-q1-before-after.png) |
| Q2 plan before / after index | [4-q2-before-after.png](screenshots/4-q2-before-after.png) |
| Q3 plan before / after partial index | [5-q3-before-after.png](screenshots/5-q3-before-after.png) |
| Q5 before / after materialized view | [6-q5-before-after.png](screenshots/6-q5-before-after.png) |
| Q4 full scan still chosen, and index sizes | [7-q4-and-index-sizes.png](screenshots/7-q4-and-index-sizes.png) |
