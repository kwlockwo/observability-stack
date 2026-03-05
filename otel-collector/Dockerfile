ARG OTEL_VERSION=0.120.0
FROM otel/opentelemetry-collector-contrib:${OTEL_VERSION}

COPY config.yaml /etc/otelcol-contrib/config.yaml
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
