# HybridOps Workloads

Kubernetes workload catalog for HybridOps GitOps deployments.

This repository is consumed by Argo CD. HybridOps installs Argo CD and points a root
Application to one of the cluster targets in `clusters/<target>`.

## How end users consume this repo

Use the Argo CD bootstrap module with a **Git URL**, **versioned revision** (tag or
commit), and a **target path**.

Example:

```bash
HYOPS_INPUT_root_app_name=hyops-onprem-stage1 \
HYOPS_INPUT_workloads_repo_url=https://github.com/hybridops-tech/hybridops-workloads.git \
HYOPS_INPUT_workloads_revision=<tag-or-commit> \
HYOPS_INPUT_workloads_target_path=clusters/onprem-stage1 \
HYOPS_INPUT_root_destination_namespace=argocd \
./.venv/bin/hyops --verbose apply --env dev \
  --module platform/k8s/argocd-bootstrap \
  --inputs modules/platform/k8s/argocd-bootstrap/examples/inputs.typical.yml
```

Notes:
- Prefer tags/commits over `main` for reproducibility.
- This repo targets Kubernetes workloads only.
- Cloudflare-hosted edge surfaces stay outside Argo CD, but in-cluster edge components such as `cloudflared` can be managed here as Kubernetes workloads.

## Target maturity

- `clusters/onprem-smoke`
  - Status: ready
  - Purpose: prove Argo CD + cluster plumbing with one minimal app
- `clusters/onprem-stage1`
  - Status: bootstrap-ready after Stage 1 substitutions
  - Purpose: first curated baseline (`smoke/guestbook`, `platform/velero`, `observability/loki`)
  - Guide: `docs/onprem-stage1-rollout.md`
- `clusters/onprem-learn-stage1`
  - Status: ready for Learn auth + hosting integration
  - Purpose: focused hybrid rollout (`platform/keycloak`, `platform/entitlements-api`, `academy/website`) with Cloudflare-hosted public/docs surfaces and in-cluster Learn SSR
  - Guide: `docs/onprem-learn-stage1-rollout.md`
- `clusters/onprem-ci-stage1`
  - Status: optional bootstrap target once a GitLab runner token exists
  - Purpose: GitLab runner manager on RKE2 while keeping GitLab itself on GitLab.com
  - Guide: `docs/onprem-ci-stage1-rollout.md`
- `clusters/onprem`
  - Status: integration in progress
  - Purpose: full app catalog (requires additional substitutions/integration)

## Validation

- Draft validation (allows unresolved placeholders):

```bash
./scripts/validate.sh
```

- Targeted validation:

```bash
./scripts/validate.sh --target onprem-stage1
```

- Strict validation (target-scoped release gate):

```bash
./scripts/validate.sh --strict --target onprem-stage1
```

```bash
./scripts/validate.sh --strict --target onprem-learn-stage1
```

```bash
./scripts/validate.sh --strict --target onprem-ci-stage1
```

## Fast path for Stage 1 placeholders

```bash
./scripts/fill-onprem-stage1.sh \
  --repo-url https://github.com/hybridops-tech/hybridops-workloads.git \
  --git-revision <WORKLOADS_GIT_TAG_OR_SHA> \
  --velero-version <VELERO_CHART_VERSION> \
  --loki-version <LOKI_CHART_VERSION>
```

## Repository layout

- `clusters/<target>`: enabled apps per cluster target (`apps.yaml` + `kustomization.yaml`)
- `apps/<domain>/<app>`: Argo CD Application definitions and values
- `docs/`: rollout and policy references
- `scripts/validate.sh`: workload hygiene checks

## References

- `CATALOG.md`
- `docs/environments.md`
- `docs/argocd-model.md`
- `docs/onprem-stage1-rollout.md`
- `docs/onprem-learn-stage1-rollout.md`
- `docs/onprem-ci-stage1-rollout.md`
