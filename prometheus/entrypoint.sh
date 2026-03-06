#!/bin/sh
set -e

CONFIG_FILE="/etc/prometheus/prometheus.yml"
# Render mounts secret files at /etc/secrets/<filename>
EXTRA_SCRAPE_FILE="/etc/secrets/scrape_configs.yml"
MERGED_CONFIG="/tmp/prometheus-merged.yml"

# Start with the base config, substituting fromService hostports for scrape targets
cp "$CONFIG_FILE" "$MERGED_CONFIG"


# Option 1: Append extra scrape configs from a Render secret file (preferred).
# In the Render dashboard, add a secret file named "scrape_configs.yml" to the
# Prometheus service. Render will mount it at /etc/secrets/scrape_configs.yml.
# The file should contain a YAML list of scrape_configs entries, e.g.:
#
#   - job_name: 'my-app'
#     static_configs:
#       - targets: ['my-app.internal:8080']
#
if [ -f "$EXTRA_SCRAPE_FILE" ] && [ -s "$EXTRA_SCRAPE_FILE" ]; then
    echo "Loading extra scrape configs from $EXTRA_SCRAPE_FILE"
    printf '\n' >> "$MERGED_CONFIG"
    cat "$EXTRA_SCRAPE_FILE" >> "$MERGED_CONFIG"

# Option 2: Parse EXTRA_SCRAPE_TARGETS env var — a JSON array of objects with
# 'job_name' and 'targets' (array of host:port strings), e.g.:
#   EXTRA_SCRAPE_TARGETS='[{"job_name":"my-app","targets":["my-app.internal:8080"]}]'
elif [ -n "$EXTRA_SCRAPE_TARGETS" ]; then
    echo "Loading extra scrape configs from EXTRA_SCRAPE_TARGETS env var"
    # Use python3 (available in the prometheus image base) to convert JSON -> YAML
    python3 - <<EOF >> "$MERGED_CONFIG"
import json, os, sys

targets = json.loads(os.environ['EXTRA_SCRAPE_TARGETS'])
for job in targets:
    job_name = job['job_name']
    hosts = job['targets']
    metrics_path = job.get('metrics_path', '/metrics')
    labels = job.get('labels', {})

    print(f"  - job_name: '{job_name}'")
    print(f"    metrics_path: {metrics_path}")
    if labels:
        print("    relabel_configs: []")
        print("    static_configs:")
        print("      - targets:")
        for h in hosts:
            print(f"          - '{h}'")
        print("        labels:")
        for k, v in labels.items():
            print(f"          {k}: '{v}'")
    else:
        print("    static_configs:")
        print("      - targets:")
        for h in hosts:
            print(f"          - '{h}'")
EOF
fi

exec /bin/prometheus \
    --config.file="$MERGED_CONFIG" \
    --storage.tsdb.path=/prometheus \
    --storage.tsdb.retention.time=15d \
    --web.console.libraries=/usr/share/prometheus/console_libraries \
    --web.console.templates=/usr/share/prometheus/consoles \
    --web.enable-lifecycle \
    --web.enable-remote-write-receiver \
    "$@"
