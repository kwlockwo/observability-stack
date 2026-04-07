#!/bin/sh
set -e

if [ -n "$GRAFANA_HOST" ]; then
    export GRAFANA_URL="http://${GRAFANA_HOST}"
fi

exec /app/mcp-grafana "$@"
