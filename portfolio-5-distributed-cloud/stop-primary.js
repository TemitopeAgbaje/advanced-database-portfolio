// Supalogi - switch off the primary and watch another node take over (Portfolio 5)
// This is what happens when the main server crashes.
//   mongosh --nodb stop-primary.js
load('cluster.js');

const oldPrimary = currentPrimary();
print('Primary is ' + oldPrimary + '. Switching it off...');
try {
  nodeConn(oldPrimary).getDB('admin').runCommand({ shutdown: 1, timeoutSecs: 5 });
} catch (e) { /* the connection closes when the node shuts down */ }

sleep(2000);
const newPrimary = waitForPrimary(30);
print('New primary: ' + newPrimary + ' (the other two nodes voted)\n');
showNodes();
