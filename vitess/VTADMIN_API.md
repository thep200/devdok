# VTAdmin API Reference

VTAdmin is now running on port 14200 and provides a REST API for managing your Vitess cluster.

**Note**: The web UI is not included in the vitess/lite image, but the API is fully functional and can be accessed via curl, Postman, or any HTTP client.

## Base URL

```
http://localhost:14200/api
```

## Common API Endpoints

### Cluster Management

```bash
# List all clusters
curl http://localhost:14200/api/clusters

# Get cluster information
curl http://localhost:14200/api/clusters/local
```

### Keyspaces

```bash
# List all keyspaces across all clusters
curl http://localhost:14200/api/keyspaces

# Get keyspace details
curl http://localhost:14200/api/keyspace/local/test_keyspace

# Get VSchema for a keyspace
curl http://localhost:14200/api/vschema/local/test_keyspace
```

### Tablets

```bash
# List all tablets
curl http://localhost:14200/api/tablets

# Get tablet details
curl http://localhost:14200/api/tablet/test-0000000101
```

### Schemas

```bash
# List schemas across all keyspaces
curl http://localhost:14200/api/schemas

# Get schema for a specific keyspace
curl http://localhost:14200/api/schema/local/test_keyspace
```

### Workflows

```bash
# List all workflows
curl http://localhost:14200/api/workflows

# Get workflow details
curl "http://localhost:14200/api/workflow/local/test_keyspace/workflow_name"
```

### VTGates

```bash
# List all VTGates
curl http://localhost:14200/api/gates
```

### VTCtlds

```bash
# List all VTCtlds
curl http://localhost:14200/api/vtctlds
```

## Pretty Print JSON

Use `jq` or Python's json.tool to format the output:

```bash
# Using jq
curl -s http://localhost:14200/api/tablets | jq

# Using Python
curl -s http://localhost:14200/api/tablets | python3 -m json.tool
```

## Example Responses

### List Clusters

```json
{
  "result": {
    "clusters": [
      {
        "id": "local",
        "name": "local"
      }
    ]
  },
  "ok": true
}
```

### List Keyspaces

```json
{
  "result": {
    "keyspaces": [
      {
        "cluster": {
          "id": "local",
          "name": "local"
        },
        "keyspace": {
          "name": "test_keyspace",
          "keyspace": {
            "sidecar_db_name": "_vt"
          }
        },
        "shards": {
          "-80": { ... },
          "80-": { ... }
        }
      }
    ]
  },
  "ok": true
}
```

## Configuration Files

- **Discovery**: `scripts/vtadmin/discovery.json` - Defines how VTAdmin discovers vtctld and vtgate instances
- **RBAC**: `scripts/vtadmin/rbac.yaml` - Role-based access control rules (currently allows all access)

## Adding a Web UI (Optional)

The vitess/lite image doesn't include the pre-built web UI. If you need a web interface, you have these options:

1. **Use a third-party API client**: Postman, Insomnia, or similar tools
2. **Build the web UI from source**: Follow the Vitess documentation to build and serve the UI
3. **Use a different container image**: Some Vitess distributions include pre-built UI assets

For most operations, the API provides all the functionality you need for cluster management and monitoring.
