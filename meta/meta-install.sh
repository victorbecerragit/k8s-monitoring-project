#!/bin/bash
#

kubectl create secret generic minio -n monitoring \
 --from-literal=rootUser=minio \
 --from-literal=rootPassword=prom-minio

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install --create-namespace meta grafana/meta-monitoring --namespace monitoring --values values.yaml

