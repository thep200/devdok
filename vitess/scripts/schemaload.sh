#!/bin/bash -e

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

sleeptime=${SLEEPTIME:-0}
targettab=${TARGETTAB:-"${CELL}-0000000101"}
schema_files=${SCHEMA_FILES:-'create_messages.sql create_tokens.sql'}
vschema_file=${VSCHEMA_FILE:-'default_vschema.json'}
load_file=${POST_LOAD_FILE:-''}
external_db=${EXTERNAL_DB:-'0'}
export PATH=/vt/bin:$PATH

# External DB configuration
db_host=${DB_HOST:-''}
db_port=${DB_PORT:-3306}
db_user=${DB_USER:-''}
db_pass=${DB_PASS:-''}

sleep $sleeptime

if [ ! -f /vt/schema_run ]; then
  while true; do
    vtctldclient --server vtctld:$GRPC_PORT GetTablet $targettab && break
    sleep 1
  done

  # Apply schema files based on database type
  if [ "$external_db" = "1" ]; then
    # For external database, load schemas directly via mysql
    echo "Loading schemas directly to external database at ${db_host}:${db_port}..."

    # Validate external DB credentials
    if [ -z "$db_host" ] || [ -z "$db_user" ]; then
      echo "ERROR: External database credentials not set (DB_HOST=$db_host, DB_USER=$db_user)"
      exit 1
    fi

    for schema_file in $schema_files; do
      if [ -f "/script/sql/${schema_file}" ]; then
        echo "Applying Schema ${schema_file} to database ${KEYSPACE}"
        mysql \
          --host="${db_host}" \
          --port="${db_port}" \
          --user="${db_user}" \
          --password="${db_pass}" \
          --database="${KEYSPACE}" \
          < /script/sql/${schema_file} || {
          echo "WARNING: Failed to apply ${schema_file}, continuing..."
          true
        }
      else
        echo "WARNING: Schema file /script/sql/${schema_file} not found"
      fi
    done
  else
    # For self-managed database, use vtctldclient
    for schema_file in $schema_files; do
      if [ -f "/script/sql/${schema_file}" ]; then
        echo "Applying Schema ${schema_file} to ${KEYSPACE}"
        vtctldclient --server vtctld:$GRPC_PORT ApplySchema --sql-file /script/sql/${schema_file} $KEYSPACE || \
        vtctldclient --server vtctld:$GRPC_PORT ApplySchema --sql "$(cat /script/sql/${schema_file})" $KEYSPACE || {
          echo "WARNING: Failed to apply ${schema_file}, continuing..."
          true
        }
      else
        echo "WARNING: Schema file /script/sql/${schema_file} not found"
      fi
    done
  fi

  echo "Applying VSchema ${vschema_file} to ${KEYSPACE}"
  if [ -f "/script/configs/${vschema_file}" ]; then
    vtctldclient --server vtctld:$GRPC_PORT ApplyVSchema --vschema-file /script/configs/${vschema_file} $KEYSPACE || \
    vtctldclient --server vtctld:$GRPC_PORT ApplyVSchema --vschema "$(cat /script/configs/${vschema_file})" $KEYSPACE || true
  else
    echo "WARNING: VSchema file /script/configs/${vschema_file} not found"
  fi

  echo "List All Tablets"
  vtctldclient --server vtctld:$GRPC_PORT GetTablets

  if [ -n "$load_file" ]; then
    # vtgate can take a REALLY long time to come up fully
    sleep 60
    if [ -f "/script/configs/$load_file" ]; then
      mysql --port=15306 --host=vtgate < /script/configs/$load_file || true
    else
      echo "WARNING: Post-load file /script/configs/$load_file not found"
    fi
  fi

  touch /vt/schema_run
  echo "Time: $(date). SchemaLoad completed at $(date "+%FT%T") " >> /vt/schema_run
  echo "Done Loading Schema at $(date "+%FT%T")"
fi
