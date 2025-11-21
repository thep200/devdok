# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Vitess development environment using Docker Compose. Vitess is a database clustering system for horizontal scaling of MySQL. This setup creates a complete Vitess cluster with etcd for topology management, VTGate as the query router, VTCtld for cluster management, and multiple VTTablets managing MySQL instances.

## Quick Start with Makefile ⚡

**Recommended**: Use the Makefile for simplified cluster management:

```bash
make setup      # Full setup (start + initialize)
make help       # View all available commands
make health     # Check cluster health
make ui         # View all web interfaces
make connect    # Connect to MySQL
```

Common commands:
- `make start` - Start containers
- `make init` - Initialize cluster
- `make stop` - Stop containers
- `make clean` - Remove all data
- `make tablets` - Show tablet status
- `make fix` - Fix NOT_SERVING tablets
- `make test-failover` - Test failover

## Quick Start (Manual)

### First Time or After `docker-compose down -v`

When starting with no existing data:

1. Start the cluster:
   ```bash
   docker-compose up -d
   ```

2. **REQUIRED**: Initialize cluster (sets durability policies + elects primaries):
   ```bash
   ./init-cluster.sh
   ```

   ⚠️ **CRITICAL**: You **MUST** run `./init-cluster.sh` after:
   - First time setup
   - Running `docker-compose down -v` (which deletes all etcd data)
   - Any time tablets remain in NOT_SERVING state after 60 seconds

   Without this script:
   - Tablets will be NOT_SERVING
   - VTOrc will log continuous durability policy errors
   - Cluster cannot accept queries

3. Access the cluster:
   - MySQL protocol: `localhost:15306`
   - VTAdmin Web UI: http://localhost:14201 (cluster management dashboard)
   - VTAdmin API: http://localhost:14200 (REST API for cluster management)
   - VTOrc UI: http://localhost:13000/debug/status (automated failover)
   - VTGate debug UI: http://localhost:15099/debug/status
   - VTCtld debug UI: http://localhost:15000/debug/status
   - Tablet web UIs: http://localhost:15101 (vttablet101), etc.

**Important**: The `init-cluster.sh` script must be run after starting containers to elect primary tablets for each shard. Without this, tablets will remain in `NOT_SERVING` state.

**Note on Restarts**: After a restart, tablets usually restore their state automatically from etcd topology. However, if they remain in NOT_SERVING state after 60 seconds, run `./init-cluster.sh` again. See `RESTART_FIX.md` for details on the health check improvements made to handle restarts gracefully.

## Architecture

### Cluster Components

The docker-compose.yml defines a complete Vitess topology with:

- **etcd Cluster**: 3-node etcd cluster (etcd1, etcd2, etcd3) for topology storage
  - etcd1 exposed on port 2379/2380

- **VTCtld**: Control plane for cluster management
  - Web UI on port 15000
  - gRPC on port 15999
  - Command: `vtctld` with etcd2 topology implementation

- **VTGate**: Query routing and connection pooling
  - Web UI on port 15099
  - MySQL protocol on port 15306 (connect via mysql client)
  - gRPC on port 15999
  - Routes queries to appropriate tablets

- **VTTablets**: Manage individual MySQL instances
  - 6 tablets total across 2 keyspaces
  - Each tablet runs both `mysqlctld` (manages MySQL) and `vttablet` (Vitess tablet server)

- **VTOrc**: Orchestrator for automated failover and recovery
  - Web UI on port 13000
  - Continuously monitors tablet health across all keyspaces
  - Automatically performs failover when primaries fail
  - Configured with `durability_policy=none` for testing

- **VTAdmin**: REST API and Web UI for cluster management
  - API endpoint on port 14200
  - Web UI on port 14201 (custom HTML/JS interface)
  - Provides programmatic and visual access to:
    - Cluster overview and status
    - Keyspace and shard information
    - Tablet status and health
    - Schema definitions
    - VSchema configurations

### Keyspace Architecture

The cluster has 2 keyspaces:

1. **test_keyspace**: Sharded keyspace with hash-based sharding
   - Shard `-80`: vttablet101 (primary), vttablet102 (replica)
   - Shard `80-`: vttablet201 (primary), vttablet202 (replica)
   - Tables: `messages`, `tokens`
   - Uses xxhash sharding on the `page` column
   - Lookup vindexes for secondary indexes on `message` and `token` columns

2. **lookup_keyspace**: Unsharded keyspace for lookup tables
   - Shard `-`: vttablet301 (primary), vttablet302 (replica)
   - Tables: `messages_message_lookup`, `tokens_token_lookup`
   - Stores mappings for lookup vindexes

### VSchema Design

The VSchema (scripts/configs/test_keyspace_vschema.json) defines:
- Primary vindex: xxhash on `page` column for sharding
- Lookup vindexes: `messages_message_lookup` and `tokens_token_lookup` for secondary index support
- These enable queries by both `page` (sharding key) and `message`/`token` (lookup key)

The lookup keyspace VSchema is also sharded using xxhash on the `id` column.

## Common Commands

### Starting the Cluster

```bash
docker-compose up -d
```

This starts all services in dependency order. Wait for health checks to pass.

### Stopping the Cluster

```bash
docker-compose down
```

To also remove volumes:
```bash
docker-compose down -v
```

### Accessing VTGate via MySQL Protocol

```bash
mysql -h 127.0.0.1 -P 15306
```

Or use the convenience script:
```bash
./scripts/client.sh
```

### Using vtctldclient

The `lvtctl.sh` script provides convenient access to vtctldclient:

```bash
./scripts/lvtctl.sh <command> [args...]
```

Examples:
```bash
./scripts/lvtctl.sh GetTablets
./scripts/lvtctl.sh GetKeyspaces
./scripts/lvtctl.sh GetSrvVSchema test
```

Or directly with docker-compose:
```bash
docker-compose exec vtctld /vt/bin/vtctldclient --server vtctld:15999 <command>
```

### Viewing Logs

```bash
docker-compose logs -f <service_name>
```

Examples:
```bash
docker-compose logs -f vtgate
docker-compose logs -f vttablet101
docker-compose logs -f vtctld
```

### Accessing Web UIs

**Note**: Vitess 24.0+ does not have traditional web UIs. Instead, it provides debug/status endpoints.

**VTGate** (port 15099):
- Status page: http://localhost:15099/debug/status
- Query logs: http://localhost:15099/debug/querylogz
- Query analytics: http://localhost:15099/debug/queryz
- Query plans: http://localhost:15099/debug/query_plans
- VSchema viewer: http://localhost:15099/debug/vschema
- Metrics: http://localhost:15099/debug/vars

**VTCtld** (port 15000):
- Status page: http://localhost:15000/debug/status
- Metrics: http://localhost:15000/debug/vars

**Individual Tablets**:
- vttablet101: http://localhost:15101/debug/status
- vttablet102: http://localhost:15102/debug/status
- vttablet201: http://localhost:15201/debug/status
- vttablet202: http://localhost:15202/debug/status
- vttablet301: http://localhost:15301/debug/status
- vttablet302: http://localhost:15302/debug/status

### VTAdmin API

VTAdmin provides a REST API for cluster management on port 14200. The web UI is not included in the vitess/lite image, but the API is fully functional.

**Common API Endpoints:**

```bash
# List clusters
curl http://localhost:14200/api/clusters

# List keyspaces
curl http://localhost:14200/api/keyspaces

# List tablets
curl http://localhost:14200/api/tablets

# List schemas
curl http://localhost:14200/api/schemas

# Get VSchema for a keyspace
curl http://localhost:14200/api/vschema/local/test_keyspace

# List workflows
curl http://localhost:14200/api/workflows
```

**Configuration:**
- Discovery config: `scripts/vtadmin/discovery.json` (defines vtctld and vtgate endpoints)
- RBAC config: `scripts/vtadmin/rbac.yaml` (currently allows all access)

## Key Scripts

All scripts are in the `scripts/` directory and are mounted into containers at `/script`.

### vttablet-up.sh

Initializes and starts a vttablet. Called with tablet UID as argument (e.g., `101`, `201`).

Key responsibilities:
- Creates MySQL instance via mysqlctld (unless external DB)
- Registers tablet with topology
- Configures replication settings
- Handles both managed and external MySQL instances

Environment variables control behavior: `KEYSPACE`, `SHARD`, `ROLE`, `EXTERNAL_DB`, etc.

### schemaload.sh

Applies schema and VSchema to a keyspace. Runs once per keyspace after tablets are healthy.

Process:
1. Waits for target tablet to be available
2. Applies SQL schema files via `ApplySchema`
3. Applies VSchema JSON via `ApplyVSchema`
4. Optionally loads initial data

Controlled by: `SCHEMA_FILES`, `VSCHEMA_FILE`, `POST_LOAD_FILE`, `EXTERNAL_DB`

### Other Utility Scripts

- `client.sh`: Runs a Go client against VTGate
- `lvtctl.sh`: Wrapper for vtctldclient commands
- `lmysql.sh`: MySQL client wrapper for tablets
- `run-forever.sh`: Keeps processes running with restart logic

## Configuration Files

### Environment Variables (.env)

The `.env.example` file documents all configuration variables. Key sections:

- **Vitess Version**: `VITESS_VERSION` (uses AMD64 images with Rosetta on Apple Silicon)
- **Topology**: etcd configuration and cell definitions
- **Keyspaces**: Definitions for test_keyspace and lookup_keyspace
- **Tablet Configuration**: Per-tablet settings (ports, roles, shards)
- **External DB Support**: Settings for connecting to external MySQL

### VSchema Files (scripts/configs/)

- `test_keyspace_vschema.json`: Defines sharding and lookup vindexes for test_keyspace
- `lookup_keyspace_vschema.json`: Defines sharding for lookup tables
- `default_vschema.json`: Fallback VSchema

### Schema Files (scripts/sql/)

- `test_keyspace_schema_file.sql`: Creates messages and tokens tables
- `lookup_keyspace_schema_file.sql`: Creates lookup tables
- Individual table creation scripts: `create_messages.sql`, `create_tokens.sql`, etc.

## Development Workflow

### Making Schema Changes

1. Modify SQL files in `scripts/sql/`
2. Apply via vtctldclient:
   ```bash
   ./scripts/lvtctl.sh ApplySchema --sql-file /script/sql/your_file.sql test_keyspace
   ```

### Modifying VSchema

1. Edit JSON files in `scripts/configs/`
2. Apply changes:
   ```bash
   ./scripts/lvtctl.sh ApplyVSchema --vschema-file /script/configs/test_keyspace_vschema.json test_keyspace
   ```

### Testing Queries

Connect via VTGate and execute queries:
```bash
mysql -h 127.0.0.1 -P 15306 -e "SELECT * FROM messages WHERE page = 1"
```

VTGate will route to the correct shard based on the vindex.

### Debugging Tablet Issues

1. Check tablet health: `./scripts/lvtctl.sh GetTablets`
2. View tablet logs: `docker-compose logs -f vttablet101`
3. Check MySQL socket issues - the vttablet-up.sh script removes stale socket files on startup (common restart issue)
4. Access tablet directly: http://localhost:15101/debug/status

### Working with External MySQL

Set `EXTERNAL_DB=1` in .env and configure `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`. The vttablet-up.sh script handles external vs managed MySQL automatically. External primary tablets skip mysqlctld and connect directly to the remote database.

## Important Implementation Details

### Tablet UID Conventions

- 101, 102: test_keyspace shard -80
- 201, 202: test_keyspace shard 80-
- 301, 302: lookup_keyspace shard -
- X01: primary, X02: replica
- Every 3rd tablet (uid % 3 == 0) becomes rdonly type

### Topology Structure

- Topology root: `vitess/global` in etcd
- Cell: `test`
- Tablet aliases: `{cell}-{uid:010d}` (e.g., `test-0000000101`)

### Health Checks

- Tablets: HTTP GET to `localhost:8080/debug/health` every 30s
- VTCtld: HTTP GET to `localhost:8080/debug/status` every 30s
- External DB: MySQL connection test every 10s

### Replication Configuration

- MySQL configured with GTID mode enabled
- Binary logging enabled for replication
- Health check interval: 5s for tablets
