// Supalogi - MongoDB queries (Portfolio 4: NoSQL)
// Run after load-data.js:
//   mongosh supalogi queries.js

// ---------------------------------------------------------------------------
print('\n=== Q1: one trip with everything (no joins) ===');
// In PostgreSQL this needs trips JOIN riders JOIN drivers JOIN vehicles JOIN payments JOIN ratings.
// Here it is one read, because the trip document already holds it all.
printjson(db.trips.findOne({ _id: 1 }));

// ---------------------------------------------------------------------------
print('\n=== Q2: nearest available drivers to a rider in Yaba (matching) ===');
// $geoNear uses the 2dsphere index and returns the distance in metres.
printjson(db.drivers.aggregate([
  { $geoNear: {
      near: { type: 'Point', coordinates: [3.3792, 6.5095] },
      distanceField: 'distance_m',
      maxDistance: 10000,
      query: { status: 'available' }
  } },
  { $limit: 3 },
  { $project: { _id: 0, name: 1, plate: '$vehicle.plate', distance_m: { $round: ['$distance_m', 0] } } }
]).toArray());

// ---------------------------------------------------------------------------
print('\n=== Q3: a rider\'s latest trips, with and without the index ===');
const q3 = { 'rider.id': 1 };
printjson(db.trips.find(q3, { _id: 1, city: 1, status: 1, fare: 1, requested_at: 1 })
  .sort({ requested_at: -1 }).limit(5).toArray());

// the deepest stage of the plan shows how documents were found: COLLSCAN (read all) or IXSCAN (index)
function firstStage(plan) {
  let p = plan.queryPlanner.winningPlan.queryPlan || plan.queryPlanner.winningPlan;
  while (p.inputStage) p = p.inputStage;
  return p.stage;
}
function summary(label, plan) {
  const s = plan.executionStats;
  print(label + ': stage=' + firstStage(plan)
    + ', docsExamined=' + s.totalDocsExamined + ', returned=' + s.nReturned
    + ', timeMs=' + s.executionTimeMillis);
}
// hint({ $natural: 1 }) forces a full collection scan, like a Seq Scan in PostgreSQL
summary('without index', db.trips.find(q3).sort({ requested_at: -1 }).limit(5).hint({ $natural: 1 }).explain('executionStats'));
summary('with index   ', db.trips.find(q3).sort({ requested_at: -1 }).limit(5).explain('executionStats'));

// ---------------------------------------------------------------------------
print('\n=== Q4: trips and revenue per city (aggregation pipeline) ===');
printjson(db.trips.aggregate([
  { $match: { status: 'completed', 'payment.status': 'paid' } },
  { $group: { _id: '$city', trips: { $sum: 1 }, revenue: { $sum: '$fare' }, avg_fare: { $avg: '$fare' } } },
  { $project: { city: '$_id', _id: 0, trips: 1, revenue: 1, avg_fare: { $round: ['$avg_fare', 0] } } },
  { $sort: { revenue: -1 } }
]).toArray());

// ---------------------------------------------------------------------------
print('\n=== Q5: flexible schema ===');
// Trip 2 has stops and a promo code. No other trip has these fields, and no ALTER TABLE was needed.
printjson(db.trips.find({ stops: { $exists: true } }, { _id: 1, stops: 1, promo_code: 1 }).toArray());
// Cancelled trips simply leave out the payment field instead of storing NULLs.
print('trips with no payment field: ' + db.trips.countDocuments({ payment: { $exists: false } }));
print('cancelled trips:             ' + db.trips.countDocuments({ status: 'cancelled' }));

// ---------------------------------------------------------------------------
print('\n=== Q6: two drivers accept the same ride (atomic update) ===');
// Same problem as Portfolio 3 Demo 3. In MongoDB an update to ONE document is atomic,
// and the filter status: 'requested' means only the first driver can match.
db.trips.deleteOne({ _id: 9001 });
db.trips.insertOne({
  _id: 9001, city: 'Lagos', status: 'requested',
  rider: { id: 3, name: 'Dongo Manchi' },
  pickup: { area: 'Ikeja', location: { type: 'Point', coordinates: [3.3515, 6.6018] } },
  dropoff: { area: 'Surulere', location: { type: 'Point', coordinates: [3.3569, 6.4969] } },
  requested_at: new Date(),
  status_history: [{ status: 'requested', at: new Date() }]
});

function accept(driverId, name) {
  return db.trips.findOneAndUpdate(
    { _id: 9001, status: 'requested' },
    { $set: { status: 'accepted', driver: { id: driverId, name: name } },
      $push: { status_history: { status: 'accepted', at: new Date() } } },
    { returnDocument: 'after' }
  );
}
const first = accept(1, 'Seun Olajeyi');
print('Seun accepts:  ' + (first ? 'got the ride' : 'ride already taken'));
const second = accept(3, 'Chibuzor Emeka');
print('Chibuzor accepts: ' + (second ? 'got the ride' : 'ride already taken'));
printjson(db.trips.findOne({ _id: 9001 }, { status: 1, driver: 1, status_history: 1 }));
