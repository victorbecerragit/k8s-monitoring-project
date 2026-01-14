

#Install only prometheus-operator and AlertManager.
#

helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack --namespace prometheus --values values.yaml


