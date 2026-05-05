ARG SCYLLADB_VERSION=5.2.5
FROM scylladb/scylla:${SCYLLADB_VERSION}

LABEL maintainer="thep200 <thep200.work@gmail.com>"

# Copy custom scylla.yaml configuration
COPY scylla.yaml /etc/scylla/scylla.yaml

# Set proper permissions
RUN chmod 644 /etc/scylla/scylla.yaml && \
    chown scylla:scylla /etc/scylla/scylla.yaml

# Copy initialization scripts if needed
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Expose ports
# 7000: ScyllaDB inter-node communication
# 7001: ScyllaDB inter-node communication (SSL)
# 7199: ScyllaDB JMX port
# 9042: ScyllaDB client port
# 9160: ScyllaDB Thrift client port
# 10000: ScyllaDB metrics port
EXPOSE 7000 7001 7199 9042 9160 10000

# Run scylla with developer mode (for single node)
ENTRYPOINT ["/docker-entrypoint.py"]
CMD ["scylla", "--developer-mode", "1"]
