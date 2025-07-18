#!/bin/bash
#

# Add helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

#install loki
helm install loki grafana/loki -n logging --create-namespace -f loki-single.yaml

#install alloy
helm install grafana-alloy grafana/alloy -n logging -f alloy.yaml

#install prometheus
helm upgrade --install -n monitoring prometheus prometheus-community/prometheus --create-namespace --values prometheus.yaml

#install grafana
helm upgrade --install grafana grafana/grafana -n monitoring --create-namespace -f grafana-custom.yaml

