# Boomi Observability Stack

A Docker-based observability pipeline for Boomi runtimes. Receives logs, metrics, and traces via OTLP and fans out traces to multiple downstream consumers — managed through a browser-based Control Plane UI.

**GitHub:** https://github.com/pythonicsshahdev/observability-stack  
**Docker Hub:** https://hub.docker.com/u/pythonicshahdev

---

## Quick Start

```bash
curl -O https://raw.githubusercontent.com/pythonicsshahdev/observability-stack/main/install-boomi-stack.sh
chmod +x install-boomi-stack.sh && ./install-boomi-stack.sh
```

To set custom credentials before installing:

```bash
export GRAFANA_PASSWORD=mypassword
export CONTROL_PLANE_PASSWORD=mypassword
./install-boomi-stack.sh
```

---

## Architecture

| Component | Ports | Signals | Destination |
|---|---|---|---|
| **Vector** | :4317 (gRPC), :4318 (HTTP) | Logs + Metrics | OpenSearch |
| **OTel Collector** | :4319 (gRPC), :4320 (HTTP) | Traces | OpenSearch + consumer fanout |
| **Control Plane** | :8090 (HTTPS) | — | Manages trace consumers |
| **Grafana** | :3000 | — | Pre-built dashboards |

Logs and metrics go directly to OpenSearch via Vector. Traces are handled by the OTel Collector, which fans them out to OpenSearch and any enabled consumers.

---

## Access Points

| Service | URL | Default Credentials |
|---|---|---|
| **Control Plane** | https://localhost:8090 | admin / changeme |
| **Grafana** | http://localhost:3000 | admin / changeme |
| **OpenSearch API** | http://localhost:9200 | None |

> **Note:** The Control Plane uses a self-signed TLS cert — accept the browser warning on first visit.

---

## Configure Boomi Atom

Add these environment variables in **Atom Management → Properties**:

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_LOGS_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_SERVICE_NAME=boomi-runtime
```

For traces:

```
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://host.docker.internal:4319
OTEL_TRACES_EXPORTER=otlp
```

---

## Stack Management

```bash
./status-boomi-stack.sh    # Check container and telemetry status
./stop-boomi-stack.sh      # Stop all containers (data preserved)
./start-boomi-stack.sh     # Restart stopped containers
./remove-boomi-stack.sh    # Remove containers and optionally volumes
```

---

## Supported Trace Consumers

Toggle consumers on/off via the Control Plane UI at https://localhost:8090.

| Consumer | Notes |
|---|---|
| New Relic | Free tier: 100 GB/month |
| Datadog | — |
| Dynatrace | OTLP native since v1.222+ |
| Splunk | HEC endpoint |

---

## Ports

| Port | Component | Purpose |
|---|---|---|
| 4317 | Vector | OTLP gRPC — Logs + Metrics |
| 4318 | Vector | OTLP HTTP — Logs + Metrics |
| 4319 | OTel Collector | OTLP gRPC — Traces |
| 4320 | OTel Collector | OTLP HTTP — Traces |
| 3000 | Grafana | Dashboards |
| 8090 | Control Plane | Consumer management UI |
| 9200 | OpenSearch | REST API |

---

## Multi-Node Runtimes

All Boomi Atoms point their OTLP config at the same host — data flows in automatically. For larger clusters:

| Option | When to apply |
|---|---|
| Increase OpenSearch heap (`OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g`) | Multiple nodes with sustained telemetry |
| Deploy on a dedicated host | Any production or long-running cluster |
| Replace local OpenSearch with AWS OpenSearch or Elastic Cloud | High-volume clusters needing storage durability |

---

## Troubleshooting

```bash
docker logs vector
docker logs otel-collector
docker logs opensearch
docker logs grafana
docker logs control-plane
```

Verify data is flowing:

```bash
curl http://localhost:9200/boomi-logs*/_count
curl http://localhost:9200/boomi-metrics*/_count
curl http://localhost:9200/ss4o_traces-*/_count
```
