ARG GRAFANA_MCP_VERSION=latest
FROM grafana/mcp-grafana:${GRAFANA_MCP_VERSION} AS mcp

FROM caddy:2-alpine
COPY --from=mcp /app/mcp-grafana /app/mcp-grafana
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
