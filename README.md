## Deploy Elasticsearch Cluster on Kubernetes using ES-Operator

### Step 1: Install Elasticsearch Operator

1. Install Custom Resource Definitions (CRDs):
```sh
kubectl create -f https://download.elastic.co/downloads/eck/2.16.0/crds.yaml
```
2. Install the Operator with RBAC Rules:
```sh
kubectl apply -f https://download.elastic.co/downloads/eck/2.16.0/operator.yaml
```

### Step 2: Deploy Elasticsearch Cluster

1. Create a Namespace for Elasticsearch:
```sh
kubectl create namespace elasticsearch
```
2. Deploy an Elasticsearch Cluster with One Node:
```sh
kubectl apply -f elasticsearch.yaml
```
3. Retrieve Credentials:
```sh
USER="elastic"
PASSWORD=$(kubectl get secret -n elasticsearch elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
echo $PASSWORD
```
4. Access Elasticsearch from Host and tunnel minikube 
```sh
kubectl apply -f externalsvc.yaml
minikube tunnel
```

## Configure Prometheus Alerts
### Step 1: Install Elasticsearch Exporter
* I used my existing Prometheus setup in the monitoring namespace.
* Install the Elasticsearch Exporter Helm chart and set the es.uri to point to the internal Elasticsearch service:

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install elasticexporter -n monitoring prometheus-community/prometheus-elasticsearch-exporter \
  --set es.uri="http://elastic:$PASSWORD@elasticsearch-es-http.elasticsearch.svc.cluster.local:9200"
```

### Step 2: Configure Prometheus to Scrape Elasticsearch Metrics

* Annotate the Elasticsearch Exporter service for Prometheus scraping:

```sh
kubectl annotate service elasticexporter-prometheus-elasticsearch-exporter -n monitoring \
  prometheus.io/scrape="true" prometheus.io/path="/metrics" prometheus.io/port="9108"
```
### Apply Elasticsearch Alerts

1. Apply Prometheus Alert Rules:
```sh
kubectl apply -f elasticsearch-alerts.yaml
```
2. Verify Prometheus Rules:
```sh
kubectl get prometheusrules -n monitoring
```
3. Add Alert Rules to Prometheus Configuration:
* Edit the Prometheus ConfigMap:
```sh
kubectl edit configmap prometheus-server -n monitoring
```
* Add the alerting_rules.yml section and include alert rules such as:
    * High CPU Usage Alerts
    * High Memory Usage Alerts
    * Cluster Health Alerts
    * Elasticsearch Health Alerts
Alternatively, you can apply the configuration:
```sh
kubectl apply -f alerting_rules.yaml
```

## Add Support for Service Mesh (Istio)
### Step 1: Install Istio
1. Download and Install Istio:
```sh
curl -L https://istio.io/downloadIstio | sh -
cd istio-<version>
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
```
2. Integrate Istio with Prometheus:
* Add the following scrape configuration to your Prometheus config (if you applied the configmap from alerting_rule.yaml it already present):

```sh
scrape_configs:
  - job_name: 'istio-mesh'
    honor_labels: true
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_pod_label_istio]
        action: keep
        regex: istio-system;.*
      - source_labels: [__meta_kubernetes_pod_container_port_name]
        action: keep
        regex: .*http-envoy-prom
```

### Step 2: Enable Istio Sidecar for Elasticsearch
1. Enable Sidecar Injection:
```sh
kubectl label namespace elasticsearch istio-injection=enabled --overwrite
```
2. Restart Elasticsearch StatefulSet:
```sh
kubectl rollout restart statefulset <elasticsearch-statefulset-name> -n elasticsearch
```

## Alerts Summary
### High CPU Usage Alert
* Rule: rate(container_cpu_usage_seconds_total[2m]) > 0.5
* Description: Triggers if a pod's CPU usage exceeds 50% for 2 minutes.

### High Memory Usage Alert
* Rule: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
* Description: Triggers if a pod uses more than 80% of its memory limit for 5 minutes.

### Cluster Health Alert
* Rule: kube_node_status_condition{condition="Ready", status="false"} == 1
* Description: Alerts when a node is in a NotReady state for more than 5 minutes.

### Elasticsearch Health Alert
* Rule: elasticsearch_cluster_health_status{status=~"yellow|red"}
* Description: Triggers if the Elasticsearch cluster health status is yellow or red.

![Elasticsearch](./img/alerts.png)

![ISTIO](./img/isto.png)

![Rules](./img/rules.png)
