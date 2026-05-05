# Database

Cung cấp cấu hình các loại database cần sử dụng

## Use

Hiện tại hỗ trợ `mySQL`, `postgreSQL`, `MongoDB`, `Cassandra`, `ScyllaDB` và `ClickHouse`.

### Relational Databases

- `MySQL`: `127.0.0.1:3306`
  - (username, password) = (root, root)
  - (username, password) = (thep200, root)
- `PostgreSQL`: `127.0.0.1:5432`
  - (username, password) = (thep200, root)

### NoSQL Databases

- `MongoDB`: `127.0.0.1:27017`
  - (username, password) = (thep200, root)
- `Cassandra`: `127.0.0.1:9042`
  - Default cluster: 'Test Cluster'
  - Keyspace: `test_keyspace` (created on startup)
  - Native transport port: 9042
  - JMX port: 7199
- `ScyllaDB`: `127.0.0.1:9042`
  - Default cluster: 'Test Cluster'
  - Keyspace: `test_keyspace` (created on startup)
  - Native transport port: 9042
  - JMX port: 7199
  - Metrics port: 10000

### Column Store Database

- `ClickHouse`: `127.0.0.1:8123`

## Ports Summary

| Database   | Port  | Type  | Purpose            |
| ---------- | ----- | ----- | ------------------ |
| MySQL      | 3306  | SQL   | Client connections |
| PostgreSQL | 5432  | SQL   | Client connections |
| MongoDB    | 27017 | NoSQL | Client connections |
| Cassandra  | 9042  | NoSQL | CQL client port    |
| Cassandra  | 7000  | NoSQL | Inter-node comm.   |
| Cassandra  | 7199  | NoSQL | JMX port           |
| ScyllaDB   | 9042  | NoSQL | CQL client port    |
| ScyllaDB   | 7000  | NoSQL | Inter-node comm.   |
| ScyllaDB   | 10000 | NoSQL | Metrics port       |
| ClickHouse | 8123  | OLAP  | HTTP client port   |
