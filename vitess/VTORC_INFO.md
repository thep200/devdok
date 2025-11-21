# VTOrc - Vitess Orchestrator

VTOrc is now enabled and running on port 13000. It provides automated failover and recovery for your Vitess cluster.

## What is VTOrc?

VTOrc (Vitess Orchestrator) is a service that:
- Continuously monitors the health of all tablets in your cluster
- Detects primary tablet failures automatically
- Performs automated failover to promote a replica to primary
- Maintains cluster topology and replication health
- Provides visibility into cluster status through its web UI

## Current Configuration

VTOrc is configured with these settings:

- **Instance Poll Time**: 5 seconds - How often VTOrc checks tablet health
- **Topo Refresh**: 15 seconds - How often it refreshes topology information
- **Cross-Cell Failover**: Enabled - Can failover across cells
- **Durability Policy**: none - For testing/development (no semi-sync required)
- **Storage**: SQLite at `/vt/vtdataroot/vtorc.db`

## Web Interface

Access VTOrc status at: http://localhost:13000/debug/status

The status page shows:
- Discovered tablets and their health
- Primary/replica relationships
- Recent recovery actions
- Cluster topology

## How It Works

1. **Discovery**: VTOrc discovers all tablets from the topology server (etcd)
2. **Monitoring**: Continuously polls each tablet to check health
3. **Detection**: When a primary fails, VTOrc detects it within seconds
4. **Recovery**: Automatically promotes a healthy replica to be the new primary
5. **Reconfiguration**: Updates remaining replicas to replicate from the new primary

## Durability Policy

The cluster is configured with `durability_policy=none`, which means:
- Failover happens immediately without waiting for semi-sync replication
- Suitable for development/testing environments
- For production, use `semi_sync` or `cross_cell` for data safety

You can change the durability policy:
```bash
./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=semi_sync test_keyspace
./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=semi_sync lookup_keyspace
```

## Testing Failover

To test VTOrc's automatic failover:

1. Check current primary:
   ```bash
   ./scripts/lvtctl.sh GetTablets
   ```

2. Stop a primary tablet (e.g., vttablet101):
   ```bash
   docker-compose stop vttablet101
   ```

3. Watch VTOrc detect the failure and promote a replica:
   ```bash
   docker-compose logs -f vtorc
   ```

4. Verify the new primary:
   ```bash
   ./scripts/lvtctl.sh GetTablets
   ```

5. Restart the stopped tablet:
   ```bash
   docker-compose start vttablet101
   ```

The restarted tablet will automatically become a replica of the new primary.

## Configuration Files

- **Startup Script**: `scripts/vtorc-up.sh`
- **Docker Compose**: VTOrc service defined in `docker-compose.yml`
- **Config**: Command-line flags (no config file in Vitess 24.0+)

## Important Notes

- **VTOrc requires keyspaces to have a durability policy set** - Without this, VTOrc will log errors and ignore the keyspace
- The init-cluster.sh script automatically sets durability policy to "none" for both keyspaces
- **Order matters**: Durability policies must be set BEFORE VTOrc starts monitoring. The init-cluster.sh script now sets policies before initializing primaries
- VTOrc discovers all keyspaces automatically from topology
- It runs continuously and restarts automatically if it crashes
- All recovery actions are logged and visible in the web UI

### If you see "ignoring keyspace because no durability_policy is set" errors:

This means VTOrc started before durability policies were configured. To fix:

```bash
# Set durability policies for both keyspaces
./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=none test_keyspace
./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=none lookup_keyspace
```

VTOrc will automatically pick up the changes within a few seconds and stop logging errors.

## Monitoring VTOrc

Check VTOrc logs:
```bash
docker-compose logs -f vtorc
```

Check VTOrc status:
```bash
docker-compose ps vtorc
```

Restart VTOrc:
```bash
docker-compose restart vtorc
```

## Resources

- VTOrc was based on Orchestrator but is now integrated into Vitess
- It's production-ready and used in many large Vitess deployments
- For more details, see the Vitess documentation on automated failover
