# Fluent Bit Helm Values Configuration for MinIO Log Parsing

This document provides a complete Helm values configuration for deploying Fluent Bit as a standalone log processor to parse and forward MinIO logs. The configuration is extracted from Parseable's integration guide and tailored for MinIO log collection.

## Overview

Fluent Bit will be deployed as a **DaemonSet** to collect logs from MinIO pods/containers and forward them to your preferred destination (Parseable, Elasticsearch, Loki, or other HTTP-compatible endpoints).

## Complete Values YAML

```yaml
# Fluent Bit Helm Chart Values for MinIO Log Parsing
# Usage: helm install fluent-bit fluent/fluent-bit -f values.yaml

replicaCount: 1

image:
  repository: fluent/fluent-bit
  pullPolicy: IfNotPresent
  tag: "2.1.8"  # Adjust to your preferred version

# ServiceAccount configuration
serviceAccount:
  create: true
  annotations: {}
  name: fluent-bit

# RBAC configuration
rbac:
  create: true

# Pod Security Policy
podSecurityPolicy:
  enabled: false  # Set to true if using PSP in your cluster

# Security Context
securityContext:
  runAsUser: 0
  runAsGroup: 0
  fsGroup: 0

# Resource limits
resources:
  limits:
    cpu: 200m
    memory: 200Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Affinity rules (optional)
affinity: {}

# Tolerations for node taints (optional)
tolerations: []

# Main Fluent Bit Configuration
config:
  # Service section - Global settings
  service: |
    [SERVICE]
        Daemon Off
        Flush 5
        Log_Level info
        Parsers_File /fluent-bit/etc/parsers.conf
        Parsers_File /fluent-bit/etc/conf/custom_parsers.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port 2020
        Health_Check On

  # Parsers section - Define custom parsers for MinIO logs
  parsers: |
    [PARSER]
        Name docker
        Format json
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
        Time_Keep On

    [PARSER]
        Name minio_json
        Format json
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
        Time_Keep On

    [PARSER]
        Name minio_text
        Format regex
        Regex ^(?<time>[^ ]+T[^ ]+) (?<level>\w+) \[(?<requestID>[^\]]+)\] (?<message>.*)$
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
        Time_Keep On

    [PARSER]
        Name syslog-rfc5424
        Format regex
        Regex ^\<(?<pri>[0-9]{1,5})\>1 (?<time>[^ ]+) (?<host>[^ ]+) (?<ident>[^ ]+) (?<pid>[-0-9]+) (?<msgid>[^ ]+) (?<extradata>(\[(.*)?\]|-)) (?<message>.+)$
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
        Time_Keep On

  # Custom parsers (optional)
  customParsers: |
    [MULTILINE_PARSER]
        Name multiline-minio
        Flush_ms 1000
        Rule "start_state" "/^[0-9]{4}-[0-9]{2}-[0-9]{2}T/" "cont"
        Rule "cont" "/^ /" "cont"

  # Input plugins - Define data sources
  inputs: |
    # MinIO container logs
    [INPUT]
        Name tail
        Alias minio_logs
        Path /var/log/containers/*minio*.log
        Parser docker
        Tag minio.*
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On
        Skip_Empty_Lines On
        Refresh_Interval 10
        DB /var/log/flb_minio.db
        DB.Locking true

    # Alternative: Direct MinIO application logs if available
    [INPUT]
        Name tail
        Alias minio_app_logs
        Path /minio/data/.minio.sys/log/minio.log
        Parser minio_text
        Tag minio.app
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On
        Skip_Empty_Lines On
        Refresh_Interval 10
        DB /var/log/flb_minio_app.db
        DB.Locking true

  # Filters - Process and enrich logs
  filters: |
    # Kubernetes metadata enrichment
    [FILTER]
        Name kubernetes
        Match minio.*
        Merge_Log On
        Keep_Log Off
        K8S-Logging.Parser On
        K8S-Logging.Exclude On
        Kube_URL https://kubernetes.default.svc:443
        Kube_CA_File /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File /var/run/secrets/kubernetes.io/serviceaccount/token
        Buffer_Size 0
        Labels On
        Annotations On

    # Parse JSON logs if MinIO outputs JSON format
    [FILTER]
        Name parser
        Match minio.*
        Key_Name log
        Parser minio_json
        Reserve_Data On
        Preserve_Key On

    # Add hostname to all logs
    [FILTER]
        Name record_modifier
        Match minio.*
        Record hostname ${HOSTNAME}
        Record cluster minio-cluster
        Record environment production

  # Output plugins - Define destinations
  outputs: |
    # Output to HTTP endpoint (Parseable)
    [OUTPUT]
        Name http
        Match minio.*
        Host parseable.parseable.svc.cluster.local
        Port 80
        URI /api/v1/ingest
        Format json
        Compress gzip
        Json_date_key timestamp
        Json_date_format iso8601
        http_User admin
        http_Passwd admin
        Header X-P-Stream minio_logs
        Buffer_Size false
        Retry_Limit 5
        net.retry_limit 5
        net.dns.mode TCP

    # Alternative: Output to Elasticsearch
    # [OUTPUT]
    #     Name es
    #     Match minio.*
    #     Host elasticsearch.logging.svc.cluster.local
    #     Port 9200
    #     Index minio-logs
    #     Type _doc
    #     Logstash_Format On
    #     Logstash_Prefix minio
    #     Retry_Limit 5

    # Alternative: Output to Loki
    # [OUTPUT]
    #     Name loki
    #     Match minio.*
    #     Host loki.logging.svc.cluster.local
    #     Port 3100
    #     Labels job=minio, instance=$HOSTNAME
    #     Auto_Kubernetes_Labels On
    #     Retry_Limit 5

    # Alternative: Output to stdout for testing/debugging
    # [OUTPUT]
    #     Name stdout
    #     Match minio.*
    #     Format json_lines

# DaemonSet configuration
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "2020"
  prometheus.io/path: "/api/v1/metrics/prometheus"

# Service configuration
service:
  type: ClusterIP
  port: 2020
  targetPort: 2020
  annotations: {}

# Service Monitor for Prometheus (if using Prometheus Operator)
serviceMonitor:
  enabled: false
  namespace: monitoring
  interval: 30s
  scrapeTimeout: 10s

# Additional environment variables
env: []
  # - name: FLUENT_BIT_LOG_LEVEL
  #   value: "debug"

# Additional volumes and volume mounts
volumeMounts: []
  # - name: minio-logs
  #   mountPath: /minio/data/.minio.sys/log

volumes: []
  # - name: minio-logs
  #   hostPath:
  #     path: /path/to/minio/logs
  #     type: Directory

# Pod Disruption Budget
podDisruptionBudget:
  enabled: false
  minAvailable: 1
  # maxUnavailable: 1

# Node selector for targeting specific nodes
nodeSelector: {}
  # node-role.kubernetes.io/worker: "true"

# Update strategy
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
```

## Key Configuration Sections Explained

### INPUT Plugins

**Tail Plugin for Container Logs:**
- `Path /var/log/containers/*minio*.log`: Watches for MinIO container logs
- `Parser docker`: Uses Docker JSON parser for container logs
- `Tag minio.*`: Tags all MinIO logs
- `Mem_Buf_Limit 5MB`: Buffer size before flushing
- `DB`: Maintains checkpoint to avoid reprocessing

**Tail Plugin for MinIO Application Logs:**
- Points to MinIO's internal log directory
- Uses `minio_text` parser for text-format logs
- Alternative source if container logs aren't available

### FILTER Plugins

**Kubernetes Filter:**
- Enriches logs with pod name, namespace, labels, annotations
- Merges multi-line logs into single structured entries
- Automatically extracts Kubernetes metadata

**Parser Filter:**
- Extracts structured fields from JSON logs
- Useful if MinIO outputs JSON format
- `Reserve_Data On`: Keeps original log alongside parsed data

**Record Modifier Filter:**
- Adds static metadata (hostname, cluster name, environment)
- Helps with log tracking and organization

### OUTPUT Plugins

**HTTP Output (Parseable):**
```yaml
[OUTPUT]
    Name http
    Match minio.*
    Host parseable.parseable.svc.cluster.local
    Port 80
    URI /api/v1/ingest
    Format json
    Compress gzip
    http_User admin
    http_Passwd admin
    Header X-P-Stream minio_logs
```

**Key parameters:**
- `Compress gzip`: Reduces bandwidth by 70-80%
- `Retry_Limit 5`: Automatic retries on failure
- `X-P-Stream`: Specifies target stream in Parseable

### Parsers Section

Defines how to parse raw log lines into structured data:

**minio_json Parser:**
- Parses JSON-formatted MinIO logs
- Extracts timestamp from `time` field
- Keeps original timestamp

**minio_text Parser:**
- Uses regex to parse text-format logs
- Example pattern: `2024-01-15T10:30:45.123Z INFO [requestID] message`

## Installation

### 1. Add Fluent Bit Helm Repository

```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
```

### 2. Create Namespace

```bash
kubectl create namespace fluent-bit
```

### 3. Install Fluent Bit

```bash
helm install fluent-bit fluent/fluent-bit \
  -n fluent-bit \
  -f values.yaml
```

### 4. Verify Installation

```bash
kubectl get pods -n fluent-bit
kubectl logs -n fluent-bit -l app.kubernetes.io/name=fluent-bit -f
```

## Customization Guide

### Change MinIO Log Path

If MinIO logs are in a different location:

```yaml
[INPUT]
    Name tail
    Path /custom/path/to/minio/logs/*.log
    ...
```

### Add Custom Fields to All Logs

```yaml
[FILTER]
    Name record_modifier
    Match minio.*
    Record service_name minio
    Record version 2.0.20
    Record datacenter us-east-1
```

### Filter Out Specific Log Levels

```yaml
[FILTER]
    Name grep
    Match minio.*
    Exclude log DEBUG
```

### Send to Multiple Destinations

Define multiple `[OUTPUT]` sections:

```yaml
[OUTPUT]
    Name http
    Match minio.*
    Host parseable.parseable.svc.cluster.local
    ...

[OUTPUT]
    Name loki
    Match minio.*
    Host loki.logging.svc.cluster.local
    ...
```

## Performance Tuning

### For High-Volume Logs

```yaml
config:
  service: |
    [SERVICE]
        Flush 1
        Daemon Off
        Workers 4
        HTTP_Server On
```

Increase memory limits:

```yaml
resources:
  limits:
    memory: 512Mi
  requests:
    memory: 256Mi
```

### For Low-Volume Logs

```yaml
config:
  service: |
    [SERVICE]
        Flush 10
        Daemon Off
```

## Troubleshooting

### Check Fluent Bit Metrics

Port-forward to metrics endpoint:

```bash
kubectl port-forward -n fluent-bit svc/fluent-bit 2020:2020
curl http://localhost:2020/api/v1/metrics/prometheus
```

### Enable Debug Logging

```yaml
config:
  service: |
    [SERVICE]
        Log_Level debug
```

### Verify Parser Configuration

```bash
kubectl exec -it -n fluent-bit pod/fluent-bit-xxx -- \
  fluent-bit -c /fluent-bit/etc/fluent-bit.conf --dry-run
```

## References

- [Fluent Bit Official Documentation](https://docs.fluentbit.io/)
- [Parseable Fluent Bit Integration](https://www.parseable.com/docs/datasource/log-agents/fluent-bit)
- [Fluent Bit Helm Chart Repository](https://github.com/fluent/helm-charts)
- [MinIO Observability Guide](https://docs.min.io/minio/baremetal/monitoring/minio-server-monitoring.html)
