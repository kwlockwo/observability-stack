ARG LOKI_VERSION=3.3.2
FROM grafana/loki:${LOKI_VERSION}

# Copy configuration
COPY loki-config.yml /etc/loki/loki-config.yml

# Start Loki with config
CMD ["-config.file=/etc/loki/loki-config.yml"]
