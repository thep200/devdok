ARG POSTGRES_VERSION=alpine
FROM postgres:${POSTGRES_VERSION}

# Copy custom postgresql.conf
COPY postgresql.conf /etc/postgresql/postgresql.conf

# Expose port
EXPOSE 5432

# Use custom config
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
