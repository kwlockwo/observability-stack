ARG GRAFANA_MCP_VERSION=latest
FROM grafana/mcp-grafana:${GRAFANA_MCP_VERSION}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
