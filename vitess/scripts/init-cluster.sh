#!/bin/bash

# Initialize Vitess Cluster
# This script initializes the shard primaries after containers are started

set -e

echo "Waiting for vtctld to be healthy..."
until docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 GetKeyspaces > /dev/null 2>&1; do
    echo "Waiting for vtctld..."
    sleep 2
done

echo "Setting keyspace durability policies (required for VTOrc)..."
docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 SetKeyspaceDurabilityPolicy --durability-policy=none test_keyspace
docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 SetKeyspaceDurabilityPolicy --durability-policy=none lookup_keyspace

echo ""
echo "Initializing shard primaries..."

# Initialize test_keyspace/-80 with tablet 101 as primary
echo "  - Initializing test_keyspace/-80 with vttablet101 as primary..."
docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 PlannedReparentShard --new-primary test-0000000101 test_keyspace/-80

# Initialize test_keyspace/80- with tablet 201 as primary
echo "  - Initializing test_keyspace/80- with vttablet201 as primary..."
docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 PlannedReparentShard --new-primary test-0000000201 test_keyspace/80-

# Initialize lookup_keyspace/- with tablet 301 as primary
echo "  - Initializing lookup_keyspace/- with vttablet301 as primary..."
docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 PlannedReparentShard --new-primary test-0000000301 lookup_keyspace/-

echo ""
echo "Cluster initialization complete!"

echo ""
echo "Tablet status:"
docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 GetTablets

echo ""
echo "You can now connect to VTGate:"
echo "  - MySQL protocol: localhost:15306"
echo ""
echo "Web Interfaces:"
echo "  - VTAdmin Web UI: http://localhost:14201"
echo "  - VTAdmin API: http://localhost:14200/api/clusters"
echo "  - VTOrc (failover): http://localhost:13000/debug/status"
echo "  - VTGate status: http://localhost:15099/debug/status"
echo "  - VTCtld status: http://localhost:15000/debug/status"
echo "  - Query logs: http://localhost:15099/debug/querylogz"
echo "  - VSchema: http://localhost:15099/debug/vschema"
