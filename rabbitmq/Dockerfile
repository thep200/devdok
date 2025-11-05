ARG RABBITMQ_VERSION=4-management-alpine

FROM rabbitmq:${RABBITMQ_VERSION}

# Enable RabbitMQ Management Plugin
RUN rabbitmq-plugins enable rabbitmq_management

# Expose ports
# 5672 - AMQP port
# 15672 - Management UI port
EXPOSE 5672 15672

CMD ["rabbitmq-server"]
