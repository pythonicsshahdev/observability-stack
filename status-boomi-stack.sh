#!/bin/bash

echo "=================================================="
echo "  Boomi Observability Stack - Status"
echo "=================================================="
echo ""

echo "Containers:"
echo ""
docker ps -a \
  --filter "name=opensearch" \
  --filter "name=vector" \
  --filter "name=otel-collector" \
  --filter "name=prometheus" \
  --filter "name=grafana" \
  --filter "name=control-plane" \
  --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers found"

echo ""
echo "Telemetry:"
echo ""

if curl -sf "http://localhost:9200/_cluster/health" >/dev/null 2>&1; then
  LOGS=$(curl -sf "http://localhost:9200/boomi-logs*/_count" \
    2>/dev/null | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
  METRICS=$(curl -sf "http://localhost:9200/boomi-metrics*/_count" \
    2>/dev/null | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
  TRACES=$(curl -sf "http://localhost:9200/ss4o_traces-*/_count" \
    2>/dev/null | grep -o '"count":[0-9]*' | grep -o '[0-9]*')

  echo "  Logs:    ${LOGS:-0} documents"
  echo "  Metrics: ${METRICS:-0} documents"
  echo "  Traces:  ${TRACES:-0} documents"

  echo ""
  echo "Indices:"
  curl -sf \
    "http://localhost:9200/_cat/indices?v&h=index,docs.count,store.size&s=index" \
    2>/dev/null | grep -v "^\." || echo "  No indices found"
else
  echo "  OpenSearch not reachable"
fi

echo ""
echo "Access Points:"
echo "  Control Plane:   https://localhost:8090  (admin / changeme)"
echo "  Grafana:         http://localhost:3000   (admin / changeme)"
echo "  OpenSearch API:  http://localhost:9200"
echo ""
echo "Boomi Atom OTLP Endpoints:"
echo "  Logs + Metrics:  localhost:4317 (gRPC) / localhost:4318 (HTTP)"
echo "  Traces:          localhost:4319 (gRPC) / localhost:4320 (HTTP)"
echo "=================================================="
