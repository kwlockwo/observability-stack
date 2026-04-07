#!/bin/sh
set -e

if [ -n "$GRAFANA_HOST" ]; then
    export GRAFANA_URL="http://${GRAFANA_HOST}"
fi

# Start MCP server on localhost:8000 (not exposed publicly — Caddy proxies it)
/app/mcp-grafana --transport sse --address 0.0.0.0:8000 &

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
