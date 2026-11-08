// Supalogi - shared settings and helpers for the Portfolio 5 scripts.
// The other scripts load this file with load('cluster.js').

const NODES = ['127.0.0.1:27021', '127.0.0.1:27022', '127.0.0.1:27023'];

// One address for the whole replica set. The driver finds the primary by itself.
const RS_URI = 'mongodb://' + NODES.join(',') + '/supalogi?replicaSet=supalogi-rs&serverSelectionTimeoutMS=5000';

// Talk to ONE node only (used to check each copy separately).
function nodeConn(host) {
  return new Mongo('mongodb://' + host + '/?directConnection=true&serverSelectionTimeoutMS=1500&readPreference=secondaryPreferred');
}

// Print each node: is it up, is it the primary, and how many trips does its copy hold?
function showNodes() {
  print('node              role        trips   newest trip');
  for (const host of NODES) {
    let role = 'DOWN', trips = '-', newest = '-';
    try {
      const m = nodeConn(host);
      const hello = m.getDB('admin').runCommand({ hello: 1 });
      role = hello.isWritablePrimary ? 'PRIMARY' : (hello.secondary ? 'SECONDARY' : 'STARTING');
      const t = m.getDB('supalogi').trips;
      trips = t.countDocuments({});
      const last = t.find().sort({ _id: -1 }).limit(1).toArray()[0];
      newest = last ? last._id : '-';
    } catch (e) { /* node is switched off */ }
    print(host.padEnd(18) + role.padEnd(12) + String(trips).padEnd(8) + newest);
  }
}

// Ask each node directly "are you the primary?"
function currentPrimary() {
  for (const host of NODES) {
    try { if (nodeConn(host).getDB('admin').runCommand({ hello: 1 }).isWritablePrimary) return host; }
    catch (e) { /* node is switched off */ }
  }
  return null;
}

function waitForPrimary(seconds) {
  for (let i = 0; i < seconds; i++) {
    const p = currentPrimary();
    if (p) return p;
    sleep(1000);
  }
  return null;
}
