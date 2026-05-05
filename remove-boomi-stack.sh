#!/bin/bash

echo "Removing Boomi Observability Stack..."
echo ""

# Stop containers
echo "Stopping containers..."
docker stop opensearch opensearch-dashboards vector otel-collector grafana 2>/dev/null || true

# Remove containers
echo "Removing containers..."
docker rm opensearch opensearch-dashboards vector otel-collector grafana 2>/dev/null || true

# Remove network
echo "Removing network..."
docker network rm boomi-net 2>/dev/null || true

echo ""
echo "✅ Containers and network removed"
echo ""
echo "⚠️  Data volumes still exist (opensearch-data, grafana-data)"
echo ""
read -p "Do you want to remove data volumes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker volume rm opensearch-data grafana-data 2>/dev/null || true
  echo "✅ Data volumes removed"
  echo ""
  echo "Complete uninstall finished."
else
  echo "Data volumes kept."
  echo ""
  echo "To remove data later:"
  echo "  docker volume rm opensearch-data grafana-data"
fi

echo ""
