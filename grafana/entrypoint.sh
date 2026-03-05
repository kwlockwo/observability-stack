#!/bin/sh
set -e

# RENDER_EXTERNAL_URL is the full public HTTPS URL Render injects automatically.
# Map it to GF_SERVER_ROOT_URL so Grafana redirects and cookie paths are correct.
if [ -n "$RENDER_EXTERNAL_URL" ]; then
    export GF_SERVER_ROOT_URL="$RENDER_EXTERNAL_URL"
fi

exec /run.sh "$@"
