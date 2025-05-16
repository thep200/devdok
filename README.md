# Doc

Repository này để cấu hình docker làm môi trường cài đặt những gì cần sử dụng để dev và một số trick khác. Ví dụ như `mysql`, `kafka`, ....

## Run

*   `make net-shared`:  để tạo mạng chung cho các container cần sử dụng
*   `docker-compose up -d`: bật hết tất cả các service

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
