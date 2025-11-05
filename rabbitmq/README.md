# RabbitMQ Setup and Usage Guide

## Overview

RabbitMQ is a robust message broker that implements the Advanced Message Queuing Protocol (AMQP). This setup provides a containerized RabbitMQ instance with management UI enabled.

## Configuration Files

### Dockerfile
- Based on official RabbitMQ image with management plugin enabled
- Exposes ports 5672 (AMQP) and 15672 (Management UI)

### rabbitmq.conf
- Main configuration file for RabbitMQ settings
- Includes network settings, memory management, and performance tuning
- Configured for clustering and high availability

### definitions.json
- Defines virtual hosts, users, queues, exchanges, and bindings
- Automatically loaded on container startup
- Contains default queue setup with TTL (Time To Live) settings

## Docker Compose Integration

The RabbitMQ service is configured in `docker-compose.yml` with:

```yaml
rabbitmq:
  restart: always
  container_name: rabbitmq
  build:
    context: ./rabbitmq
    args:
      - RABBITMQ_VERSION=${RABBITMQ_VERSION}
  environment:
    - RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER}
    - RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS}
  ports:
    - "${RABBITMQ_PORT}:5672"
    - "${RABBITMQ_MANAGEMENT_PORT}:15672"
  volumes:
    - rabbitmq_data:/var/lib/rabbitmq
  networks:
    - internal
    - shared
```

## Environment Variables

Add these to your `.env` file:

```env
# RabbitMQ
RABBITMQ_VERSION=4-management-alpine
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672
RABBITMQ_DEFAULT_USER=thep200
RABBITMQ_DEFAULT_PASS=root
```

## Starting RabbitMQ

From the project root directory:

```bash
# Start all services including RabbitMQ
docker-compose up -d rabbitmq

# View logs
docker-compose logs -f rabbitmq

# Stop RabbitMQ
docker-compose down rabbitmq
```

## Accessing RabbitMQ

### AMQP Connection
- **Host**: localhost
- **Port**: 5672
- **Username**: thep200 (default from .env)
- **Password**: root (default from .env)
- **Virtual Host**: / (default)

Example connection string:
```
amqp://thep200:root@localhost:5672/
```

### Management UI
- **URL**: http://localhost:15672
- **Username**: thep200
- **Password**: root

The Management UI allows you to:
- View and manage queues
- Create/delete exchanges and bindings
- Monitor connections and channels
- Manage virtual hosts and users
- View message rates and statistics

## Default Queues and Exchanges

The `definitions.json` file creates:

### Queues
- `default_queue` - A durable queue with 1 hour TTL

### Exchanges
- `amq.direct` - Direct exchange for direct routing
- `amq.fanout` - Fanout exchange for broadcasting
- `amq.topic` - Topic exchange for pattern-based routing

### Bindings
- `default_queue` bound to `amq.direct` with routing key `default_key`

## Connecting from Your Application

### Node.js (amqplib)
```javascript
const amqp = require('amqplib');

const connection = await amqp.connect('amqp://thep200:root@localhost:5672/');
const channel = await connection.createChannel();

// Declare queue
await channel.assertQueue('my_queue', { durable: true });

// Publish message
channel.sendToQueue('my_queue', Buffer.from('Hello World'));

// Consume messages
channel.consume('my_queue', (msg) => {
  console.log(msg.content.toString());
  channel.ack(msg);
});
```

### Python (pika)
```python
import pika

credentials = pika.PlainCredentials('thep200', 'root')
parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)
connection = pika.BlockingConnection(parameters)
channel = connection.channel()

# Declare queue
channel.queue_declare(queue='my_queue', durable=True)

# Publish message
channel.basic_publish(exchange='', routing_key='my_queue', body='Hello World')

# Consume messages
def callback(ch, method, properties, body):
    print(f"Received: {body.decode()}")
    ch.basic_ack(delivery_tag=method.delivery_tag)

channel.basic_consume(queue='my_queue', on_message_callback=callback)
channel.start_consuming()
```

### Java (Spring AMQP)
```java
@Configuration
public class RabbitConfig {

    @Bean
    public ConnectionFactory connectionFactory() {
        return new CachingConnectionFactory("localhost");
    }

    @Bean
    public Queue myQueue() {
        return new Queue("my_queue", true);
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        return new RabbitTemplate(connectionFactory);
    }
}
```

## Persistence

- RabbitMQ data is persisted in the `rabbitmq_data` Docker volume
- Data survives container restarts due to `restart: always` policy
- To reset data, remove the volume: `docker volume rm devdok_rabbitmq_data`

## Networking

RabbitMQ is connected to:
- **internal** network - For communication with other services in the project
- **shared** network - For external access (if configured)

Other services can connect using the hostname `rabbitmq` instead of localhost.

## Performance Tuning

Key settings in `rabbitmq.conf`:

- `vm_memory_high_watermark.relative = 0.6` - Memory threshold
- `channel_max = 2048` - Maximum channels per connection
- `heartbeat = 60` - Heartbeat interval in seconds
- `disk_free_limit.absolute = 50MB` - Minimum disk space

Adjust these based on your system resources and requirements.

## Troubleshooting

### Connection refused
- Ensure RabbitMQ container is running: `docker-compose ps rabbitmq`
- Check if ports are not already in use: `lsof -i :5672`

### High memory usage
- Adjust `vm_memory_high_watermark.relative` in `rabbitmq.conf`
- Check for accumulated messages in queues via Management UI

### Management UI not loading
- Verify port 15672 is accessible
- Check container logs: `docker-compose logs rabbitmq`
- Ensure management plugin is enabled

## Useful Commands

```bash
# Access RabbitMQ shell
docker exec -it rabbitmq rabbitmqctl status

# List users
docker exec -it rabbitmq rabbitmqctl list_users

# Reset RabbitMQ
docker exec -it rabbitmq rabbitmqctl reset

# List queues
docker exec -it rabbitmq rabbitmqctl list_queues

# List connections
docker exec -it rabbitmq rabbitmqctl list_connections
```

## References

- [RabbitMQ Official Documentation](https://www.rabbitmq.com/documentation.html)
- [AMQP Protocol](https://www.amqp.org/)
- [Docker RabbitMQ Image](https://hub.docker.com/_/rabbitmq)
