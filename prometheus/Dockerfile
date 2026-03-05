ARG PROMETHEUS_VERSION=v3.2.1
FROM prom/prometheus:${PROMETHEUS_VERSION}

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
