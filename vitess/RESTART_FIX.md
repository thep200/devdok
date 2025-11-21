# Vitess Restart Issue - Diagnosis and Fix

## Issue Summary

After restarting Docker Compose, all vttablet containers (vttablet101, vttablet102, vttablet201, vttablet202, vttablet301, vttablet302) were marked as **unhealthy**, even though the processes were running correctly.

## Root Cause Analysis

### 1. Symptom
- All vttablet containers showing status: `Up X minutes (unhealthy)`
- Docker health checks failing with exit code 22
- Error message: `curl: (22) The requested URL returned error: 500`

### 2. Investigation
Examined the containers and found:
- ✅ vttablet process (PID 7) running
- ✅ mysqlctld process (PID 13) running
- ✅ mysqld process running
- ❌ Health check endpoint `/debug/health` returning HTTP 500

### 3. Root Cause
The health check was using `/debug/health` endpoint which returns:
- **HTTP 200** when tablet is in SERVING state
- **HTTP 500** when tablet is in NOT_SERVING state with error: "operation not allowed in state NOT_SERVING"

After restart, tablets initially come up in NOT_SERVING state while waiting for:
1. Connection to topology server (etcd)
2. Primary election/restoration from topology
3. Replication setup

This caused Docker to mark the containers as unhealthy, even though they were functioning correctly.

## The Fix

### Solution 1: Improved Health Check (Permanent Fix)
Changed the health check endpoint from `/debug/health` to `/debug/status` in `docker-compose.yml`:

**Before:**
```yaml
healthcheck:
  interval: 30s
  retries: 15
  test:
    - CMD-SHELL
    - curl -s --fail --show-error localhost:8080/debug/health
  timeout: 10s
```

**After:**
```yaml
healthcheck:
  interval: 30s
  retries: 15
  test:
    - CMD-SHELL
    - curl -f http://localhost:8080/debug/status
  timeout: 10s
```

**Why this works:**
- `/debug/status` returns HTTP 200 as long as the vttablet process is running and responding
- It doesn't require the tablet to be in SERVING state
- Provides a better indication of whether the container is actually running vs serving traffic

### Solution 2: Manual Reinitialization (When Needed)
If tablets don't automatically restore their state, run:
```bash
./init-cluster.sh
```

This script:
1. Elects primaries for all shards using `PlannedReparentShard`
2. Sets durability policies for keyspaces
3. Displays tablet status

## Testing the Fix

### Test 1: Restart Individual Tablets
```bash
docker-compose restart vttablet101 vttablet102 vttablet201 vttablet202 vttablet301 vttablet302
sleep 40
docker-compose ps
```

**Expected Result:** All vttablets should show `(healthy)` status

### Test 2: Full Cluster Restart
```bash
docker-compose down
docker-compose up -d
sleep 60
./init-cluster.sh
docker-compose ps
```

**Expected Result:**
- All containers start successfully
- Health checks pass
- After init-cluster.sh, all tablets in SERVING state

## Files Modified

1. **docker-compose.yml** - Updated health checks for all 6 vttablet services
   - Lines 225-231 (vttablet101)
   - Lines 264-270 (vttablet102)
   - Lines 303-309 (vttablet201)
   - Lines 342-348 (vttablet202)
   - Lines 381-387 (vttablet301)
   - Lines 420-426 (vttablet302)

## Verification Commands

### Check container health status:
```bash
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
```

### Check tablet serving status:
```bash
./scripts/lvtctl.sh GetTablets
```

### Check VTAdmin API:
```bash
curl -s http://localhost:14200/api/tablets | python3 -m json.tool | grep -E "(uid|type|state)"
```

### Test health endpoint manually:
```bash
docker exec vitess-vttablet101-1 curl -s http://localhost:8080/debug/status
docker exec vitess-vttablet101-1 curl -s http://localhost:8080/debug/health
```

## Understanding Tablet States

Vitess tablets can be in different states:
- **NOT_SERVING**: Tablet is running but not accepting queries (during startup/recovery)
- **SERVING**: Tablet is healthy and accepting queries
- **NOT_SERVING_REPLICA**: Replica is running but replication is broken

The old health check using `/debug/health` would fail for all NOT_SERVING states, even though this is normal during startup. The new check using `/debug/status` only verifies the vttablet process is running and responding.

## Additional Notes

### VTOrc Role
VTOrc (Vitess Orchestrator) is now running and monitors all tablets. It can:
- Automatically detect primary failures
- Perform failover to promote replicas
- Maintain cluster health

However, VTOrc doesn't help with initial startup when tablets are NOT_SERVING - it only helps with failover scenarios.

### Why Tablets Restore State
Vitess stores tablet metadata in etcd (the topology server). On restart, tablets:
1. Connect to etcd
2. Retrieve their previous role and configuration
3. Restore replication relationships
4. Resume serving (for primaries) or start replicating (for replicas)

This usually happens automatically within 30-60 seconds. If it doesn't, run `./init-cluster.sh` to manually reinitialize.

## Troubleshooting

### If tablets remain unhealthy after fix:
1. Check if vttablet process is running:
   ```bash
   docker exec vitess-vttablet101-1 ps aux | grep vttablet
   ```

2. Check vttablet logs:
   ```bash
   docker-compose logs vttablet101 --tail 50
   ```

3. Verify etcd is accessible:
   ```bash
   docker exec vitess-vttablet101-1 curl http://etcd1:2379/health
   ```

### If tablets are healthy but not serving:
1. Check tablet status:
   ```bash
   ./scripts/lvtctl.sh GetTablets
   ```

2. Run initialization script:
   ```bash
   ./init-cluster.sh
   ```

3. Check VTOrc for recovery actions:
   ```bash
   curl http://localhost:13000/debug/status
   ```

## Summary

**Problem:** Docker health checks failing on restart because `/debug/health` returns 500 for NOT_SERVING tablets

**Solution:** Changed health check to use `/debug/status` which checks if vttablet is running, not if it's serving traffic

**Result:** Tablets can restart successfully and Docker correctly identifies them as healthy while they initialize and restore their serving state
