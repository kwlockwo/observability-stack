ARG GRAFANA_VERSION=11.4.0

# Optional: fetch dashboards from private GitHub repos at build time.
# DASHBOARD_GITHUB_REPOS: semicolon-delimited list of GitHub repo URLs, e.g.
#   https://github.com/org/repo/tree/main/path/to/dashboards
# GITHUB_TOKEN: personal access token with repo read access.
# Dashboards are fetched as JSON files from the specified paths.
FROM alpine:3.21 AS dashboard-fetcher
ARG GITHUB_TOKEN
ARG DASHBOARD_GITHUB_REPOS
RUN apk add --no-cache git && \
    mkdir -p /fetched-dashboards && \
    if [ -n "$DASHBOARD_GITHUB_REPOS" ] && [ -n "$GITHUB_TOKEN" ]; then \
      echo "$DASHBOARD_GITHUB_REPOS" | tr ';' '\n' | while IFS= read -r url; do \
        [ -z "$url" ] && continue; \
        # Extract org/repo and optional subpath from URL
        # Supports: https://github.com/org/repo or https://github.com/org/repo/tree/branch/path
        path=$(echo "$url" | sed 's|https://github.com/||'); \
        repo=$(echo "$path" | cut -d'/' -f1-2); \
        subpath=$(echo "$path" | grep -oP '(?<=tree/[^/]+/).*' || true); \
        branch=$(echo "$path" | grep -oP '(?<=tree/)[^/]+' || echo 'main'); \
        git clone --depth=1 --branch "$branch" \
          "https://x-token:${GITHUB_TOKEN}@github.com/${repo}.git" /tmp/repo-clone && \
        if [ -n "$subpath" ]; then \
          cp /tmp/repo-clone/${subpath}/*.json /fetched-dashboards/ 2>/dev/null || true; \
        else \
          cp /tmp/repo-clone/*.json /fetched-dashboards/ 2>/dev/null || true; \
        fi; \
        rm -rf /tmp/repo-clone; \
      done; \
    fi

FROM grafana/grafana:${GRAFANA_VERSION}
COPY provisioning/datasources/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY provisioning/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY provisioning/grafana.ini /etc/grafana/grafana.ini
COPY dashboards/ /etc/grafana/dashboards/
COPY --from=dashboard-fetcher /fetched-dashboards/ /etc/grafana/dashboards/

ENV GF_AUTH_ANONYMOUS_ENABLED=false
ENV GF_AUTH_DISABLE_LOGIN_FORM=false
