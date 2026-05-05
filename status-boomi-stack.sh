#!/bin/bash

echo "=================================================="
echo "Boomi Observability Stack - Status"
echo "=================================================="
echo ""

echo "Containers:"
echo ""
docker ps -a --filter "name=opensearch" --filter "name=vector" --filter "name=grafana" --filter "name=otel" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers found"

echo ""
echo "=================================================="
echo "Data Statistics:"
echo "=================================================="
echo ""

# Check if OpenSearch is accessible
if curl -s http://localhost:9200 >/dev/null 2>&1; then
  echo "OpenSearch: ✅ Running"
  echo ""
  
  # Get counts
  LOGS=$(curl -s "http://localhost:9200/boomi-logs-*/_count" 2>/dev/null | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
  METRICS=$(curl -s "http://localhost:9200/boomi-metrics-*/_count" 2>/dev/null | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
  TRACES=$(curl -s "http://localhost:9200/boomi-traces/_count" 2>/dev/null | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
  
  echo "  Logs:    ${LOGS:-0} documents"
  echo "  Metrics: ${METRICS:-0} documents"
  echo "  Traces:  ${TRACES:-0} documents"
  
  # Show index details
  echo ""
  echo "Indices:"
  curl -s "http://localhost:9200/_cat/indices?v&h=index,docs.count,store.size" 2>/dev/null | grep boomi || echo "  No boomi indices found"
else
  echo "OpenSearch: ❌ Not accessible"
fi

echo ""
echo "=================================================="
echo "Access Points:"
echo "=================================================="
echo ""
echo "  Grafana:              http://localhost:3000 (admin/admin)"
echo "  OpenSearch Dashboards: http://localhost:5601"
echo "  OpenSearch API:        http://localhost:9200"
echo ""
echo "=================================================="
echo "OTLP Endpoints (for Boomi configuration):"
echo "=================================================="
echo ""
echo "  Logs/Metrics:  http://host.docker.internal:4317"
echo "  Traces:        http://host.docker.internal:4319"
echo ""
echo "=================================================="
