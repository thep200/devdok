# VTAdmin Web UI

The VTAdmin Web UI is now installed and running on port 14201.

## Access

Open your browser and navigate to: **http://localhost:14201**

## Features

The web interface provides a dashboard with the following tabs:

### 1. Clusters
- View all Vitess clusters managed by VTAdmin
- Shows cluster ID and name
- Currently displays the "local" cluster

### 2. Keyspaces
- View all keyspaces in the cluster
- Shows keyspace name, cluster, and number of shards
- Displays shard information (e.g., -80, 80-, -)
- Currently shows:
  - `test_keyspace` with 2 shards (-80, 80-)
  - `lookup_keyspace` with 1 shard (-)

### 3. Tablets
- View all tablets (MySQL instances) in the cluster
- Shows detailed information:
  - Alias (e.g., test-101, test-201)
  - Keyspace and shard assignment
  - Tablet type (PRIMARY, REPLICA, RDONLY, etc.)
  - Hostname
  - State (SERVING or NOT_SERVING)
- Color-coded badges for easy identification
- Currently shows 6 tablets:
  - vttablet101, 102 (test_keyspace/-80)
  - vttablet201, 202 (test_keyspace/80-)
  - vttablet301, 302 (lookup_keyspace/-)

### 4. Schemas
- View database schemas for each keyspace
- Shows table definitions and counts
- Useful for understanding the database structure

### 5. VSchema
- View VSchema (Vitess schema) configurations
- Select a keyspace from the dropdown
- Displays the JSON configuration for:
  - Vindexes (sharding and lookup indexes)
  - Table configurations
  - Routing rules

## Implementation Details

The VTAdmin Web UI is a custom single-page application built with:
- **Server**: Node.js 18 Alpine with `serve` package
- **Frontend**: Pure HTML, CSS, and JavaScript (no frameworks)
- **API Integration**: Fetches data from VTAdmin API at http://localhost:14200
- **Source**: `vtadmin-web/index.html`

### Docker Configuration

The web UI runs as a separate container (`vtadmin-web`) that:
1. Installs the `serve` npm package globally
2. Serves static files from `/app` directory
3. Enables CORS for API communication
4. Depends on `vtadmin-api` service

## Architecture

```
┌─────────────────┐
│   Browser       │
│  (port 14201)   │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│  VTAdmin Web    │
│  (node:18)      │
│  serve static   │
└────────┬────────┘
         │ API calls
         ▼
┌─────────────────┐
│  VTAdmin API    │
│  (port 14200)   │
└────────┬────────┘
         │ gRPC
         ▼
┌─────────────────┐
│  VTCtld/VTGate  │
│  Vitess Cluster │
└─────────────────┘
```

## Troubleshooting

### Web UI not loading
Check if the container is running:
```bash
docker-compose ps vtadmin-web
docker-compose logs vtadmin-web
```

### No data displayed
1. Verify VTAdmin API is running:
   ```bash
   curl http://localhost:14200/api/clusters
   ```

2. Check if cluster is initialized:
   ```bash
   ./init-cluster.sh
   ```

3. Check browser console for errors (F12 → Console tab)

### API connection errors
The web UI makes requests to `http://localhost:14200`. If you're accessing the UI from a different hostname, you may need to:
1. Update the `API_BASE` variable in `vtadmin-web/index.html`
2. Or configure your reverse proxy/load balancer

## API Endpoints Used

The web UI consumes these VTAdmin API endpoints:
- `GET /api/clusters` - List all clusters
- `GET /api/keyspaces` - List all keyspaces
- `GET /api/tablets` - List all tablets
- `GET /api/schemas` - List all schemas
- `GET /api/vschema/{cluster}/{keyspace}` - Get VSchema for a keyspace

For full API documentation, see `VTADMIN_API.md`.

## Customization

To modify the web UI:
1. Edit `vtadmin-web/index.html`
2. Restart the container:
   ```bash
   docker-compose restart vtadmin-web
   ```
3. Refresh your browser

The UI uses inline CSS and JavaScript, so all changes are in a single file.
