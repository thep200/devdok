# Cassandra Database

Apache Cassandra là một cơ sở dữ liệu NoSQL phân tán, được thiết kế cho khả năng mở rộng cao và tính khả dụng cao.

## Connection Information

- **Host**: `127.0.0.1`
- **Port**: `9042` (Native transport port)
- **Cluster Name**: `Test Cluster`
- **Default Keyspace**: `test_keyspace`

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 7000 | Inter-node | Cassandra inter-node communication |
| 7001 | Inter-node SSL | Cassandra inter-node communication (SSL) |
| 7199 | JMX | Java Management Extensions |
| 9042 | CQL | Cassandra Query Language (Native transport) |
| 9160 | Thrift | Legacy Thrift client port |

## Configuration

The configuration is defined in `cassandra.yaml`:
- **Replication Strategy**: SimpleStrategy
- **Replication Factor**: 1 (single node)
- **Partitioner**: Murmur3Partitioner
- **Snitch**: SimpleSnitch

## Sample Tables

On startup, the following tables are created in `test_keyspace`:
- `users`: Stores user information with indexes on username and email
- `posts`: Stores post information linked to users

## Usage Examples

### Connect using cqlsh

```bash
docker exec -it cassandra cqlsh 127.0.0.1 9042
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
  cassandra:
    build:
      context: ./cassandra
      args:
        CASSANDRA_VERSION: "4.1.3"
    container_name: cassandra
    ports:
      - "7000:7000"
      - "7001:7001"
      - "7199:7199"
      - "9042:9042"
      - "9160:9160"
    environment:
      - MAX_HEAP_SIZE=1G
      - HEAP_NEWSIZE=256M
    volumes:
      - cassandra_data:/var/lib/cassandra
    healthcheck:
      test: ["CMD", "cqlsh", "-e", "describe cluster"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  cassandra_data:
```

## Useful Commands

### Check cluster status
```bash
docker exec cassandra nodetool status
```

### View logs
```bash
docker logs cassandra
```

### List all keyspaces
```bash
docker exec -it cassandra cqlsh -e "DESCRIBE KEYSPACES;" 127.0.0.1 9042
```

### Flush data to disk
```bash
docker exec cassandra nodetool flush
```

## Performance Tuning

For development:
- `num_tokens: 256` - Good balance for development
- `memtable_total_space_in_mb: 2048` - Suitable for development
- `commitlog_total_space_in_mb: 8192` - Suitable for development

For production, adjust these values based on your hardware and workload.

## References

- [Apache Cassandra Documentation](https://cassandra.apache.org/doc/latest/)
- [Cassandra Configuration Reference](https://cassandra.apache.org/doc/latest/cassandra/configuration/cass_yaml_file.html)
