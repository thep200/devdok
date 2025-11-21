# Vitess Docker Compose Setup

Complete Vitess cluster with VTGate, VTCtld, VTOrc, VTAdmin, and 6 VTTablets.

## Quick Start with Makefile ⚡

The easiest way to manage the cluster:

```bash
# First time setup
make setup          # Starts containers and initializes cluster

# View all available commands
make help

# Check cluster health
make health

# View web interfaces
make ui

# Connect to MySQL
make connect
```

## Quick Start (Manual)

### First Time Setup or After `docker-compose down -v`

When starting fresh (no existing data):

```bash
# 1. Start all containers
docker-compose up -d

# 2. Wait for containers to be healthy (about 30 seconds)
docker-compose ps

# 3. Initialize cluster (REQUIRED - sets policies and elects primaries)
./init-cluster.sh
```

**Important**: `./init-cluster.sh` is **REQUIRED** after:
- First time setup
- Running `docker-compose down -v` (which deletes all data)
- Any situation where etcd data is lost

### Regular Restart (with existing data)

If you're just restarting containers without deleting data:

```bash
# Stop containers
docker-compose down

# Start containers
docker-compose up -d

# Usually cluster restores automatically, but if tablets remain NOT_SERVING after 60s:
./init-cluster.sh
```

## What `init-cluster.sh` Does

The initialization script performs these critical steps:

1. **Waits for vtctld** to be healthy
2. **Sets durability policies** for all keyspaces (required for VTOrc)
3. **Elects primary tablets** for each shard using PlannedReparentShard
4. **Displays cluster status** to verify everything is working

Without this script:
- ❌ Tablets remain in NOT_SERVING state
- ❌ VTOrc logs continuous errors about missing durability policies
- ❌ Cluster cannot accept queries

## Access Points

After initialization, access the cluster at:

- **MySQL protocol**: `localhost:15306`
  ```bash
  mysql -h 127.0.0.1 -P 15306
  ```

- **VTAdmin Web UI**: http://localhost:14201
  - Visual dashboard for cluster management
  - View tablets, keyspaces, schemas, and VSchema

- **VTAdmin API**: http://localhost:14200/api/clusters
  - REST API for programmatic access

- **VTOrc**: http://localhost:13000/debug/status
  - Automated failover orchestrator
  - View recovery actions and cluster health

- **VTGate**: http://localhost:15099/debug/status
  - Query router status and logs

- **VTCtld**: http://localhost:15000/debug/status
  - Control plane status

- **Individual tablets**: http://localhost:15101, 15102, 15201, 15202, 15301, 15302

## Cluster Architecture

### Keyspaces

1. **test_keyspace** (sharded)
   - Shard `-80`: vttablet101 (primary), vttablet102 (replica)
   - Shard `80-`: vttablet201 (primary), vttablet202 (replica)
   - Uses xxhash sharding on `page` column
   - Tables: `messages`, `tokens`

2. **lookup_keyspace** (unsharded)
   - Shard `-`: vttablet301 (primary), vttablet302 (replica)
   - Tables: `messages_message_lookup`, `tokens_token_lookup`
   - Stores lookup vindex mappings

### Components

- **etcd cluster** (3 nodes): Topology storage
- **VTCtld**: Control plane for cluster management
- **VTGate**: Query router and MySQL protocol gateway
- **VTTablets** (6): Manage individual MySQL instances
- **VTOrc**: Automated failover and recovery
- **VTAdmin API + Web UI**: Cluster management interface

## Common Commands

### Check cluster status
```bash
docker-compose ps
```

### View tablet status
```bash
./scripts/lvtctl.sh GetTablets
```

### Check VTOrc logs
```bash
docker-compose logs vtorc --tail 50
```

### Connect to MySQL
```bash
mysql -h 127.0.0.1 -P 15306
```

### Stop cluster (keep data)
```bash
docker-compose down
```

### Stop cluster (delete all data)
```bash
docker-compose down -v
```

**Warning**: After `docker-compose down -v`, you must run `./init-cluster.sh` to reinitialize.

## Troubleshooting

### Tablets show "unhealthy" status
Wait 30-40 seconds for health checks to pass. The health check uses `/debug/status` which checks if vttablet process is running (not if it's serving traffic).

### Tablets in NOT_SERVING state
Run the initialization script:
```bash
./init-cluster.sh
```

### VTOrc logs "ignoring keyspace because no durability_policy is set"
This means durability policies weren't set. Fix by running:
```bash
./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=none test_keyspace
./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=none lookup_keyspace
```

Or simply run `./init-cluster.sh` which sets these automatically.

### Can't connect to MySQL on port 15306
1. Check VTGate is running: `docker-compose ps vtgate`
2. Check tablets are SERVING: `./scripts/lvtctl.sh GetTablets`
3. If tablets are NOT_SERVING, run: `./init-cluster.sh`

## Development Workflow

### Making schema changes
```bash
# View current schema
./scripts/lvtctl.sh GetSchema test_keyspace

# Apply schema change (example)
./scripts/lvtctl.sh ApplySchema --sql "ALTER TABLE messages ADD COLUMN created_at TIMESTAMP" test_keyspace
```

### Testing failover
```bash
# Check current primaries
./scripts/lvtctl.sh GetTablets

# Stop a primary
docker-compose stop vttablet101

# Watch VTOrc perform automatic failover
docker-compose logs vtorc -f

# Restart the tablet
docker-compose start vttablet101
```

## Documentation

- **CLAUDE.md**: Comprehensive guide for AI assistants
- **RESTART_FIX.md**: Details on health check improvements
- **VTORC_INFO.md**: VTOrc configuration and failover testing
- **VTADMIN_API.md**: VTAdmin REST API documentation
- **VTADMIN_WEB_UI.md**: Web interface guide
- **.env.example**: All configuration variables

## Environment Variables

Copy `.env.example` to `.env` to customize:
- Vitess version
- Port mappings
- Keyspace configurations
- Durability policies

## Important Notes

1. **Always run `./init-cluster.sh` after `docker-compose down -v`**
2. Health checks pass when vttablet process is running (even if NOT_SERVING)
3. VTOrc requires durability policies to be set on all keyspaces
4. The cluster stores state in etcd - removing volumes requires reinitialization
5. For production, change durability policy from "none" to "semi_sync" or "cross_cell"

## Getting Help

For issues or questions:
- Check logs: `docker-compose logs <service> --tail 100`
- Verify status: `docker-compose ps`
- Review documentation in this repository
- Report issues: https://github.com/anthropics/claude-code/issues (for Claude Code)
- Vitess docs: https://vitess.io/docs/
