#!/bin/bash

echo "Starting Boomi Observability Stack..."
echo ""

echo "1. Starting OpenSearch..."
docker start opensearch

echo "2. Waiting for OpenSearch (10 seconds)..."
sleep 10

echo "3. Starting OpenSearch Dashboards..."
docker start opensearch-dashboards

echo "4. Starting Vector..."
docker start vector

echo "5. Starting OTel Collector..."
docker start otel-collector

echo "6. Starting Grafana..."
docker start grafana

echo ""
echo "✅ Stack started!"
echo ""
echo "Access:"
echo "  Grafana:              http://localhost:3000 (admin/admin)"
echo "  OpenSearch Dashboards: http://localhost:5601"
echo "  OpenSearch API:        http://localhost:9200"
echo ""
