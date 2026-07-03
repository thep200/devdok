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

web_port=${WEB_PORT:-'8080'}

# Create data directory
mkdir -p /vt/vtdataroot/vtorc

echo "Starting vtorc..."
exec /vt/bin/vtorc \
$TOPOLOGY_FLAGS \
--logtostderr=true \
--port $web_port \
--sqlite-data-file /vt/vtdataroot/vtorc.db \
--instance-poll-time 5s \
--topo-information-refresh-duration 15s \
--prevent-cross-cell-failover=false
