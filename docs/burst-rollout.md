# Burst Target Rollout

This guide defines the first public burst target for HybridOps Kubernetes workloads.

## Target

- `clusters/burst`

## Purpose

The first public burst target is intentionally narrow:

- prove GitOps reconciliation into a secondary cluster
- keep the initial burst payload stateless
- avoid coupling the burst baseline to unfinished chart-pinning or storage contracts

## Current burst app set

1. `smoke/guestbook`
2. `academy/website`

## Why this set

- `smoke/guestbook` proves Argo CD, namespace creation, sync, and rollback with a minimal app.
- `academy/website` proves a real stateless application can be re-established in a burst cluster without placing authoritative state inside Kubernetes.

## Not included yet

The first burst target does not yet include:

- `observability/kube-prometheus-stack`
- `observability/thanos-compactor`
- `studio/docsgpt`

Those are follow-on promotions once the target cluster and endpoint contracts are fully pinned.
