ARG OTEL_VERSION=0.120.0
FROM otel/opentelemetry-collector-contrib:${OTEL_VERSION} AS collector

FROM alpine:3.21
COPY --from=collector /otelcol-contrib /otelcol-contrib

COPY config.yaml /etc/otelcol-contrib/config.yaml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
