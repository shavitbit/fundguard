
## Prerequisites
 - minikube
 - trriger the command minikube tunnel

## Installation
The start.sh script will install anything you need for this project:

1. Install Elasticsearch Operator with RBAC Rules
2. Deploy Elasticsearch Cluster one node
3. Install Prometheus
4. Configure Prometheus Alerts with value-prometheus.yaml
5. Install elasticsearch exporter
6. Install istio
7. Enable Istio Sidecar for Elasticsearch

## Namespace:
- elasticsearch
- monitoring
- istio-system

### helm used:
./internet/helm/prometheus <br />
./internet/helm/prometheus-elasticsearch-exporter<br />

### elastic-operator crd:
./internet/yaml/crd.yaml <br/>
./internet/yaml/operator.yaml <br />


## Alerts:
alerts are part of the values-prometheus.yaml <br/>
- Elastic_up 
- Elastic_Cluster_Health_Red 
- Elastic_Cluster_Health_Red 
- Elasticsearch_JVM_Heap_Too_High 
- Elasticsearch_health_up
- Elasticsearch_Too_Few_Nodes_Running
- Elasticsearch_Count_of_JVM_GC_Runs
- Elasticsearch_GC_Run_Time
- Elasticsearch_json_parse_failures
- Elasticsearch_breakers_tripped
- Elasticsearch_health_timed_out