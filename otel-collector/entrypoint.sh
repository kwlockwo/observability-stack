#!/bin/sh
set -e

# Render assigns a dynamic port via $PORT (default 10000).
# Bind the health_check extension to it so Render's health check passes.
export HEALTH_CHECK_PORT="${PORT:-10000}"

# Render provides host:port via fromService. Construct the full URLs here.
if [ -n "$LOKI_HOST" ]; then
    export LOKI_ENDPOINT="http://${LOKI_HOST}/loki/api/v1/push"
fi
if [ -n "$PROMETHEUS_HOST" ]; then
    export PROMETHEUS_REMOTE_WRITE_ENDPOINT="http://${PROMETHEUS_HOST}/api/v1/write"
fi

BASE_CONFIG="/etc/otelcol-contrib/config.yaml"
# Render mounts secret files at /etc/secrets/<filename>
EXTRA_CONFIG_FILE="/etc/secrets/otelcol_extra.yaml"
MERGED_CONFIG="/tmp/otelcol-merged.yaml"

# Start with the base config
cp "$BASE_CONFIG" "$MERGED_CONFIG"

# Option 1: Merge extra config from a Render secret file (preferred).
# In the Render dashboard, add a secret file named "otelcol_extra.yaml" to the
# OTel Collector service. Render will mount it at /etc/secrets/otelcol_extra.yaml.
# The file should contain valid OTel Collector YAML — it will be deep-merged with
# the base config (later files take precedence).
#
# Example secret file content:
#   exporters:
#     otlp/my-backend:
#       endpoint: "https://my-backend.example.com:4317"
#   service:
#     pipelines:
#       traces:
#         exporters: [otlp/my-backend]

if [ -f "$EXTRA_CONFIG_FILE" ] && [ -s "$EXTRA_CONFIG_FILE" ]; then
    echo "Loading extra OTel config from $EXTRA_CONFIG_FILE"
    exec /otelcol-contrib \
        --config="$MERGED_CONFIG" \
        --config="$EXTRA_CONFIG_FILE" \
        "$@"

# Option 2: Use OTEL_EXTRA_CONFIG env var (YAML string).
# The collector supports env var expansion natively, but for injecting whole
# config blocks we write it to a temp file and pass it as a second --config.
elif [ -n "$OTEL_EXTRA_CONFIG" ]; then
    echo "Loading extra OTel config from OTEL_EXTRA_CONFIG env var"
    EXTRA_TMP="/tmp/otelcol-extra.yaml"
    printf '%s\n' "$OTEL_EXTRA_CONFIG" > "$EXTRA_TMP"
    exec /otelcol-contrib \
        --config="$MERGED_CONFIG" \
        --config="$EXTRA_TMP" \
        "$@"

else
    exec /otelcol-contrib \
        --config="$MERGED_CONFIG" \
        "$@"
fi
