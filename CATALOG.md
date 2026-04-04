# Workload Catalog

## Cluster rollout targets

- `clusters/onprem-smoke` (minimal Argo CD and cluster validation target)
- `clusters/onprem-stage1` (curated on-prem baseline: guestbook + velero + loki)
- `clusters/onprem` (broader reusable on-prem application catalog)
- `clusters/burst` (stateless secondary-cluster baseline: external-secrets + guestbook)

## App catalog

- platform/external-secrets (ready)
- platform/secret-stores (ready)
- platform/velero (draft)
- platform/gitlab-runner (draft)
- observability/kube-prometheus-stack (draft)
- observability/loki (draft)
- observability/thanos-compactor (draft)
- business/nextcloud (draft)
- business/zammad (draft)
- studio/docsgpt (draft)
