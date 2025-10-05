# Envoy Proxy Configuration

## Overview
Envoy là một high-performance proxy được sử dụng cho service mesh và API gateway.

## Configuration

File cấu hình chính: `envoy.yaml`

### Ports
- **82**: Main HTTP listener port
- **9901**: Admin interface port

### Cấu trúc cấu hình

#### Listeners
- Lắng nghe trên port 82 cho tất cả các incoming requests
- Sử dụng HTTP connection manager để xử lý HTTP traffic

#### Clusters
- `service_backend`: Backend service cluster
- Có thể thêm nhiều clusters khác tùy vào nhu cầu routing

#### Admin Interface
- Truy cập tại: http://localhost:9901
- Cung cấp metrics, health checks, và configuration dump

## Cách sử dụng

### Start Envoy
```bash
docker-compose up -d envoy
```

### Check logs
```bash
docker-compose logs -f envoy
```

### Restart với config mới
```bash
docker-compose restart envoy
```

### Access Admin Interface
```bash
curl http://localhost:9901/help
curl http://localhost:9901/stats
curl http://localhost:9901/config_dump
```

## Tùy chỉnh cấu hình

### Thêm backend service
Sửa section `clusters` trong `envoy.yaml`:
```yaml
clusters:
- name: my_service
  connect_timeout: 0.25s
  type: LOGICAL_DNS
  lb_policy: ROUND_ROBIN
  load_assignment:
    cluster_name: my_service
    endpoints:
    - lb_endpoints:
      - endpoint:
          address:
            socket_address:
              address: my-service-host
              port_value: 8080
```

### Thêm routing rules
Sửa section `routes` trong `virtual_hosts`:
```yaml
routes:
- match:
    prefix: "/api"
  route:
    cluster: api_service
- match:
    prefix: "/web"
  route:
    cluster: web_service
```

### Load Balancing Policies
- ROUND_ROBIN: Phân phối đều requests
- LEAST_REQUEST: Gửi đến backend ít request nhất
- RANDOM: Random selection

## Monitoring

### Health Check
```bash
curl http://localhost:9901/ready
```

### Statistics
```bash
curl http://localhost:9901/stats/prometheus
```

## Troubleshooting

### Check if Envoy is running
```bash
docker ps | grep envoy
```

### Validate configuration
```bash
docker-compose run --rm envoy --mode validate -c /etc/envoy/envoy.yaml
```

### Common Issues
1. Port conflict: Đảm bảo ports 82 và 9901 không bị sử dụng
2. Config syntax: Validate YAML syntax
3. Network connectivity: Check network configuration trong docker-compose

## References
- [Envoy Documentation](https://www.envoyproxy.io/docs/envoy/latest/)
- [Configuration Reference](https://www.envoyproxy.io/docs/envoy/latest/configuration/configuration)
