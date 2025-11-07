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

set -u

external=${EXTERNAL_DB:-0}
web_port=${WEB_PORT:-'8080'}
config=${VTORC_CONFIG:-/vt/vtorc/config.json}

# External DB configuration
db_host=${DB_HOST:-'localhost'}
db_port=${DB_PORT:-3306}
db_user=${DB_USER:-'root'}
db_pass=${DB_PASS:-''}

# Copy config file
mkdir -p /vt/vtorc
cp /script/configs/default.json /vt/vtorc/default.json

# Update credentials based on database type
if [ "$external" = "1" ]; then
    echo "Configuring vtorc for external database at ${db_host}:${db_port}..."

    # For external database, we need to ensure vtorc can connect
    # Parse and update the config file with external database credentials

    cp /vt/vtorc/default.json /vt/vtorc/config.json

    # Since we don't have jq, we'll create a new config with proper settings
    cat > /vt/vtorc/config.json <<EOF
{
  "Debug": false,
  "ListenAddress": ":3000",
  "MySQLOrchestratorHost": "${db_host}",
  "MySQLOrchestratorPort": ${db_port},
  "MySQLOrchestratorUser": "${db_user}",
  "MySQLOrchestratorPassword": "${db_pass}",
  "MySQLConnectTimeoutSeconds": 5,
  "MySQLReadTimeoutSeconds": 30,
  "MySQLWriteTimeoutSeconds": 30,
  "MySQLMaxOpenConnections": 25,
  "DefaultInstancePort": 3306,
  "ReplicationLagQuery": "SELECT EXTRACT(EPOCH FROM (NOW() - pg_last_xact_replay_timestamp())) as lag",
  "ReplicationLagMaxSeconds": 0,
  "MaxPoolConnections": 3,
  "Environments": null,
  "EnableGTID": true,
  "RecoverMasterClusterFilters": ["*"],
  "RecoverIntermediateClusterFilters": ["*"],
  "OnFailureDetectionProcesses": [],
  "PreFailoverProcesses": [],
  "PostFailoverProcesses": [],
  "PostUnsuccessfulFailoverProcesses": [],
  "PostMasterFailoverProcesses": [],
  "PostIntermediateFailoverProcesses": []
}
EOF

    echo "Updated vtorc config for external database"
else
    echo "Configuring vtorc for self-managed database..."
    cp /vt/vtorc/default.json /vt/vtorc/config.json
fi

echo "Starting vtorc..."
exec /vt/bin/vtorc \
$TOPOLOGY_FLAGS \
--logtostderr \
--alsologtostderr \
--config-path=/vt \
--config-name=vtorc/config \
--config-type=json \
--port $web_port
