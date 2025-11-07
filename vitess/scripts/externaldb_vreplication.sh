#!/bin/bash

# Copyright 2020 The Vitess Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

VTCTLD_SERVER=${VTCTLD_SERVER:-'vtctld:15999'}

# External database configuration
DB_HOST=${DB_HOST:-'localhost'}
DB_PORT=${DB_PORT:-3306}
DB_USER=${DB_USER:-'root'}
DB_PASS=${DB_PASS:-''}

# Timeout settings
TABLET_WAIT_TIMEOUT=${TABLET_WAIT_TIMEOUT:-300}  # 5 minutes
SCHEMA_WAIT_TIMEOUT=${SCHEMA_WAIT_TIMEOUT:-300}  # 5 minutes

echo "=========================================="
echo "Starting vreplication setup for external database"
echo "=========================================="
echo "External DB: $DB_HOST:$DB_PORT"
echo "VTCtld Server: $VTCTLD_SERVER"
echo ""

# Function to check if external primary tablet exists
check_external_primary() {
  /vt/bin/vtctldclient --server $VTCTLD_SERVER GetTablets 2>/dev/null | grep -q "ext_" && grep -q "primary" && return 0 || return 1
}

# Function to check if managed primary tablet exists
check_managed_primary() {
  /vt/bin/vtctldclient --server $VTCTLD_SERVER GetTablets 2>/dev/null | grep -v "ext_" | grep -q "primary" && return 0 || return 1
}

# Wait for external primary tablet with timeout
echo "Waiting for external primary tablet (timeout: ${TABLET_WAIT_TIMEOUT}s)..."
start_time=$(date +%s)
while ! check_external_primary; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if [ $elapsed -gt $TABLET_WAIT_TIMEOUT ]; then
    echo "❌ ERROR: Timeout waiting for external primary tablet after ${elapsed}s"
    exit 1
  fi

  echo "  ⏳ Waiting... ($elapsed/${TABLET_WAIT_TIMEOUT}s)"
  sleep 2
done
echo "✓ External primary tablet detected"

# Wait for managed primary tablet with timeout
echo "Waiting for managed primary tablet (timeout: ${TABLET_WAIT_TIMEOUT}s)..."
start_time=$(date +%s)
while ! check_managed_primary; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if [ $elapsed -gt $TABLET_WAIT_TIMEOUT ]; then
    echo "❌ ERROR: Timeout waiting for managed primary tablet after ${elapsed}s"
    exit 1
  fi

  echo "  ⏳ Waiting... ($elapsed/${TABLET_WAIT_TIMEOUT}s)"
  sleep 2
done
echo "✓ Managed primary tablet detected"

echo ""
echo "Retrieving tablet information..."

# Get source and destination tablet and shard information
TABLET_INFO=$(/vt/bin/vtctldclient --server $VTCTLD_SERVER GetTablets)

source_alias=$(echo "$TABLET_INFO" | grep "ext_" | grep "primary" | awk '{ print $1 }' | head -1)
dest_alias=$(echo "$TABLET_INFO" | grep -v "ext_" | grep "primary" | awk '{ print $1 }' | head -1)
source_keyspace=$(echo "$TABLET_INFO" | grep "ext_" | grep "primary" | awk '{ print $2 }' | head -1)
dest_keyspace=$(echo "$TABLET_INFO" | grep -v "ext_" | grep "primary" | awk '{ print $2 }' | head -1)
source_shard=$(echo "$TABLET_INFO" | grep "ext_" | grep "primary" | awk '{ print $3 }' | head -1)
dest_shard=$(echo "$TABLET_INFO" | grep -v "ext_" | grep "primary" | awk '{ print $3 }' | head -1)

if [ -z "$source_alias" ] || [ -z "$dest_alias" ]; then
  echo "❌ ERROR: Could not determine source or destination tablet alias"
  echo "Source: $source_alias"
  echo "Destination: $dest_alias"
  exit 1
fi

echo "Source: $source_alias ($source_keyspace/$source_shard)"
echo "Destination: $dest_alias ($dest_keyspace/$dest_shard)"
echo ""

# Disable foreign_key checks on destination
echo "Disabling foreign key checks on destination..."
if /vt/bin/vtctldclient --server $VTCTLD_SERVER ExecuteFetchAsDBA $dest_alias 'SET GLOBAL FOREIGN_KEY_CHECKS=0;' 2>/dev/null; then
  echo "✓ Foreign key checks disabled"
else
  echo "⚠️  Warning: Could not disable foreign key checks (may already be disabled)"
fi

# Get source SQL mode
echo ""
echo "Retrieving SQL mode from source..."
source_sql_mode=$(/vt/bin/vtctldclient --server $VTCTLD_SERVER ExecuteFetchAsDBA $source_alias 'SELECT @@GLOBAL.sql_mode' 2>/dev/null | awk 'NR==4 {print $2}')

if [ -z "$source_sql_mode" ]; then
  echo "⚠️  Warning: Could not retrieve SQL mode from source, using default"
  source_sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
fi
echo "Source SQL mode: $source_sql_mode"

# Apply source sql_mode to destination
# The intention is to avoid replication errors
echo "Applying SQL mode to destination..."
if /vt/bin/vtctldclient --server $VTCTLD_SERVER ExecuteFetchAsDBA $dest_alias "SET GLOBAL sql_mode='$source_sql_mode';" 2>/dev/null; then
  echo "✓ SQL mode applied to destination"
else
  echo "❌ ERROR: Failed to apply SQL mode to destination"
  exit 1
fi

# Verify sql_mode matches
dest_sql_mode=$(/vt/bin/vtctldclient --server $VTCTLD_SERVER ExecuteFetchAsDBA $dest_alias 'SELECT @@GLOBAL.sql_mode' 2>/dev/null | awk 'NR==4 {print $2}')

if [ "$source_sql_mode" = "$dest_sql_mode" ]; then
  echo "✓ SQL modes match between source and destination"
else
  echo "⚠️  Warning: SQL mode mismatch"
  echo "  Source: $source_sql_mode"
  echo "  Destination: $dest_sql_mode"
fi

# Wait for destination schema to be ready with timeout
echo ""
echo "Waiting for destination schema to be ready (timeout: ${SCHEMA_WAIT_TIMEOUT}s)..."
start_time=$(date +%s)
while ! /vt/bin/vtctldclient --server $VTCTLD_SERVER GetSchema $dest_alias >/dev/null 2>&1; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if [ $elapsed -gt $SCHEMA_WAIT_TIMEOUT ]; then
    echo "❌ ERROR: Timeout waiting for schema after ${elapsed}s"
    exit 1
  fi

  echo "  ⏳ Schema not ready yet... ($elapsed/${SCHEMA_WAIT_TIMEOUT}s)"
  sleep 3
done
echo "✓ Destination schema is ready"

# Start vreplication workflow
echo ""
echo "Creating vreplication workflow: ext_commerce2commerce"
if /vt/bin/vtctldclient --server $VTCTLD_SERVER MoveTables \
  --workflow ext_commerce2commerce \
  --target-keyspace $dest_keyspace \
  create \
  --source-keyspace $source_keyspace \
  --all-tables 2>&1; then
  echo "✓ Vreplication workflow created successfully"
else
  echo "❌ ERROR: Failed to create vreplication workflow"
  exit 1
fi

# Check vreplication status
echo ""
echo "Checking vreplication status..."
sleep 3

if /vt/bin/vtctldclient --server $VTCTLD_SERVER MoveTables \
  --workflow ext_commerce2commerce \
  --target-keyspace $dest_keyspace \
  show 2>&1; then
  echo "✓ Vreplication status retrieved"
else
  echo "⚠️  Warning: Could not retrieve vreplication status"
fi

echo ""
echo "=========================================="
echo "✓ Vreplication setup completed successfully"
echo "=========================================="
