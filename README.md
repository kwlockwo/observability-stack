# Grafana Observability Stack for Render

Production-ready observability stack for deployment on Render.com with logs and metrics support.

## Stack Components

- **Grafana** (v11.4.0) - Visualization and dashboards
- **Loki** (v3.3.2) - Log aggregation and querying
- **Prometheus** (v3.2.1) - Metrics collection and storage
- **OTel Collector** (v0.120.0) - OpenTelemetry telemetry ingestion (logs, metrics, traces)

## Architecture

The stack deploys as 4 separate web services on Render:

1. **Loki** - Log aggregation (10GB persistent disk)
2. **Prometheus** - Metrics storage (10GB persistent disk)
3. **Grafana** - Observability dashboard (1GB persistent disk)
4. **OTel Collector** - Telemetry ingestion (1GB persistent disk)

Data flow:
- Applications send OTLP logs/metrics/traces → OTel Collector
- OTel Collector forwards logs → Loki, metrics → Prometheus (remote write)
- Grafana queries Loki and Prometheus for visualization

## Deployment to Render

### Prerequisites

- A Render account (https://render.com)
- Git repository with this code

### Quick Deploy

1. **Push this repository to GitHub/GitLab**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Deploy to Render**
   - Go to the Render Dashboard
   - Click "New" → "Blueprint"
   - Connect your repository
   - Render will auto-detect `render.yaml`
   - Review the services and click "Apply"

### Access Your Services

After deployment, your services will be available at:

- **Grafana**: `https://grafana-<random>.onrender.com`
- **Loki**: `https://loki-<random>.onrender.com`
- **Prometheus**: `https://prometheus-<random>.onrender.com`
- **OTel Collector**: `https://otel-collector-<random>.onrender.com`

## Sending Telemetry Data

### Via OpenTelemetry (recommended)

Configure your application's OpenTelemetry SDK to send to the OTel Collector:

```javascript
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { OTLPLogExporter } = require('@opentelemetry/exporter-logs-otlp-http');

// OTLP HTTP endpoint
const endpoint = 'https://otel-collector-<your-service>.onrender.com:4318';
```

**OTLP Endpoints:**
- gRPC: `https://otel-collector-<your-service>.onrender.com:4317`
- HTTP: `https://otel-collector-<your-service>.onrender.com:4318`

### Logs directly to Loki

```bash
curl -X POST https://loki-<your-service>.onrender.com/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [{
      "stream": {"job": "my-app"},
      "values": [["'"$(date +%s)000000000"'", "test log message"]]
    }]
  }'
```

## Configuration

### Environment Variables

| Variable | Service | Default | Description |
|----------|---------|---------|-------------|
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana | auto-generated | Grafana admin password |
| `GF_AUTH_ANONYMOUS_ENABLED` | Grafana | `true` | Allow anonymous access |
| `LOKI_ENDPOINT` | OTel Collector | `http://loki:3100/loki/api/v1/push` | Loki push endpoint |
| `PROMETHEUS_REMOTE_WRITE_ENDPOINT` | OTel Collector | `http://prometheus:9090/api/v1/write` | Prometheus remote write endpoint |
| `EXTRA_SCRAPE_TARGETS` | Prometheus | `""` | JSON array of extra scrape targets (see below) |
| `OTEL_EXTRA_CONFIG` | OTel Collector | `""` | Extra OTel Collector config as YAML string (see below) |

### Adding Custom Scrape Targets to Prometheus

**Option 1 — Secret file (recommended):** In the Render dashboard, add a secret file named `scrape_configs.yml` to the Prometheus service. Render will mount it at `/etc/secrets/scrape_configs.yml`. The file should contain a YAML list of `scrape_configs` entries:

```yaml
- job_name: 'my-app'
  static_configs:
    - targets: ['my-app.onrender.com:443']
  scheme: https

- job_name: 'another-service'
  static_configs:
    - targets: ['another.internal:8080']
```

**Option 2 — Environment variable:** Set `EXTRA_SCRAPE_TARGETS` on the Prometheus service to a JSON array:

```json
[
  {"job_name": "my-app", "targets": ["my-app.onrender.com:443"]},
  {"job_name": "another", "targets": ["another.internal:8080"], "metrics_path": "/custom/metrics"}
]
```

### Adding Custom OTel Collector Configuration

**Option 1 — Secret file (recommended):** In the Render dashboard, add a secret file named `otelcol_extra.yaml` to the OTel Collector service. Render will mount it at `/etc/secrets/otelcol_extra.yaml`. The file is deep-merged with the base config:

```yaml
exporters:
  otlp/my-backend:
    endpoint: "https://my-backend.example.com:4317"
service:
  pipelines:
    traces:
      exporters: [otlp/my-backend]
```

**Option 2 — Environment variable:** Set `OTEL_EXTRA_CONFIG` on the OTel Collector service to a YAML string with the same format.

## Storage and Data Persistence

| Service | Disk Size | Mount Path | Purpose |
|---------|-----------|------------|---------|
| Loki | 10GB | `/loki` | Log storage (chunks + index) |
| Prometheus | 10GB | `/prometheus` | Metrics TSDB (15-day retention) |
| Grafana | 1GB | `/var/lib/grafana` | Dashboards and settings |
| OTel Collector | 1GB | `/var/lib/otelcol` | Collector data |

## Cost Estimate

Based on Render's pricing (as of 2026):

- **Loki**: Starter plan + 10GB disk = $7 + $0.50 = **$7.50/month**
- **Prometheus**: Starter plan + 10GB disk = $7 + $0.50 = **$7.50/month**
- **Grafana**: Starter plan + 1GB disk = $7 + $0.05 = **$7.05/month**
- **OTel Collector**: Starter plan + 1GB disk = $7 + $0.05 = **$7.05/month**

**Total**: ~**$29/month**

## Architecture Files

- `render.yaml` - Render Blueprint configuration
- `loki/` - Loki configuration and Dockerfile
- `prometheus/` - Prometheus configuration, entrypoint, and Dockerfile
- `grafana/` - Grafana configuration and Dockerfile
- `otel-collector/` - OTel Collector configuration, entrypoint, and Dockerfile

## Security Best Practices

1. **Enable Grafana authentication** - Disable anonymous access in production:
   ```yaml
   envVars:
     - key: GF_AUTH_ANONYMOUS_ENABLED
       value: "false"
   ```
2. **Use secret files** for sensitive scrape target configs rather than env vars
3. **Enable HTTPS** - Render provides free SSL certificates automatically
4. **Restrict access** - Use Render's IP allowlisting for internal services

## Troubleshooting

### Services Won't Start

1. Check service logs in Render dashboard
2. Verify environment variables are set correctly

### No Metrics in Grafana

1. Confirm Prometheus is up: `https://prometheus-<random>.onrender.com/-/healthy`
2. Check Prometheus targets page: `https://prometheus-<random>.onrender.com/targets`
3. Verify the Prometheus datasource URL in Grafana points to the correct service

### No Logs in Grafana

1. Confirm Loki is up and receiving data
2. Check OTel Collector logs for pipeline errors
3. Verify `LOKI_ENDPOINT` is set correctly on the OTel Collector service

### OTel Collector Not Receiving Data

1. Check the collector health: `https://otel-collector-<random>.onrender.com` (port 13133)
2. Verify your application is sending to the correct OTLP endpoint
3. Check collector logs for receiver errors
