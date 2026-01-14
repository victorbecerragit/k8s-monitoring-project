# Create a dedicated namespace
kubectl create namespace fluent-bit

# Verify namespace creation
kubectl get ns fluent-bit


cat > fluent-bit-values.yaml << 'EOF'
# Global service configuration for Fluent Bit
config:
  # SERVICE section - controls Fluent Bit's HTTP server and global settings
  service: |
    [SERVICE]
        Daemon Off
        Flush 1
        Log_Level info
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port 2020
        Health_Check On
        HC_Errors_Count 5
        HC_Retry_Failure_Count 5
        HC_Period 60

  # INPUT section - receives MinIO audit logs via HTTP on port 9880
  inputs: |
    [INPUT]
        Name http
        Listen 0.0.0.0
        Port 9880
        Tag minio-audit
        Buffer_Max_Size 4M

  # FILTER section - removes unnecessary fields to reduce log volume
  filters: |
    [FILTER]
        Name record_modifier
        Match minio-audit
        # Remove fields that shouldn't be sent to Loki
        Remove_key tags
        Remove_key partition
        Remove_key remoteHost
        Remove_key topic
        Remove_key trigger
        Remove_key version

  # OUTPUT section - forwards transformed logs to Loki
  outputs: |
    [OUTPUT]
        Name loki
        Match minio-audit
        Host loki-gateway.logging.svc.cluster.local
        Port 3100
        Http_User admin
        Http_Passwd admin
        Labels job=minio-audit
        Auto_Kubernetes_Labels on

# Service port for metrics (HTTP server endpoint on port 2020)
servicePort: 2020

# Container ports - defines ports on the pod itself
containerPorts:
  - name: http
    containerPort: 2020
    protocol: TCP
  - name: http-input
    containerPort: 9880
    protocol: TCP

# Liveness probe - checks if Fluent Bit is healthy
livenessProbe:
  httpGet:
    path: /api/v1/health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

# Readiness probe - checks if Fluent Bit is ready to receive traffic
readinessProbe:
  httpGet:
    path: /api/v1/health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

# Resource limits and requests
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi

# Pod security policy (disable for Kubernetes 1.25+)
podSecurityPolicy:
  enabled: false
EOF


cat > fluent-bit-http-input-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: fluent-bit-http-input
  namespace: fluent-bit
  labels:
    app.kubernetes.io/name: fluent-bit
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: fluent-bit
  ports:
    - name: http-input
      port: 9880
      targetPort: 9880
      protocol: TCP
EOF

# Install the chart
helm install fluent-bit fluent/fluent-bit \
  -f fluent-bit-values.yaml \
  -n fluent-bit

# Watch the deployment
kubectl get pods -n fluent-bit -w


