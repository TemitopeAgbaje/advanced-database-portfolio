#!/bin/bash
# Supalogi - switch off all 3 nodes when you are finished (Portfolio 5)
#   bash stop-cluster.sh

for port in 27021 27022 27023; do
  mongosh "mongodb://127.0.0.1:$port/?directConnection=true&serverSelectionTimeoutMS=1000" --quiet \
    --eval 'db.getSiblingDB("admin").runCommand({ shutdown: 1, force: true })' >/dev/null 2>&1
  echo "node $port: stopped"
done
