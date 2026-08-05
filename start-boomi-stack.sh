#!/bin/bash

echo "Starting Boomi Observability Stack..."
echo ""

echo "1. Starting OpenSearch..."
docker start opensearch

echo "   Waiting for OpenSearch to be healthy..."
until curl -sf "http://localhost:9200/_cluster/health" >/dev/null 2>&1; do
  printf '.'
  sleep 5
done
echo " ready"

echo "2. Starting Vector..."
docker start vector

echo "3. Starting Control Plane..."
docker start control-plane
sleep 3

echo "4. Starting OTel Collector..."
docker start otel-collector

echo "5. Starting Prometheus..."
docker start prometheus

echo "6. Starting Grafana..."
docker start grafana

echo ""
echo "Stack started!"
echo ""
echo "  Control Plane:   https://localhost:8090"
echo "  Grafana:         http://localhost:3000"
echo "  Logs/Metrics:    localhost:4317 (gRPC) / localhost:4318 (HTTP)"
echo "  Traces:          localhost:4319 (gRPC) / localhost:4320 (HTTP)"
echo ""
