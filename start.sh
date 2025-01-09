# Deploy Elasticsearch Cluster on Kubernetes using ES-Operator
kubectl create -f ./internet/yaml/crds.yaml
kubectl apply -f ./internet/yaml/operator.yaml 
kubectl create namespace elasticsearch
kubectl apply -f elasticsearch.yaml

USERELASTIC="elastic"
PASSWORD=$(kubectl get secret -n elasticsearch elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')

kubectl apply -f externalsvc.yaml

# Install Prometheus
helm install prometheus ./internet/helm/prometheus/prometheus \
  --namespace monitoring \
  --create-namespace \
  -f ./values-prometheus.yaml

# INSTALL elasticsearch exporter
helm install elasticexporter -n monitoring ./internet/helm/prometheus-elasticsearch-exporter/prometheus-elasticsearch-exporter \
  --set es.uri="http://$USERELASTIC:$PASSWORD@elasticsearch-es-http.elasticsearch.svc.cluster.local:9200"

kubectl annotate service elasticexporter-prometheus-elasticsearch-exporter -n monitoring \
  prometheus.io/scrape="true" prometheus.io/path="/metrics" prometheus.io/port="9108"

#install istio
mkdir ~/istio-install
cd ~/istio-install
curl -L https://istio.io/downloadIstio | sh -
tar -xzvf istio-*
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

# Enable Istio Sidecar for Elasticsearch
kubectl label namespace elasticsearch istio-injection=enabled --overwrite
kubectl rollout restart statefulset elasticsearch-es-orenes -n elasticsearch

