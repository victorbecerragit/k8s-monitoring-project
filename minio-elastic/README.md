helm repo add elastic https://helm.elastic.co

helm repo update


helm install elasticsearch  \
        --set service.type=LoadBalancer \
        --set persistence.labels.enabled=true elastic/elasticsearch -n efk


kubectl get secrets --namespace=efk elasticsearch-master-credentials -ojsonpath='{.data.username}' | base64 -d


kubectl get secrets --namespace=efk elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d


helm install kibana --set service.type=LoadBalancer elastic/kibana -n efk

helm repo add fluent https://fluent.github.io/helm-charts

helm install fluent-bit fluent/fluent-bit -f fluent-Bit-values.yaml -n efk


