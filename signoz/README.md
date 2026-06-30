# SigNoz

Stack observability tự host (APM, logs, metrics, traces) chạy bằng Docker để dùng ở local. Đây là một stack **độc lập**: có ClickHouse riêng, không đụng tới service `clickhouse` chung của project.

## Thành phần

| Service                          | Vai trò                                            |
| -------------------------------- | -------------------------------------------------- |
| `signoz`                         | UI + query service (cổng container 8080)           |
| `signoz-otel-collector`          | Nhận telemetry qua OTLP (gRPC `4317`, HTTP `4318`) |
| `signoz-clickhouse`              | Lưu trữ dữ liệu (nội bộ, **không** publish ra host)|
| `signoz-telemetrystore-migrator` | Chạy migrate schema 1 lần rồi thoát                |
| `signoz-init-clickhouse`         | Tải UDF `histogramQuantile` rồi thoát              |

> **Coordination:** schema của SigNoz dùng `ReplicatedMergeTree` + DDL `ON CLUSTER`, nên
> ClickHouse cần một bộ coordination. Thay vì chạy container ZooKeeper riêng, setup này
> dùng **ClickHouse Keeper nhúng** ngay trong container `signoz-clickhouse`
> (xem `common/clickhouse/keeper.xml`) → chỉ còn đúng 1 container ClickHouse.

## Chạy

```bash
# 1. Tạo network shared (chạy ở thư mục gốc project, chỉ cần 1 lần)
make net-shared

# 2. Bật SigNoz (chạy ở thư mục gốc project)
docker compose -f signoz/docker-compose.yml --env-file .env up -d

# Dừng
docker compose -f signoz/docker-compose.yml down

# Xoá luôn dữ liệu (clickhouse / sqlite / zookeeper)
docker compose -f signoz/docker-compose.yml down -v
```

> `--env-file .env` để lấy các biến `SIGNOZ_*` từ `.env` ở thư mục gốc. Bỏ cờ này
> cũng được — compose đã có sẵn giá trị mặc định cho mọi biến.

- **UI:** http://localhost:3301 (đổi qua `SIGNOZ_PORT`)
- Cổng UI mặc định để **3301** vì host port `8080` đã bị `kafka-ui` dùng.

## Gửi telemetry vào SigNoz

`otel-collector` được gắn thêm vào network `shared`, nên container khác trong project
(php-fpm, app, ...) gửi thẳng qua tên service:

| Từ đâu                              | Endpoint                          |
| ----------------------------------- | --------------------------------- |
| Container khác trong network `shared` | `signoz-otel-collector:4317` (gRPC) / `:4318` (HTTP) |
| Ứng dụng chạy trên host             | `localhost:4317` (gRPC) / `localhost:4318` (HTTP)    |

Ví dụ với SDK OpenTelemetry: đặt `OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector:4318`
(trong container) hoặc `http://localhost:4318` (trên host).

## Biến môi trường (ở `.env` gốc)

| Biến                        | Mặc định  | Ý nghĩa                        |
| --------------------------- | --------- | ------------------------------ |
| `SIGNOZ_PORT`               | `3301`    | Cổng host cho UI               |
| `SIGNOZ_VERSION`            | `v0.129.0`| Image `signoz/signoz`          |
| `SIGNOZ_OTELCOL_VERSION`    | `v0.144.5`| Image otel-collector & migrator|
| `SIGNOZ_CLICKHOUSE_VERSION` | `25.5.6`  | Image ClickHouse của SigNoz    |
| `SIGNOZ_OTLP_GRPC_PORT`     | `4317`    | Cổng host OTLP gRPC            |
| `SIGNOZ_OTLP_HTTP_PORT`     | `4318`    | Cổng host OTLP HTTP            |

## Cấu trúc thư mục

```
signoz/
├── docker-compose.yml              # định nghĩa stack
├── otel-collector-config.yaml      # pipeline thu thập telemetry
└── common/
    ├── clickhouse/                 # config ClickHouse (config/users/cluster/custom-function/keeper)
    │   └── user_scripts/           # nơi chứa UDF histogramQuantile (tải lúc init)
    └── signoz/
        └── otel-collector-opamp-config.yaml
```

Các file config lấy từ deploy chính thức của SigNoz (`SigNoz/signoz`, thư mục `deploy/`).
