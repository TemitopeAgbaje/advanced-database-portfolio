// Supalogi - join the 3 nodes into one replica set and load trips (Portfolio 5)
// Run after start-cluster.sh:
//   mongosh --nodb setup.js
load('cluster.js');

// 1. Make the 3 nodes one replica set (only the first time)
const admin = nodeConn(NODES[0]).getDB('admin');
let alreadySetUp = true;
try { admin.runCommand({ replSetGetStatus: 1 }); } catch (e) { alreadySetUp = false; }
if (!alreadySetUp) {
  admin.runCommand({ replSetInitiate: {
    _id: 'supalogi-rs',
    settings: { electionTimeoutMillis: 2000 },   // vote for a new primary after 2 s of silence (default is 10 s)
    members: NODES.map((host, i) => ({ _id: i, host: host }))
  } });
  print('Replica set supalogi-rs created');
}
const primary = waitForPrimary(30);
print('Primary: ' + primary);

// 2. Load 300 trips. They are written to the primary and copied to the other two.
const riders = ['Feranmi Oluwase', 'Olayide Abass', 'Dongo Manchi', 'Adaeze Adeyemi', 'Kwame Mensah', 'Halima Bello'];
const drivers = ['Seun Olajeyi', 'Tayo Makayu', 'Chibuzor Emeka', 'Kofi Asante', 'Musa Danjuma', 'Lanre Bello'];
const cities = ['Lagos', 'Abuja', 'Accra'];

const db = new Mongo(RS_URI).getDB('supalogi');
db.trips.drop();
const trips = [];
for (let i = 1; i <= 300; i++) {
  trips.push({
    _id: i,
    city: cities[i % 3],
    rider: riders[i % riders.length],
    driver: drivers[(i * 7) % drivers.length],
    fare: 1500 + (i * 37) % 7000,
    status: 'completed'
  });
}
db.trips.insertMany(trips, { writeConcern: { w: 'majority' } });
print('Loaded ' + db.trips.countDocuments({}) + ' trips\n');

sleep(1000);  // give the secondaries a moment to copy the last writes
showNodes();
