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

## Why this set

- `smoke/guestbook` proves Argo CD, namespace creation, sync, and rollback with a minimal app.

## Not included yet

The first burst target does not yet include:

- `academy/website`
- `observability/kube-prometheus-stack`
- `observability/thanos-compactor`
- `studio/docsgpt`

Those are follow-on promotions once the target cluster and endpoint contracts are fully pinned. `academy/website` in particular still depends on a generated runtime payload secret and platform secret inputs that are not yet part of the first public burst baseline.
