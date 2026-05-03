# Boomi Observability Stack

Complete observability solution for Boomi integrations using OpenTelemetry, Vector, OpenSearch, and Grafana.

## Quick Start (One Command)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/pythonicshahdev/boomi-observability-stack/main/install-boomi-stack.sh)
```

## What Gets Installed

- **OpenSearch** - Stores all telemetry data (logs, metrics, traces)
- **OpenSearch Dashboards** - Web UI for log analysis and search
- **Vector** - OTLP receiver for logs and metrics
- **OTel Collector** - Handles distributed traces
- **Grafana** - Beautiful dashboards and alerting

## Architecture
Boomi Atom/API Gateway
↓
┌───┴───┐
↓       ↓
Vector   OTel Collector
(Logs/   (Traces)
Metrics)      ↓
↓         ↓
└─→ OpenSearch ←─┘
↓      ↓
OpenSearch  Grafana
Dashboards

## Access

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / admin |
| **OpenSearch Dashboards** | http://localhost:5601 | None |
| **OpenSearch API** | http://localhost:9200 | None |

## Configure Boomi

### Boomi Atom (Runtime)

Add environment variables in **Atom Management → Properties:**

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_LOGS_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_SERVICE_NAME=boomi-runtime
```

**For traces:**
```bash
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://host.docker.internal:4319
OTEL_TRACES_EXPORTER=otlp
```

### Boomi API Gateway

1. Navigate to **API Gateway → OpenTelemetry Settings**
2. **Enable OpenTelemetry:** Toggle ON
3. **Exporter Endpoint/URL:** `http://host.docker.internal:4317`
4. **Add Custom Header:**
   - Key: `service.name`
   - Value: `boomi-api-gateway`
5. **Enable:** Logs, Metrics, Traces
6. **Traces Endpoint:** `http://host.docker.internal:4319`
7. **Save**

## Management Commands

### Check Status

```bash
bash <(curl -sSL https://raw.githubusercontent.com/pythonicshahdev/boomi-observability-stack/main/status-boomi-stack.sh)
```

Or locally:
```bash
./status-boomi-stack.sh
```

### Stop Stack

```bash
bash <(curl -sSL https://raw.githubusercontent.com/pythonicshahdev/boomi-observability-stack/main/stop-boomi-stack.sh)
```

### Start Stack (After Stop)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/pythonicshahdev/boomi-observability-stack/main/start-boomi-stack.sh)
```

### Uninstall

```bash
bash <(curl -sSL https://raw.githubusercontent.com/pythonicshahdev/boomi-observability-stack/main/remove-boomi-stack.sh)
```

## Manual Installation

If you prefer to run commands yourself:

### 1. Create Network
```bash
docker network create boomi-net
```

### 2. Start OpenSearch
```bash
docker run -d --name opensearch --network boomi-net -p 9200:9200 -e "discovery.type=single-node" -e "DISABLE_SECURITY_PLUGIN=true" -e "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" -v opensearch-data:/usr/share/opensearch/data --restart unless-stopped opensearchproject/opensearch:latest
```

### 3. Wait for OpenSearch (Important!)
```bash
sleep 30
```

### 4. Start OpenSearch Dashboards
```bash
docker run -d --name opensearch-dashboards --network boomi-net -p 5601:5601 -e "OPENSEARCH_HOSTS=http://opensearch:9200" -e "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true" --restart unless-stopped opensearchproject/opensearch-dashboards:latest
```

### 5. Start Vector
```bash
docker run -d --name vector --network boomi-net -p 4317:4317 -p 4318:4318 --restart unless-stopped pythonicshahdev/boomi-vector:latest
```

### 6. Start OTel Collector
```bash
docker run -d --name otel-collector --network boomi-net -p 4319:4317 -p 4320:4318 --restart unless-stopped pythonicshahdev/boomi-otel-collector:latest
```

### 7. Start Grafana
```bash
docker run -d --name grafana --network boomi-net -p 3000:3000 -e "GF_SECURITY_ADMIN_PASSWORD=admin" -e "GF_SECURITY_ADMIN_USER=admin" -v grafana-data:/var/lib/grafana --restart unless-stopped grafana/grafana:latest
```

## Ports

| Port | Service | Purpose |
|------|---------|---------|
| **3000** | Grafana | Web UI |
| **4317** | Vector | OTLP gRPC (logs/metrics) |
| **4318** | Vector | OTLP HTTP (logs/metrics) |
| **4319** | OTel Collector | OTLP gRPC (traces) |
| **4320** | OTel Collector | OTLP HTTP (traces) |
| **5601** | OpenSearch Dashboards | Web UI |
| **9200** | OpenSearch | REST API |

## Grafana Setup

### Configure Data Sources

1. Go to http://localhost:3000 (admin/admin)
2. **Configuration** → **Data sources** → **Add data source**
3. Search: **"Elasticsearch"**

**Boomi Metrics:**
Name: Boomi Metrics
URL: http://opensearch:9200
Index name: boomi-metrics-*
Pattern: No pattern
Time field name: timestamp
Version: 8.0+
Default query mode: Metrics

**Boomi Logs:**
Name: Boomi Logs
URL: http://opensearch:9200
Index name: boomi-logs-*
Pattern: No pattern
Time field name: timestamp
Version: 8.0+
Default query mode: Logs

### Create Dashboard

See [GRAFANA-SETUP.md](docs/GRAFANA-SETUP.md) for detailed dashboard creation guide.

## Docker Images

- **Vector:** https://hub.docker.com/r/pythonicshahdev/boomi-vector
- **OTel Collector:** https://hub.docker.com/r/pythonicshahdev/boomi-otel-collector

**Supported Platforms:**
- linux/amd64 (Intel/AMD)
- linux/arm64 (Apple Silicon, AWS Graviton)

## Troubleshooting

### Check Container Logs
```bash
docker logs vector
docker logs otel-collector
docker logs opensearch
docker logs grafana
```

### Verify Data
```bash
curl http://localhost:9200/boomi-logs-*/_count
curl http://localhost:9200/boomi-metrics-*/_count
```

### Restart a Service
```bash
docker restart vector
docker restart opensearch
```

### Complete Reset
```bash
./remove-boomi-stack.sh
./install-boomi-stack.sh
```

## Support

- **Issues:** https://github.com/pythonicshahdev/boomi-observability-stack/issues
- **Documentation:** https://github.com/pythonicshahdev/boomi-observability-stack

## License

MIT
