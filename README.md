# Doc

Repository này để cấu hình docker làm môi trường cài đặt những gì cần sử dụng để dev và một số trick khác. Ví dụ như `mysql`, `kafka`, ....

## Run

*   `make net-shared`:  để tạo mạng chung cho các container cần sử dụng
*   `docker-compose up -d`: bật hết tất cả các service

## SigNoz (observability)

Stack observability (APM, logs, metrics, traces) chạy riêng, không bật cùng `docker-compose up` ở trên:

```bash
docker compose -f signoz/docker-compose.yml --env-file .env up -d
```

UI ở http://localhost:3301. Chi tiết xem [`signoz/README.md`](./signoz/README.md).

## Note

Các container khác chạy có thể thêm network `shared` để có thể kết nối internal tới các dịch vụ khác.

```yaml
networks:
  ...
  shared:
    external: true

services:
  ...
  networks:
    - shared
```
