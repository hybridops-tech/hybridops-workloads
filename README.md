# HybridOps Workloads

Kubernetes workload catalog for HybridOps GitOps deployments.

This repository is intended to be consumed directly by Argo CD bootstrap through
the `hybridops-core` `argocd-bootstrap` module.

## How end users consume this repo

Pass a Git URL, versioned revision, and public target path.

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
- Prefer tags or commits over `main` for reproducibility.
- This repo covers Kubernetes workloads only.
- Edge hosting choices outside Kubernetes remain deployment-specific.

## Public targets

- `clusters/onprem-smoke`
  - Status: minimal smoke proof
- `clusters/onprem-stage1`
  - Status: curated baseline
  - Guide: `docs/onprem-stage1-rollout.md`
- `clusters/onprem`
  - Status: broader catalog target with additional substitutions still expected
- `clusters/burst`
  - Status: first stateless burst target
  - Guide: `docs/burst-rollout.md`

## Validation

```bash
./scripts/validate.sh --strict --target onprem-stage1
```

```bash
./scripts/validate.sh --target onprem
```

## Repository layout

- `clusters/<target>`: public enabled apps per cluster target
- `apps/<domain>/<app>`: Argo CD Application definitions and values
- `docs/`: public workload/operator references
- `scripts/validate.sh`: workload hygiene checks
- `tools/`: public helper tooling

## References

- `STANDARD.md`
- `CATALOG.md`
- `docs/environments.md`
- `docs/argocd-model.md`
