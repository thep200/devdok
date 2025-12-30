# ClickHouse Configuration

## Environment Variables

Bạn cần thêm các biến môi trường sau vào file `.env` của bạn:

```bash
# ClickHouse Configuration
CLICKHOUSE_VERSION=latest
CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_NATIVE_PORT=9000
CLICKHOUSE_DB=default
CLICKHOUSE_USER=clickhouse_user
CLICKHOUSE_PASSWORD=your_password_here

# Password SHA256 hashes (see below for generation)
CLICKHOUSE_PASSWORD_SHA256=your_sha256_hash_here
CLICKHOUSE_USER_PASSWORD_SHA256=your_sha256_hash_here
```

## Tạo Password SHA256

ClickHouse sử dụng SHA256 hash cho password. Để tạo hash, bạn có thể sử dụng một trong các cách sau:

### Cách 1: Sử dụng echo và sha256sum (Linux/Mac)
```bash
echo -n 'your_password' | sha256sum | awk '{print $1}'
```

### Cách 2: Sử dụng Python
```bash
python3 -c "import hashlib; print(hashlib.sha256('your_password'.encode()).hexdigest())"
```

### Cách 3: Sử dụng openssl
```bash
echo -n 'your_password' | openssl dgst -sha256 | awk '{print $2}'
```

## Ví dụ cấu hình

Nếu bạn muốn sử dụng password `mypassword123`:

```bash
# Tạo hash
python3 -c "import hashlib; print(hashlib.sha256('mypassword123'.encode()).hexdigest())"
# Output: ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f

# Thêm vào .env
CLICKHOUSE_PASSWORD=mypassword123
CLICKHOUSE_PASSWORD_SHA256=ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f
```

## Kết nối với ClickHouse

### HTTP Interface (Port 8123)
```bash
curl http://localhost:8123/?user=default&password=mypassword123 -d "SELECT 1"
```

### Native Client (Port 9000)
```bash
clickhouse-client --host localhost --port 9000 --user default --password mypassword123
```

### Sử dụng Docker
```bash
docker exec -it clickhouse clickhouse-client --user default --password mypassword123
```

## Users

Hệ thống được cấu hình với 2 users:

1. **default**: User mặc định với full quyền admin
2. **clickhouse_user**: User custom với quyền truy cập database

Cả 2 users đều có thể quản lý access (tạo user mới, grant permissions, etc.)

## Start Service

```bash
cd /Users/thep200/Projects/Env/devdok
docker-compose up -d clickhouse
```

## Kiểm tra logs

```bash
docker-compose logs -f clickhouse
```
