// Supalogi - book one new trip through the replica set (Portfolio 5)
//   mongosh --nodb add-trip.js
load('cluster.js');

const db = new Mongo(RS_URI).getDB('supalogi');
const last = db.trips.find().sort({ _id: -1 }).limit(1).toArray()[0];
const id = last ? last._id + 1 : 1;

// w: 'majority' = only say "saved" once at least 2 of the 3 nodes have the trip
db.trips.insertOne(
  { _id: id, city: 'Lagos', rider: 'Dongo Manchi', driver: 'Seun Olajeyi', fare: 3500, status: 'requested' },
  { writeConcern: { w: 'majority', wtimeout: 5000 } }
);
print('Saved trip ' + id + ' on the primary ' + db.hello().primary + ' (w: majority)\n');

sleep(1000);
showNodes();
