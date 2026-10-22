# Case Study: Supalogi

**Type:** Simulated ride-hailing platform

## What the business does
Supalogi is a ride-hailing platform operating in Lagos, Abuja and Accra. Riders
request trips from a mobile app, nearby available drivers accept them, and the
rider pays at the end of the trip. After each trip, the rider and the driver can
rate each other.

## Who uses the database
| User | How they use it |
|---|---|
| Riders | Sign up, request trips, pay, rate drivers |
| Drivers | Register with a vehicle, go online/offline, accept trips, rate riders |
| Operations staff | Run reports on trips, earnings, ratings and city activity |
| Matching service | Finds available drivers and assigns them to trip requests |

## Main data stored
- **Riders and drivers**: names, contact details, driver licence numbers
- **Vehicles**: plate number, make, model, colour, year
- **Cities**: the regions Supalogi operates in
- **Trips**: pickup, dropoff, status, fare, and timestamps
- **Payments**: amount, method (card, cash, wallet), status
- **Ratings**: a score from 1 to 5 plus an optional comment, from each side of a trip
- **Live driver locations**: frequent GPS updates (modelled in NoSQL, Portfolio 4)

## Key operations
1. **Book a trip**: the rider requests a trip and the system records it as `requested`
2. **Match a driver**: assign an available driver; the trip becomes `accepted`
3. **Run the trip**: the trip moves from `ongoing` to `completed` (or `cancelled`)
4. **Take payment**: charge the rider; if payment fails, undo the change
5. **Rate**: the rider and the driver each rate the trip once
6. **Report**: earnings per driver, trips per city, average ratings

## Why this case study
Ride-hailing covers every part of the course:
- **Relational design**: clear entities and relationships (Portfolio 1)
- **Query optimisation**: reporting over a large trips table (Portfolio 2)
- **Transactions and concurrency**: two riders competing for one driver, payment rollback (Portfolio 3)
- **NoSQL**: fast-changing location and trip-status data (Portfolio 4)
- **Distributed data**: splitting data by city, and replicating it for availability (Portfolio 5)
