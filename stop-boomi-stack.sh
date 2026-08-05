#!/bin/bash

echo "Stopping Boomi Observability Stack..."
echo ""

docker stop \
  grafana \
  prometheus \
  otel-collector \
  control-plane \
  vector \
  opensearch \
  2>/dev/null || true

echo ""
echo "All containers stopped. Data is preserved in volumes."
echo ""
echo "To start again:    ./start-boomi-stack.sh"
echo "To remove:         ./remove-boomi-stack.sh"
echo "To check status:   ./status-boomi-stack.sh"
echo ""
