# Render Deployment Guide

This guide covers deploying the Grafana Observability Stack to Render.com.

## Prerequisites

- A Render account (https://render.com)
- Git repository with this code
- Render CLI (optional, for local testing)

## Architecture

The stack deploys as 5 separate web services:
1. **MinIO** - S3-compatible object storage (50GB persistent disk)
2. **Loki** - Log aggregation (5GB persistent disk)
3. **Tempo** - Distributed tracing (5GB persistent disk)
4. **Grafana** - Observability dashboard (1GB persistent disk)
5. **Alloy** - Telemetry collector (1GB persistent disk)

All services run on Render's Starter plan with persistent disks.

## Deployment Steps

### 1. Set Up Environment Variables

Before deploying, you need to configure the following environment variables in the Render dashboard:

**Required for all services:**
- `MINIO_ROOT_USER` - MinIO admin username (keep this secret!)
- `MINIO_ROOT_PASSWORD` - MinIO admin password (keep this secret!)

**Optional (have defaults):**
- `MINIO_LOKI_BUCKET` - Bucket name for Loki (default: `loki`)
- `MINIO_TEMPO_BUCKET` - Bucket name for Tempo (default: `tempo`)

### 2. Deploy via Blueprint

1. Push your code to a Git repository (GitHub, GitLab, etc.)
2. Go to the Render Dashboard
3. Click "New" → "Blueprint"
4. Connect your repository
5. Render will detect the `render.yaml` file
6. Review the services and click "Apply"

### 3. Configure Environment Variables

After the initial deployment:

1. Go to each service in the Render dashboard
2. Navigate to "Environment" tab
3. Add the required environment variables:
   - For **MinIO**: Set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
   - For **Loki**: Set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` (same as MinIO)
   - For **Tempo**: Set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` (same as MinIO)
4. Save and redeploy each service

### 4. Update Grafana Configuration

After deployment, you'll need to update Grafana datasource URLs:

1. Get the internal URLs for Loki and Tempo from Render dashboard
2. Update the datasource configuration in Grafana UI or via provisioning files

## Service URLs

After deployment, your services will be available at:

- **Grafana**: `https://grafana.onrender.com` (or your custom domain)
- **Loki**: `https://loki.onrender.com`
- **Tempo**: `https://tempo.onrender.com`
- **Alloy**: `https://alloy.onrender.com`
- **MinIO Console**: `https://minio.onrender.com`

### Internal Communication

Services communicate using Render's internal networking:
- Loki connects to MinIO via the `MINIO_ENDPOINT` environment variable
- Tempo connects to MinIO via the `MINIO_ENDPOINT` environment variable
- Alloy forwards telemetry to Loki and Tempo via internal URLs
- Grafana connects to Loki and Tempo via internal URLs

### Sending Telemetry to Alloy

Send your application's traces to Alloy's OTLP endpoints:
- **gRPC**: `https://alloy.onrender.com:4317`
- **HTTP**: `https://alloy.onrender.com:4318`

## Persistent Storage

Each service has persistent disk storage:

| Service | Disk Size | Mount Path | Purpose |
|---------|-----------|------------|---------|
| MinIO | 50GB | `/data` | Object storage for logs and traces |
| Loki | 5GB | `/loki` | Local cache and WAL |
| Tempo | 5GB | `/tmp/tempo` | Local WAL and cache |
| Grafana | 1GB | `/var/lib/grafana` | Dashboards and settings |
| Alloy | 1GB | `/var/lib/alloy` | Telemetry collector data |

## Cost Estimate

Based on Render's pricing (as of 2026):

- **MinIO**: Starter plan + 50GB disk = ~$7/month + $2.50/month = $9.50/month
- **Loki**: Starter plan + 5GB disk = ~$7/month + $0.25/month = $7.25/month
- **Tempo**: Starter plan + 5GB disk = ~$7/month + $0.25/month = $7.25/month
- **Grafana**: Starter plan + 1GB disk = ~$7/month + $0.05/month = $7.05/month
- **Alloy**: Starter plan + 1GB disk = ~$7/month + $0.05/month = $7.05/month

**Total**: ~$38/month

## Configuration Differences

The stack automatically detects when running on Render and uses cloud-specific configurations:

### Local vs Cloud Configs

| Feature | Local | Cloud (Render) |
|---------|-------|----------------|
| MinIO Endpoint | `minio:9000` | Dynamic (from service) |
| S3 Insecure Mode | `true` | `false` |
| Service Discovery | Docker networking | Render internal URLs |

## Troubleshooting

### MinIO Buckets Not Created

If buckets aren't created automatically:

1. Access MinIO console at your MinIO service URL
2. Login with `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
3. Manually create buckets: `loki` and `tempo`

### Loki/Tempo Can't Connect to MinIO

Check the following:

1. Verify `MINIO_ENDPOINT` environment variable is set correctly
2. Ensure `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` match across all services
3. Check MinIO service logs for authentication errors
4. Verify buckets exist in MinIO console

### Service Won't Start

1. Check service logs in Render dashboard
2. Verify all required environment variables are set
3. Ensure persistent disks are properly mounted
4. Check for port conflicts or configuration errors

## Monitoring

### Health Checks

All services have health check endpoints:

- **MinIO**: `/minio/health/live`
- **Loki**: `/ready`
- **Tempo**: `/ready`
- **Grafana**: `/api/health`

### Logs

Access logs for each service in the Render dashboard under the "Logs" tab.

## Scaling

### Vertical Scaling

Upgrade to larger Render plans for more resources:
- Standard: 2GB RAM, 1 CPU
- Pro: 4GB RAM, 2 CPU

### Storage Scaling

Increase persistent disk size in Render dashboard:
1. Go to service settings
2. Navigate to "Disk" section
3. Increase size as needed
4. Service will restart with new disk size

## Security Best Practices

1. **Use strong credentials** - Change default `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
2. **Enable HTTPS** - Render provides free SSL certificates
3. **Restrict access** - Use Render's IP allowlisting if needed
4. **Rotate credentials** - Periodically update MinIO credentials
5. **Enable authentication** - Configure Grafana authentication for production use

## Backup and Recovery

### MinIO Data Backup

MinIO data is stored on persistent disks. To backup:

1. Use MinIO client (`mc`) to mirror buckets to external storage
2. Set up scheduled backups using Render cron jobs
3. Consider using MinIO bucket replication to another S3-compatible service

### Grafana Configuration Backup

Export Grafana dashboards and datasources:
```bash
# From Grafana UI: Settings → Import/Export
```

## Migration from Docker Compose

To migrate from local Docker Compose deployment:

1. Export data from local MinIO
2. Deploy to Render following this guide
3. Import data to Render MinIO instance
4. Update application endpoints to point to Render URLs

## Additional Resources

- [Render Documentation](https://render.com/docs)
- [MinIO Documentation](https://min.io/docs)
- [Loki Documentation](https://grafana.com/docs/loki)
- [Tempo Documentation](https://grafana.com/docs/tempo)
- [Grafana Documentation](https://grafana.com/docs/grafana)
