# Burst Target Rollout

This guide defines the published burst baseline for HybridOps Kubernetes workloads.

## Target

- `clusters/burst`

## Scope

The published burst baseline is intentionally narrow:

- validate GitOps reconciliation into a secondary cluster
- keep the initial burst payload stateless
- establish cloud secret projection without relying on a static service account key inside the cluster
- avoid coupling the burst baseline to unfinished chart-pinning or storage contracts

## Current burst app set

1. `platform/external-secrets`
2. `smoke/guestbook`

## Why this set

- `platform/external-secrets` establishes the operator required for cloud-native secret projection on GKE.
- `smoke/guestbook` validates Argo CD, namespace creation, sync, and rollback with a minimal workload.

## Not included yet

The first burst target does not yet include:

- `platform/secret-stores`
- `observability/kube-prometheus-stack`
- `observability/thanos-compactor`
- `studio/docsgpt`

Those are follow-on promotions once the target cluster and endpoint contracts are fully pinned. `platform/secret-stores` remains outside the published burst GitOps set for now because the cluster-specific GKE Secret Manager store is bootstrapped by HybridOps core with Workload Identity, not by a static-key manifest.
