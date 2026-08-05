#!/bin/bash

echo "Removing Boomi Observability Stack..."
echo ""

echo "Stopping containers..."
docker stop grafana prometheus otel-collector control-plane vector opensearch 2>/dev/null || true

echo "Removing containers..."
docker rm grafana prometheus otel-collector control-plane vector opensearch 2>/dev/null || true

echo "Removing network..."
docker network rm boomi-net 2>/dev/null || true

echo ""
echo "Containers and network removed."
echo ""
echo "WARNING: Data volumes still exist:"
echo "  opensearch-data, grafana-data, consumers-data,"
echo "  otel-config, prometheus-config, prometheus-data"
echo ""
read -p "Remove data volumes too? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker volume rm \
    opensearch-data grafana-data consumers-data \
    otel-config prometheus-config prometheus-data \
    2>/dev/null || true
  echo "Volumes removed — complete uninstall finished."
else
  echo "Volumes kept. To remove later:"
  echo "  docker volume rm opensearch-data grafana-data consumers-data otel-config prometheus-config prometheus-data"
fi

echo ""
