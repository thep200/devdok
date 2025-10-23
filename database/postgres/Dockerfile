ARG POSTGRES_VERSION=16-alpine
FROM postgres:${POSTGRES_VERSION}

# Copy custom postgresql.conf
COPY postgresql.conf /etc/postgresql/postgresql.conf

# Set proper permissions
RUN chmod 644 /etc/postgresql/postgresql.conf && \
  chown postgres:postgres /etc/postgresql/postgresql.conf

# Expose port
EXPOSE 5432

# Use custom config
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
