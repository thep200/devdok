# Doc

Repository này để cấu hình docker làm môi trường cài đặt những gì cần sử dụng để dev và một số trick khác. Ví dụ như `mysql`, `kafka`, ....

## Mysql


## Kafka

Kafka là một nền tảng streaming data với độ trễ thấp, cho phép truyền truyền dữ liệu đi từ `producer` với độ trễ thấp tới các nền tảng tiêu thu dữ liệu khác `consummer`

*   Producer: nguồn truyền phát dữ liệu
*   Consummer: nơi tiêu thụ dữ liệu
*   Topics: Dữ liệu được truyền phát bởi vào các topic khác nhau
*   Partition: Các phần vùng khác nhau trên một topic cho phép dữ liệu được load trên nhiều serve khác nhau
*   Brokers: các máy chủ kafka mỗi một `broker` là một thành phần trong một `cluster` kafka

> Zookeeper: giúp quản lý cấu hình và điều phối, giám sát tình trạng các broker.

## Debezium

`Debezium` cho phép theo dõi binlog của các cơ sở dữ liệu và gửi các thay đổi vào các topic thông qua kafka `Change Data Capture - CDC`

*   Debezium có thể tích hợp với nhiều loại cơ sở dữ liệu khác nhau
*   Thường kết hợp với kafka connect cho phép kết nối các nguồn dữ liệu tới các broker kafka

### Connector

Sau khi kết nối thành công connector sẽ public một domaim để chúng ta thao tác add và view các connector.

### Create connector

*   Để tạo connector sử dụng api được expose từ kafka connect

> Lưu ý là nếu mysql được đặt ở một network khác thì phải đổi `database.hostname` thành `host.docker.internal`

### Noted
Vào [docker hub](https://hub.docker.com/) để đọc doc khi tự build file docker compose file
