// Supalogi - switch off 2 of the 3 nodes: consistency vs availability (Portfolio 5)
// Run with all 3 nodes up.
//   mongosh --nodb two-down.js
load('cluster.js');

const primary = currentPrimary();
const others = NODES.filter(h => h !== primary);
print('Switching off ' + others.join(' and ') + '...');
for (const host of others) {
  try { nodeConn(host).getDB('admin').runCommand({ shutdown: 1, force: true }); } catch (e) {}
}

// The last node cannot see a majority (2 of 3), so it stops being primary.
sleep(6000);
print('');
showNodes();

print('\nTrying to book a trip on the last node (' + primary + ')...');
try {
  nodeConn(primary).getDB('supalogi').trips.insertOne(
    { _id: 99999, city: 'Accra', rider: 'Olayide Abass', status: 'requested' },
    { writeConcern: { w: 'majority', wtimeout: 5000 } }
  );
  print('Write worked');
} catch (e) {
  print('Write refused: ' + e.message);
}
print('Reading still works on ' + primary + ': ' + nodeConn(primary).getDB('supalogi').trips.countDocuments({}) + ' trips');
