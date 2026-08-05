#!/bin/bash

echo "Starting Boomi Observability Stack..."
echo ""

echo "1. Starting OpenSearch..."
docker start opensearch

echo "   Waiting for OpenSearch..."
until curl -sf "http://localhost:9200/_cluster/health" >/dev/null 2>&1; do sleep 3; done
echo "   OpenSearch ready."

echo "2. Starting Control Plane..."
docker start control-plane

echo "3. Starting OTel Collector..."
docker start otel-collector

echo "4. Starting Vector..."
docker start vector

echo "5. Starting Prometheus..."
docker start prometheus

echo "6. Starting Grafana..."
docker start grafana

echo ""
echo "=================================================="
echo "  Stack started."
echo ""
echo "  Control Plane:  https://localhost:8090"
echo "  Grafana:        http://localhost:3000"
echo "  OpenSearch API: http://localhost:9200"
echo "=================================================="
