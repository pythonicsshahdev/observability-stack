#!/bin/bash

echo "Stopping Boomi Observability Stack..."
echo ""

docker stop \
  opensearch \
  opensearch-dashboards \
  vector \
  otel-collector \
  grafana \
  2>/dev/null || true

echo ""
echo "✅ All containers stopped"
echo ""
echo "Containers are stopped but not removed."
echo "Data is preserved in volumes."
echo ""
echo "To start again:    ./start-boomi-stack.sh"
echo "To remove:         ./remove-boomi-stack.sh"
echo "To check status:   ./status-boomi-stack.sh"
echo ""
