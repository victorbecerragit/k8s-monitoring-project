# k8s-monitoring-project

A comprehensive Kubernetes monitoring and observability stack featuring Prometheus, Grafana, Loki, Alloy, and integrated log aggregation solutions.

## Project Overview

This repository contains production-ready Kubernetes manifests and Helm configurations for deploying a complete observability solution with metrics collection, log aggregation, visualization, and alerting capabilities.

## Core Components

### 1. **Kube Prometheus Stack** (`kube-prometheus-stack/`)
- **Prometheus Operator**: Automated prometheus deployment and configuration via CRDs
- **Prometheus**: Time-series metrics collection and storage
- **AlertManager**: Alert routing and management
- **Node Exporter**: Hardware and kernel metrics
- Installation via Helm with customizable values
- Custom alert rules and ServiceMonitor configurations

**Files**:
- `install.sh` - Installation script for prometheus-operator and AlertManager
- `kube-prometheus-stack.yaml` - Kubernetes manifests
- `values.yaml` - Helm chart values configuration

### 2. **Grafana Monitoring Stack** (`grafana/`, `grafana-loki/`)
- **Grafana**: Multi-source data visualization dashboard
- **Loki**: Lightweight log aggregation system
- **Alloy**: Observability data collector (formerly Grafana Agent)
- Custom datasource configurations
- Pre-built dashboards and alerting rules
- Integration with Prometheus and Loki data sources

**Key Files**:
- `grafana-loki/grafana-loki.sh` - Installation script for Loki, Alloy, and Grafana
- `grafana-loki/alloy.yaml` - Alloy configuration for log collection
- `grafana-loki/loki-single.yaml` - Single-instance Loki configuration
- `grafana-loki/grafana-custom.yaml` - Grafana custom configuration

### 3. **Log Aggregation & Storage Solutions**

#### **MinIO + Fluent Bit** (`minio-fluent-bit/`)
- **Fluent Bit**: Lightweight log processor and shipper
- **MinIO**: S3-compatible object storage for logs
- HTTP input for receiving logs (port 9880)
- Record filtering to reduce log volume
- Integration with Loki for log shipping
- Configurable health checks and resource limits

**Features**:
- Removes unnecessary fields from logs
- Kubernetes label auto-discovery
- Service monitoring and health checks
- Configurable resource limits and requests

#### **MinIO + Elastic Stack** (`minio-elastic/`)
- **Elasticsearch**: Distributed search and analytics engine
- **Kibana**: Log analysis and visualization
- **Fluent Bit**: Log collection and forwarding
- LoadBalancer services for external access
- Credentials management via Kubernetes secrets

#### **MinIO + Parseable** (`minio-parseable/`)
- **Parseable**: Log storage and query system
- **MinIO**: S3 backend storage for logs
- API-driven log stream creation
- Webhook integration with MinIO audit logs
- RESTful API for log ingest and retrieval
- Basic authentication for security

**Features**:
- HTTP PUT/GET APIs for log management
- Support for MinIO audit webhook events
- Queue directory for failed deliveries
- Optional TLS configuration

#### **Prometheus Community** (`prometheus-community/`)
- Community-maintained Prometheus configurations
- Alternative deployment values
- Reference implementations

### 4. **Application Instrumentation**

#### **Podinfo** (`podinfo/`)
- Sample Go microservice with built-in observability
- Multiple endpoints for testing: `/healthz`, `/readyz`, `/status/*`, `/delay/*`
- Prometheus metrics exposure
- Includes CLI tool (`podcli`)
- Kubernetes deployment manifests (Kustomize)
- Docker image build configuration
- OpenTelemetry support via Docker Compose

**Components**:
- `cmd/podinfo/` - Main application
- `cmd/podcli/` - CLI utility
- `deploy/` - Kustomize and Helm deployment overlays
- `otel/` - OpenTelemetry integration
- `charts/podinfo/` - Helm chart

### 5. **Traffic Generation** (`generate-traffic.sh`)
- Load simulation script for testing monitoring stack
- Tests multiple endpoints on target service
- Real-time statistics collection
- Simulates various HTTP response codes and latencies
- Useful for validating metrics collection and alerting

### 6. **Meta Monitoring** (`meta/`)
- **Grafana Meta Monitoring**: Monitor the monitoring stack itself
- Observability of Prometheus, Grafana, and Loki
- MinIO integration for storage metrics
- Self-monitoring capabilities

**Installation**: `meta-install.sh`

### 7. **Prometheus + Grafana + Loki Integration** (`prometheus-grafana-loki/`)
- Combined deployment of Prometheus, Grafana, and Loki
- Alloy configuration for unified data collection
- Prometheus scrape configurations with MinIO integration
- Prometheus adapter for custom metrics
- Loki gateway with authentication
- Fluent Bit integration for log forwarding

**Key Files**:
- `alloy.yaml` - Alloy data collection configuration
- `loki-single.yaml` - Single-instance Loki setup
- `prometheus-adapter.yaml` - Prometheus adapter rules
- `prometheus-minio-scraps.yaml` - MinIO scrape configuration
- `fluent-bit-loki-values.yaml` - Fluent Bit values

## Key Features

- **Multi-Tenant Observability**: Prometheus metrics, Loki logs, and Grafana dashboards
- **Cloud-Native**: Fully containerized with Kubernetes integration
- **Scalable Storage**: MinIO provides S3-compatible object storage
- **Log Processing**: Fluent Bit for lightweight log collection and filtering
- **Alerting**: AlertManager with multi-channel routing
- **Visualization**: Grafana dashboards with multiple data source support
- **Monitoring the Monitor**: Meta-monitoring for stack health
- **Traffic Generation**: Built-in load testing capabilities
- **Sample Application**: Podinfo for testing and validation

## Deployment Workflows

### Basic Prometheus + Grafana + Loki Stack
```bash
./grafana-prom-loki.sh  # Deploys complete stack
```

### MinIO + Fluent Bit + Loki Integration
```bash
cd minio-fluent-bit
# Configure and deploy Fluent Bit with MinIO backend
```

### Parseable Log Storage
```bash
cd minio-parseable
# Deploy Parseable with MinIO S3 storage
```

### Meta Monitoring
```bash
cd meta
./meta-install.sh  # Monitor the monitoring stack
```

### Traffic Generation for Testing
```bash
./generate-traffic.sh http://podinfo-service:8080
```

## Architecture Highlights

- **Metrics Path**: Application → Prometheus → AlertManager → Grafana
- **Logs Path**: Application → Fluent Bit → Loki/Elasticsearch/Parseable → Grafana
- **Storage**: MinIO provides S3-compatible backend for multiple systems
- **Collection**: Alloy unifies metrics and logs collection
- **Visualization**: Grafana as central dashboard platform

## Configuration Files

- `values-kube-prometheus-stack.yaml` - Kube-prometheus-stack Helm values
- `custom_kube_prometheus_stack.yml` - Custom Prometheus configuration
- `debug-pod.yaml` - Debugging pod for troubleshooting
- `loki-microservice.yaml` - Loki microservice deployment
- `podinfo-servicemonitor.yaml` - ServiceMonitor for Podinfo application

## Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.0+
- kubectl configured to access cluster
- Sufficient storage for logs and metrics retention

## Getting Started

1. Review and customize Helm values for your environment
2. Deploy core monitoring stack: `./grafana-prom-loki.sh`
3. Deploy log aggregation solution of choice (Fluent Bit, Elastic, or Parseable)
4. Deploy sample application (Podinfo) for testing
5. Access Grafana and configure dashboards
6. Generate traffic for testing: `./generate-traffic.sh`
7. Configure alerts and notification channels in AlertManager

## Storage Backends

- **MinIO**: S3-compatible object storage (default for Fluent Bit, Parseable)
- **Elasticsearch**: Full-text search and analytics (EFK stack)
- **Loki**: Lightweight, horizontally scalable log aggregation
- **Prometheus**: Time-series database for metrics (TSDB)

## Observability Features

✅ Metrics collection (Prometheus)
✅ Log aggregation (Loki/Elasticsearch/Parseable)
✅ Visualization (Grafana)
✅ Alerting (AlertManager)
✅ Log processing (Fluent Bit)
✅ Data collection (Alloy)
✅ Stack monitoring (Meta Monitoring)
✅ Health checks & readiness probes
✅ Traffic simulation & testing

---

**Repository Structure**: Modular organization with separate namespaces and deployment directories for easy customization and isolation.