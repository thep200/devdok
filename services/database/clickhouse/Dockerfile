ARG CLICKHOUSE_VERSION=latest
FROM clickhouse/clickhouse-server:${CLICKHOUSE_VERSION}

LABEL maintainer="thep200 <thep200.work@gmail.com>"

# Copy custom users configuration
COPY users.xml /etc/clickhouse-server/users.d/users.xml

# Set proper permissions
RUN chmod 644 /etc/clickhouse-server/users.d/users.xml

# Expose ports
# 8123 - HTTP interface
# 9000 - Native client protocol
EXPOSE 8123 9000
