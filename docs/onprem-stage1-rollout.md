# On-Prem Stage 1 Rollout

This guide defines a practical progression from smoke-only validation to an initial
operational baseline for on-prem clusters.

## Stage targets

- `clusters/onprem-smoke`: single app smoke proof (`smoke/guestbook`)
- `clusters/onprem-stage1`: first curated baseline (guestbook + velero + loki)
- `clusters/onprem`: full catalog target (requires additional integration work)

## Stage 1 app order

Apply in this order to reduce blast radius:

1. `smoke/guestbook`
2. `platform/velero`
3. `observability/loki`

## Required substitutions (Stage 1)

### 1) `smoke/guestbook`

No placeholder substitutions required.

### 2) `platform/velero`

File: `apps/platform/velero/base/application.yaml`

- `REPLACE_CHART_REPO_URL`
- `REPLACE_CHART_VERSION`
- `REPLACE_GIT_REPO_URL`

Recommended chart source baseline:

- repo: `https://vmware-tanzu.github.io/helm-charts`
- chart: `velero`
- version: pin a validated release in your environment

### 3) `observability/loki`

File: `apps/observability/loki/base/application.yaml`

- `REPLACE_CHART_REPO_URL`
- `REPLACE_CHART_VERSION`
- `REPLACE_GIT_REPO_URL`

Recommended chart source baseline:

- repo: `https://grafana.github.io/helm-charts`
- chart: `loki`
- version: pin a validated release in your environment

## Validation commands

Draft validation (allows unresolved placeholders outside your target):

```bash
./scripts/validate.sh --target onprem-stage1
```

Strict validation (fails on unresolved placeholders in `apps/` and `clusters/`):

```bash
./scripts/validate.sh --strict --target onprem-stage1
```

## Promotion rule

Promote `onprem-stage1` to the default on-prem path only after:

- all Stage 1 placeholders are replaced
- Argo CD Applications report `Synced` and `Healthy`
- evidence for backup/restore and failure recovery is captured
