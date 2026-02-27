# Observability Apps

Current apps:
- kube-prometheus-stack
- loki
- thanos-compactor

Notes:
- Prometheus runs in each Kubernetes cluster and remote_write sends to edge Thanos Receive.
- Thanos Receive/Query/Store, Grafana, Alertmanager, and Ruler run on the edge as system services (not managed by Argo CD).
- Loki runs in-cluster for log aggregation and is intended to be queried from Grafana.
