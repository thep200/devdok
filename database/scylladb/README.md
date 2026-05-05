# ScyllaDB Database

ScyllaDB là một cơ sở dữ liệu NoSQL hiệu suất cao, tương thích với Cassandra nhưng viết lại hoàn toàn bằng C++ để tối ưu hóa hiệu suất.

## Connection Information

- **Host**: `127.0.0.1`
- **Port**: `9042` (Native transport port)
- **Cluster Name**: `Test Cluster`
- **Default Keyspace**: `test_keyspace`

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 7000 | Inter-node | ScyllaDB inter-node communication |
| 7001 | Inter-node SSL | ScyllaDB inter-node communication (SSL) |
| 7199 | JMX | Java Management Extensions |
| 9042 | CQL | Cassandra Query Language (Native transport) |
| 9160 | Thrift | Legacy Thrift client port |
| 10000 | Metrics | Prometheus metrics endpoint |

## Configuration

The configuration is defined in `scylla.yaml`:
- **Replication Strategy**: SimpleStrategy
- **Replication Factor**: 1 (single node)
- **Partitioner**: Murmur3Partitioner
- **Snitch**: SimpleSnitch
- **Developer Mode**: Enabled (for single-node setup)

## Sample Tables

On startup, the following tables are created in `test_keyspace`:
- `users`: Stores user information with indexes on username and email
- `posts`: Stores post information linked to users

## Usage Examples

### Connect using cqlsh

```bash
docker exec -it scylladb cqlsh 127.0.0.1 9042
```

### Create a keyspace

```cql
CREATE KEYSPACE IF NOT EXISTS my_keyspace
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 3
};
```

### Create a table

```cql
USE my_keyspace;

CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY,
    name TEXT,
    email TEXT,
    created_at TIMESTAMP
);
```

### Insert data

```cql
INSERT INTO employees (id, name, email, created_at)
VALUES (uuid(), 'John Doe', 'john@example.com', toTimestamp(now()));
```

### Query data

```cql
SELECT * FROM employees;
```

## Docker Compose Example

```yaml
services:
  scylladb:
    build:
      context: ./scylladb
      args:
        SCYLLADB_VERSION: "5.2.5"
    container_name: scylladb
    ports:
      - "7000:7000"
      - "7001:7001"
      - "7199:7199"
      - "9042:9042"
      - "9160:9160"
      - "10000:10000"
    environment:
      - SCYLLA_DEVELOPER_MODE=true
    volumes:
      - scylladb_data:/var/lib/scylla
    healthcheck:
      test: ["CMD", "cqlsh", "-e", "describe cluster"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  scylladb_data:
```

## Useful Commands

### Check cluster status
```bash
docker exec scylladb nodetool status
```

### View logs
```bash
docker logs scylladb
```

### List all keyspaces
```bash
docker exec -it scylladb cqlsh -e "DESCRIBE KEYSPACES;" 127.0.0.1 9042
```

### Flush data to disk
```bash
docker exec scylladb nodetool flush
```

### View metrics
```bash
curl http://127.0.0.1:10000/metrics
```

## Performance Characteristics

ScyllaDB offers:
- **Higher Throughput**: Up to 10x faster than Cassandra
- **Lower Latency**: Significantly lower P99 latencies
- **Better Resource Efficiency**: Lower CPU and memory usage
- **Drop-in Replacement**: Compatible with Cassandra clients and CQL

## Advantages over Cassandra

1. **Performance**: Written in C++ for better performance
2. **Lower Resource Usage**: Can run on less powerful hardware
3. **Simpler Operations**: Less tuning required
4. **Modern Architecture**: Designed for modern hardware

## References

- [ScyllaDB Documentation](https://docs.scylladb.com/)
- [ScyllaDB Configuration](https://docs.scylladb.com/stable/operating-scylla/configuration/)
- [ScyllaDB vs Cassandra](https://www.scylladb.com/scylla-vs-cassandra/)
