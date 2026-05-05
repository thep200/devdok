ARG CASSANDRA_VERSION=4.1.3
FROM cassandra:${CASSANDRA_VERSION}

LABEL maintainer="thep200 <thep200.work@gmail.com>"

# Copy custom cassandra.yaml configuration
COPY cassandra.yaml /etc/cassandra/cassandra.yaml

# Set proper permissions
RUN chmod 644 /etc/cassandra/cassandra.yaml && \
    chown cassandra:cassandra /etc/cassandra/cassandra.yaml

# Copy initialization scripts if needed
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Expose ports
# 7000: Cassandra inter-node communication
# 7001: Cassandra inter-node communication (SSL)
# 7199: Cassandra JMX port
# 9042: Cassandra client port
# 9160: Cassandra Thrift client port
EXPOSE 7000 7001 7199 9042 9160

# Run cassandra
CMD ["cassandra", "-f"]
