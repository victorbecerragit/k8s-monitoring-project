# Create namespace
kubectl create ns minio-storage

# Create MinIO tenant for Parseable logs storage
kubectl minio tenant create parseable-storage \
  --servers=1 \
  --volumes=4 \
  --capacity=10Gi \
  --disable-tls \
  -n minio-storage

# Get credentials (save these)
kubectl minio tenant info parseable-storage -n minio-storage


# Create the parseable bucket through the MinIO console or using the MC CLI
# Port forward to MinIO console
kubectl port-forward svc/parseable-storage-console 9090:9090 -n minio-storage

# Or use MC to create the bucket
mc alias set parseable-storage http://parseable-storage-minio.minio-storage.svc.cluster.local <ACCESS_KEY> <SECRET_KEY>
mc mb parseable-storage/parseable

cat << 'EOF' > parseable-env-secret
s3.url=http://parseable-storage-minio.minio-storage.svc.cluster.local:9000
s3.access.key=<ACCESS_KEY_FROM_STEP_1>
s3.secret.key=<SECRET_KEY_FROM_STEP_1>
s3.region=us-east-1
s3.bucket=parseable
addr=0.0.0.0:8000
staging.dir=./staging
fs.dir=./data
username=admin
password=admin
EOF

# Create namespace and secret
kubectl create ns parseable
kubectl create secret generic parseable-env-secret \
  --from-env-file=parseable-env-secret \
  -n parseable

rm parseable-env-secret


# Add Parseable Helm repository
helm repo add parseable https://charts.parseable.io
helm repo update

# Deploy Parseable
helm install parseable parseable/parseable \
  -n parseable \
  -f - <<'EOF'
# Parseable will load credentials from the secret we created
# No additional values needed for basic setup
EOF

kubectl get pods -n parseable
kubectl port-forward svc/parseable 8000:80 -n parseable

# Access Parseable at http://localhost:8000 with credentials admin:admin


# Create a log stream named 'minio-audit'
curl -X PUT \
  http://localhost:8000/api/v1/logstream/minio-audit \
  -H "Authorization: Basic YWRtaW46YWRtaW4=" \
  -H "Content-Type: application/json"

# Verify the stream was created
curl -X GET \
  http://localhost:8000/api/v1/logstream \
  -H "Authorization: Basic YWRtaW46YWRtaW4="


# Update minio-tenant config to point to Parseable
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: myminio
  namespace: minio-tenant
spec:
  # ... other tenant configuration ...
  
  env:
    # Enable audit webhook
    - name: MINIO_AUDIT_WEBHOOK_ENABLE_parseable
      value: "on"
    
    # Parseable HTTP ingest endpoint
    - name: MINIO_AUDIT_WEBHOOK_ENDPOINT_parseable
      value: "http://parseable.parseable.svc.cluster.local:8000/api/v1/logstream/minio-audit"
    
    # Optional: Add basic auth token
    - name: MINIO_AUDIT_WEBHOOK_AUTH_TOKEN_parseable
      value: "Basic YWRtaW46YWRtaW4="
    
    # Optional: Queue directory for failed deliveries
    - name: MINIO_AUDIT_WEBHOOK_QUEUE_DIR_parseable
      value: "/tmp/audit-webhook"

# Query Parseable to see if logs are being received
curl -X POST \
  http://localhost:8000/api/v1/query \
  -H "Authorization: Basic YWRtaW46YWRtaW4=" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "select * from minio-audit limit 10",
    "startTime": "2025-11-04T00:00:00Z",
    "endTime": "2025-11-04T23:59:59Z"
  }'

