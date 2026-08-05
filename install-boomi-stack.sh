#!/bin/bash
set -e

# Credentials — override via env vars or a .env file
OPENSEARCH_PASSWORD=${OPENSEARCH_PASSWORD:-changeme}
GRAFANA_PASSWORD=${GRAFANA_PASSWORD:-changeme}
CONTROL_PLANE_PASSWORD=${CONTROL_PLANE_PASSWORD:-changeme}

echo "=================================================="
echo "  Boomi Observability Stack - Installer"
echo "=================================================="
echo ""

# Load .env if present
if [ -f .env ]; then
  echo "  Loading credentials from .env..."
  set -a; . ./.env; set +a
fi

# ── Network ──────────────────────────────────────────
echo "1. Creating network..."
docker network create boomi-net 2>/dev/null || echo "   Network already exists"

# ── Volumes ──────────────────────────────────────────
echo "2. Creating volumes..."
docker volume create opensearch-data  >/dev/null
docker volume create grafana-data     >/dev/null
docker volume create consumers-data   >/dev/null
docker volume create otel-config      >/dev/null
docker volume create prometheus-config >/dev/null
docker volume create prometheus-data  >/dev/null

# ── OpenSearch ────────────────────────────────────────
echo "3. Starting OpenSearch..."
docker run -d \
  --name opensearch \
  --network boomi-net \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "DISABLE_SECURITY_PLUGIN=true" \
  -e "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" \
  -v opensearch-data:/usr/share/opensearch/data \
  --restart unless-stopped \
  opensearchproject/opensearch:latest

echo "   Waiting for OpenSearch to be healthy..."
until curl -sf "http://localhost:9200/_cluster/health" >/dev/null 2>&1; do
  printf '.'
  sleep 5
done
echo " ready"

# ── Vector (logs + metrics → OpenSearch) ─────────────
echo "4. Starting Vector (logs + metrics)..."
docker run -d \
  --name vector \
  --network boomi-net \
  -p 4317:4317 \
  -p 4318:4318 \
  --restart unless-stopped \
  pythonicshahdev/boomi-vector:latest

# ── Control Plane (seeds otel-config + prometheus-config volumes) ─
echo "5. Starting Control Plane..."
docker run -d \
  --name control-plane \
  --network boomi-net \
  -p 8090:8090 \
  -e "CONSUMERS_PATH=/data/consumers.json" \
  -e "TEMPLATE_PATH=/templates/otel-collector-config.hbs" \
  -e "CONFIG_OUTPUT_PATH=/config/otel-collector-config.yaml" \
  -e "COLLECTOR_CONTAINER=otel-collector" \
  -e "DEPLOY_TARGET=compose" \
  -e "CONTROL_PLANE_USER=admin" \
  -e "CONTROL_PLANE_PASSWORD=${CONTROL_PLANE_PASSWORD}" \
  -v consumers-data:/data \
  -v otel-config:/config \
  -v prometheus-config:/prometheus-config \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  pythonicshahdev/otel-fanout-control-plane:latest

echo "   Waiting for volume seeding..."
sleep 5

# ── OTel Collector (traces + consumer fanout) ─────────
echo "6. Starting OTel Collector (traces + fanout)..."
docker run -d \
  --name otel-collector \
  --network boomi-net \
  -p 4319:4317 \
  -p 4320:4318 \
  -v otel-config:/etc/otelcol-contrib \
  --restart unless-stopped \
  otel/opentelemetry-collector-contrib:latest \
  --config=/etc/otelcol-contrib/otel-collector-config.yaml

# ── Prometheus ────────────────────────────────────────
echo "7. Starting Prometheus..."
docker run -d \
  --name prometheus \
  --network boomi-net \
  -v prometheus-config:/etc/prometheus \
  -v prometheus-data:/prometheus \
  --restart unless-stopped \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.retention.time=7d

# ── Grafana ───────────────────────────────────────────
echo "8. Starting Grafana..."
docker run -d \
  --name grafana \
  --network boomi-net \
  -p 3000:3000 \
  -e "GF_SECURITY_ADMIN_USER=admin" \
  -e "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}" \
  -v grafana-data:/var/lib/grafana \
  --restart unless-stopped \
  pythonicshahdev/otel-fanout-grafana:latest

echo ""
echo "=================================================="
echo "  Stack Installed Successfully"
echo "=================================================="
echo ""
echo "  Control Plane:   https://localhost:8090"
echo "     Login: admin / ${CONTROL_PLANE_PASSWORD}"
echo "     (accept the self-signed cert warning)"
echo ""
echo "  Grafana:         http://localhost:3000"
echo "     Login: admin / ${GRAFANA_PASSWORD}"
echo ""
echo "=================================================="
echo "  Configure your Boomi Atom:"
echo "=================================================="
echo ""
echo "  Logs + Metrics:"
echo "    OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4317"
echo ""
echo "  Traces:"
echo "    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://host.docker.internal:4319"
echo ""
echo "  Common:"
echo "    OTEL_EXPORTER_OTLP_PROTOCOL=grpc"
echo "    OTEL_LOGS_EXPORTER=otlp"
echo "    OTEL_METRICS_EXPORTER=otlp"
echo "    OTEL_TRACES_EXPORTER=otlp"
echo "    OTEL_SERVICE_NAME=boomi-runtime"
echo ""
echo "=================================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
  --filter "name=opensearch" \
  --filter "name=vector" \
  --filter "name=otel-collector" \
  --filter "name=prometheus" \
  --filter "name=grafana" \
  --filter "name=control-plane"
echo "=================================================="
