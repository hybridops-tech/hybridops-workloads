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

## Fast path: fill placeholders with one command

Use the Stage 1 helper script:

```bash
./scripts/fill-onprem-stage1.sh \
  --repo-url https://github.com/hybridops-tech/hybridops-workloads.git \
  --git-revision <WORKLOADS_GIT_TAG_OR_SHA> \
  --velero-version <VELERO_CHART_VERSION> \
  --loki-version <LOKI_CHART_VERSION>
```

This updates Stage 1 placeholders and runs strict target validation.

## Validation commands

Draft validation (allows unresolved placeholders outside your target):

```bash
./scripts/validate.sh --target onprem-stage1
```

Strict validation (target-scoped release gate):

```bash
./scripts/validate.sh --strict --target onprem-stage1
```

## Promotion rule

Promote `onprem-stage1` to the default on-prem path only after:

- all Stage 1 placeholders are replaced
- Argo CD Applications report `Synced` and `Healthy`
- evidence for backup/restore and failure recovery is captured

## Troubleshooting

Use an explicit kubeconfig path (not `KUBEC`):

```bash
KUBECONFIG="$HOME/.hybridops/envs/dev/state/kubeconfigs/rke2.yaml" kubectl -n argocd get applications
```

Common Stage 1 issues:

- `platform-velero` `Init:ErrImagePull` on `upgrade-crds`: keep `upgradeCRDs: false` in
  `apps/platform/velero/overlays/onprem/values.yaml`.
- `platform-velero` invalid `BackupStorageLocation`/`VolumeSnapshotLocation`: for Stage 1,
  keep `backupsEnabled: false` and `snapshotsEnabled: false` until cloud/object-store inputs
  are configured.
- `observability-loki` rendered but no pods: ensure on-prem values use a valid storage/deployment
  profile (single-binary + filesystem in
  `apps/observability/loki/overlays/onprem/values.yaml`).
- `observability-loki` crash with `compactor.delete-request-store`: disable retention for Stage 1
  (`loki.compactor.retention_enabled: false`) unless full object-store retention config is in place.
- `observability-loki` crash with `mkdir /var/loki` permission errors: set Stage 1
  path/storage directories to `/tmp/loki/*` in on-prem overlay values.
