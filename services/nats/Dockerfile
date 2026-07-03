FROM nats:2.10-alpine

# Copy custom configuration if needed
COPY nats-server.conf /etc/nats/nats-server.conf

# Expose NATS ports
# 4222 - Client connections
# 8222 - HTTP monitoring
# 6222 - Clustering
EXPOSE 4222 8222 6222

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nats-server --help > /dev/null || exit 1

# Start NATS server with configuration
CMD ["nats-server", "--config", "/etc/nats/nats-server.conf"]
