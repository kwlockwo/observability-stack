ARG GRAFANA_MCP_VERSION=0.11.4
FROM grafana/mcp-grafana:${GRAFANA_MCP_VERSION} AS mcp

FROM alpine:3.21
RUN apk add --no-cache caddy libcap && setcap -r $(which caddy) 2>/dev/null || true
COPY --from=mcp /app/mcp-grafana /app/mcp-grafana
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
