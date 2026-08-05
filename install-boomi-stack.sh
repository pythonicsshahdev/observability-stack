#!/bin/bash
set -e

GRAFANA_PASSWORD=${GRAFANA_PASSWORD:-changeme}
CONTROL_PLANE_PASSWORD=${CONTROL_PLANE_PASSWORD:-changeme}
WORK_DIR="$HOME/.boomi-stack"

echo "=================================================="
echo "  Boomi Observability Stack - Installer"
echo "=================================================="
echo ""

mkdir -p "$WORK_DIR"

# Write prometheus config inline (no file download needed)
cat > "$WORK_DIR/prometheus.yml" <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: otel-collector
    static_configs:
      - targets: ['otel-collector:8888']
  - job_name: vector
    static_configs:
      - targets: ['vector:9598']
EOF

echo "1. Creating Docker network..."
docker network create boomi-net 2>/dev/null || echo "   Network already exists"

echo "2. Starting OpenSearch..."
docker run -d \
  --name opensearch \
  --network boomi-net \
  -p 9200:9200 \
  -p 9600:9600 \
  -e "discovery.type=single-node" \
  -e "DISABLE_SECURITY_PLUGIN=true" \
  -e "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" \
  -v opensearch-data:/usr/share/opensearch/data \
  --restart unless-stopped \
  opensearchproject/opensearch:latest

echo "   Waiting for OpenSearch..."
until curl -sf "http://localhost:9200/_cluster/health" >/dev/null 2>&1; do sleep 3; done
echo "   OpenSearch ready."

echo "3. Starting Control Plane..."
# Mounts collector-config volume at /config so the control plane can write
# otel-collector-config.yaml there; the otel-collector reads from the same volume.
docker run -d \
  --name control-plane \
  --network boomi-net \
  -p 8090:8090 \
  -e "CONSUMERS_PATH=/data/consumers.json" \
  -e "TEMPLATE_PATH=/templates/otel-collector-config.hbs" \
  -e "CONFIG_OUTPUT_PATH=/config/otel-collector-config.yaml" \
  -e "COLLECTOR_CONTAINER=otel-collector" \
  -e "CONTROL_PLANE_USER=admin" \
  -e "CONTROL_PLANE_PASSWORD=$CONTROL_PLANE_PASSWORD" \
  -e "OPENSEARCH_URL=http://opensearch:9200" \
  -e "SOURCES_PATH=/data/sources.json" \
  -v consumers-data:/data \
  -v collector-config:/config \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  pythonicshahdev/otel-fanout-control-plane:latest

echo "   Waiting for collector config to initialize..."
sleep 3

echo "4. Starting OTel Collector (Traces)..."
docker run -d \
  --name otel-collector \
  --network boomi-net \
  -p 4319:4317 \
  -p 4320:4318 \
  -v collector-config:/config \
  --restart on-failure \
  otel/opentelemetry-collector-contrib:latest \
  --config=/config/otel-collector-config.yaml

echo "5. Starting Vector (Logs + Metrics)..."
docker run -d \
  --name vector \
  --network boomi-net \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 9598:9598 \
  --restart unless-stopped \
  pythonicshahdev/boomi-vector:latest

echo "6. Starting Prometheus..."
docker run -d \
  --name prometheus \
  --network boomi-net \
  -v "$WORK_DIR/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v prometheus-data:/prometheus \
  --restart unless-stopped \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.retention.time=7d

echo "7. Starting Grafana..."
docker run -d \
  --name grafana \
  --network boomi-net \
  -p 3000:3000 \
  -e "GF_SECURITY_ADMIN_USER=admin" \
  -e "GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PASSWORD" \
  -v grafana-data:/var/lib/grafana \
  --restart unless-stopped \
  pythonicshahdev/otel-fanout-grafana:latest

echo ""
echo "=================================================="
echo "  Boomi Observability Stack - Ready"
echo "=================================================="
echo ""
echo "Access Points:"
echo "  Control Plane:  https://localhost:8090  (admin / $CONTROL_PLANE_PASSWORD)"
echo "  Grafana:        http://localhost:3000   (admin / $GRAFANA_PASSWORD)"
echo "  OpenSearch API: http://localhost:9200"
echo ""
echo "  Note: Control Plane uses a self-signed cert - accept the browser warning."
echo ""
echo "Boomi Atom OTLP Endpoints:"
echo "  Logs + Metrics (gRPC): http://host.docker.internal:4317"
echo "  Logs + Metrics (HTTP): http://host.docker.internal:4318"
echo "  Traces (gRPC):         http://host.docker.internal:4319"
echo "  Traces (HTTP):         http://host.docker.internal:4320"
echo ""
echo "=================================================="
docker ps -a \
  --filter "name=opensearch" \
  --filter "name=vector" \
  --filter "name=otel-collector" \
  --filter "name=prometheus" \
  --filter "name=grafana" \
  --filter "name=control-plane" \
  --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "=================================================="
