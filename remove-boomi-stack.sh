#!/bin/bash

echo "Removing Boomi Observability Stack..."
echo ""

echo "Stopping and removing containers..."
docker stop grafana prometheus vector otel-collector control-plane opensearch 2>/dev/null || true
docker rm grafana prometheus vector otel-collector control-plane opensearch 2>/dev/null || true

echo "Removing network..."
docker network rm boomi-net 2>/dev/null || true

echo ""
echo "Containers and network removed."
echo ""
echo "Persistent volumes:"
echo "  opensearch-data   - OpenSearch telemetry data"
echo "  grafana-data      - Grafana state"
echo "  consumers-data    - Control Plane consumer config"
echo "  collector-config  - OTel Collector rendered config"
echo "  prometheus-data   - Prometheus metrics history"
echo ""
read -p "Remove all data volumes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker volume rm opensearch-data grafana-data consumers-data collector-config prometheus-data 2>/dev/null || true
  rm -rf "$HOME/.boomi-stack"
  echo "Data volumes and config files removed."
else
  echo "Volumes kept. To remove later:"
  echo "  docker volume rm opensearch-data grafana-data consumers-data collector-config prometheus-data"
fi

echo ""
