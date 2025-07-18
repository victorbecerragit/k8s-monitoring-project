#!/bin/bash
#

# Add helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

#install loki
helm install loki grafana/loki -n loki --create-namespace -f loki-single.yaml

#install alloy
helm install grafana-alloy grafana/alloy -n loki -f alloy.yaml

#install grafana
helm install grafana grafana/grafana -n monitoring --create-namespace -f grafana-custom.yaml

