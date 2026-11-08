#!/bin/bash
# Supalogi - start a 3-node MongoDB replica set on this laptop (Portfolio 5)
# Each node is a separate mongod with its own port and its own data folder,
# like three servers in three different places.
# Safe to run again: it only starts the nodes that are not running.
#   bash start-cluster.sh

DIR=${SUPALOGI_CLUSTER_DIR:-$HOME/supalogi-cluster}

for port in 27021 27022 27023; do
  if mongosh "mongodb://127.0.0.1:$port/?directConnection=true&serverSelectionTimeoutMS=1000" --quiet --eval 1 >/dev/null 2>&1; then
    echo "node $port: already running"
  else
    mkdir -p "$DIR/$port"
    if mongod --replSet supalogi-rs --port "$port" --bind_ip 127.0.0.1 \
         --dbpath "$DIR/$port" --logpath "$DIR/$port.log" \
         --wiredTigerCacheSizeGB 0.25 --fork >/dev/null; then
      echo "node $port: started"
    else
      echo "node $port: failed to start (see $DIR/$port.log)"
    fi
  fi
done
