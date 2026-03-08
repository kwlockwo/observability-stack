#!/bin/sh
set -e

# RENDER_EXTERNAL_URL is the full public HTTPS URL Render injects automatically.
# Map it to GF_SERVER_ROOT_URL so Grafana redirects and cookie paths are correct.
if [ -n "$RENDER_EXTERNAL_URL" ]; then
    export GF_SERVER_ROOT_URL="$RENDER_EXTERNAL_URL"
fi

# Fetch dashboards from GitHub repos at startup if configured.
if [ -n "$DASHBOARD_GITHUB_REPOS" ] && [ -n "$GITHUB_TOKEN" ]; then
    /home/grafana/bin/fetch-dashboards.sh || echo "Warning: fetch-dashboards.sh failed, continuing anyway"
fi

exec /run.sh "$@"
