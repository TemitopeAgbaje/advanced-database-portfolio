// Supalogi - MongoDB document model (Portfolio 4: NoSQL)
// The same case study as Portfolios 1-3, stored as documents instead of tables.
// Replaces the supalogi database every time it runs:
//   mongosh supalogi load-data.js

db.dropDatabase();

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function minutesAgo(m) { return new Date(Date.now() - m * 60 * 1000); }

// GeoJSON points are [longitude, latitude]
const cities = {
  Lagos: { Ikeja: [3.3515, 6.6018], Lekki: [3.4746, 6.4474], Yaba: [3.3792, 6.5095], Surulere: [3.3569, 6.4969] },
  Abuja: { Wuse: [7.4689, 9.0765], Maitama: [7.4951, 9.0882], Garki: [7.4833, 9.0333], Gwarinpa: [7.4114, 9.1099] },
  Accra: { Osu: [-0.1820, 5.5560], 'Airport City': [-0.1736, 5.6052], 'East Legon': [-0.1528, 5.6352], Madina: [-0.1668, 5.6837] }
};
const cityNames = Object.keys(cities);

// a point near an area, so drivers are spread out instead of stacked on one spot
function near(coords) {
  return { type: 'Point', coordinates: [coords[0] + (Math.random() - 0.5) * 0.04, coords[1] + (Math.random() - 0.5) * 0.04] };
}

// ---------------------------------------------------------------------------
// riders: profile only. Saved places is an array - not every rider has one.
// ---------------------------------------------------------------------------
const riderNames = ['Feranmi Oluwase', 'Olayide Abass', 'Dongo Manchi'];
const riders = [];
for (let i = 1; i <= 200; i++) {
  const rider = { _id: i, name: riderNames[i - 1] || 'Rider ' + i, phone: '+23480' + String(i).padStart(8, '0') };
  if (i % 3 === 0) {
    rider.saved_places = [{ label: 'Home', area: 'Yaba' }, { label: 'Work', area: 'Lekki' }];
  }
  riders.push(rider);
}
db.riders.insertMany(riders);

// ---------------------------------------------------------------------------
// drivers: the vehicle is embedded (one car per driver) and so is the live location
// ---------------------------------------------------------------------------
const driverNames = ['Seun Olajeyi', 'Tayo Makayu', 'Chibuzor Emeka'];
const drivers = [];
for (let i = 1; i <= 60; i++) {
  const city = cityNames[i % 3];
  drivers.push({
    _id: i,
    name: driverNames[i - 1] || 'Driver ' + i,
    city: city,
    status: pick(['available', 'available', 'on_trip', 'offline']),
    vehicle: { plate: 'SPL-' + String(i).padStart(5, '0'), make: pick(['Toyota', 'Honda', 'Kia']), color: pick(['Black', 'Silver', 'White']) },
    location: near(pick(Object.values(cities[city])))
  });
}
db.drivers.insertMany(drivers);

// ---------------------------------------------------------------------------
// trips: one document holds the whole trip - rider, driver, payment, ratings, history
// ---------------------------------------------------------------------------
const trips = [];

// trip 1: a hand-written example to show the full shape
trips.push({
  _id: 1,
  city: 'Lagos',
  status: 'completed',
  rider: { id: 1, name: 'Feranmi Oluwase' },
  driver: { id: 1, name: 'Seun Olajeyi', plate: 'SPL-00001' },
  pickup: { area: 'Yaba', location: { type: 'Point', coordinates: cities.Lagos.Yaba } },
  dropoff: { area: 'Lekki', location: { type: 'Point', coordinates: cities.Lagos.Lekki } },
  fare: 4200,
  requested_at: minutesAgo(90), started_at: minutesAgo(82), ended_at: minutesAgo(45),
  payment: { method: 'card', status: 'paid', paid_at: minutesAgo(45) },
  ratings: [
    { from: 'rider', score: 5, comment: 'Smooth ride' },
    { from: 'driver', score: 5 }
  ],
  status_history: [
    { status: 'requested', at: minutesAgo(90) },
    { status: 'accepted', at: minutesAgo(88) },
    { status: 'ongoing', at: minutesAgo(82) },
    { status: 'completed', at: minutesAgo(45) }
  ]
});

// trip 2: a multi-stop trip with a promo code - extra fields, no schema change needed
trips.push({
  _id: 2,
  city: 'Abuja',
  status: 'completed',
  rider: { id: 2, name: 'Olayide Abass' },
  driver: { id: 2, name: 'Tayo Makayu', plate: 'SPL-00002' },
  pickup: { area: 'Wuse', location: { type: 'Point', coordinates: cities.Abuja.Wuse } },
  stops: [{ area: 'Garki', location: { type: 'Point', coordinates: cities.Abuja.Garki } }],
  dropoff: { area: 'Maitama', location: { type: 'Point', coordinates: cities.Abuja.Maitama } },
  promo_code: 'SUPA20',
  fare: 3600,
  requested_at: minutesAgo(300), started_at: minutesAgo(292), ended_at: minutesAgo(240),
  payment: { method: 'wallet', status: 'paid', paid_at: minutesAgo(240) },
  ratings: [{ from: 'rider', score: 4 }],
  status_history: [
    { status: 'requested', at: minutesAgo(300) },
    { status: 'completed', at: minutesAgo(240) }
  ]
});

// trips 3-5000: generated past trips over the last 90 days, ~12% cancelled
for (let i = 3; i <= 5000; i++) {
  const city = pick(cityNames);
  const areas = Object.keys(cities[city]);
  const from = pick(areas);
  const to = pick(areas.filter(a => a !== from));
  const riderId = 1 + Math.floor(Math.random() * 200);
  const requested = minutesAgo(Math.random() * 90 * 24 * 60);
  const trip = {
    _id: i,
    city: city,
    rider: { id: riderId, name: riders[riderId - 1].name },
    pickup: { area: from, location: { type: 'Point', coordinates: cities[city][from] } },
    dropoff: { area: to, location: { type: 'Point', coordinates: cities[city][to] } },
    requested_at: requested
  };

  if (Math.random() < 0.12) {
    // a cancelled trip simply has no driver, fare, payment or ratings fields
    trip.status = 'cancelled';
    trip.status_history = [{ status: 'requested', at: requested }, { status: 'cancelled', at: new Date(requested.getTime() + 3 * 60000) }];
  } else {
    const d = drivers[Math.floor(Math.random() * 60)];
    const started = new Date(requested.getTime() + (2 + Math.random() * 10) * 60000);
    const ended = new Date(started.getTime() + (10 + Math.random() * 50) * 60000);
    trip.status = 'completed';
    trip.driver = { id: d._id, name: d.name, plate: d.vehicle.plate };
    trip.fare = Math.round((1500 + Math.random() * 7500) / 10) * 10;
    trip.started_at = started;
    trip.ended_at = ended;
    trip.payment = { method: pick(['card', 'cash', 'wallet']), status: Math.random() < 0.05 ? 'failed' : 'paid' };
    trip.ratings = Math.random() < 0.7 ? [{ from: 'rider', score: pick([3, 4, 4, 5, 5, 5]) }] : [];
    trip.status_history = [{ status: 'requested', at: requested }, { status: 'completed', at: ended }];
  }
  trips.push(trip);
}
db.trips.insertMany(trips);

// ---------------------------------------------------------------------------
// indexes
// ---------------------------------------------------------------------------
db.trips.createIndex({ 'rider.id': 1, requested_at: -1 });  // a rider's trip history, newest first
db.drivers.createIndex({ location: '2dsphere' });            // find drivers near a point

print('riders:  ' + db.riders.countDocuments());
print('drivers: ' + db.drivers.countDocuments());
print('trips:   ' + db.trips.countDocuments());
