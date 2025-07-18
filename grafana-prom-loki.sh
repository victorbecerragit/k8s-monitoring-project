#!/bin/bash

# Create namespace
kubectl create namespace monitoring || true

# Add helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki stack (loki + promtail)
#helm install loki grafana/loki-stack \
#  --namespace monitoring \
#  --set loki.enabled=true,promtail.enabled=true

#helm upgrade --install loki --namespace=monitoring --values loki-grafana-values.yaml grafana/loki-stack


# Install kube-prometheus-stack with Prometheus, Alertmanager , Grafana, loki
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --values values-kube-prometheus-stack.yaml
