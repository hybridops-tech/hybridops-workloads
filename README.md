# HybridOps Workloads

This repo holds workload Application definitions for HybridOps.
Argo CD installation and the root Application are created by a module/blueprint.
The root Application should point to `clusters/<target>`.

This repo is for Kubernetes clusters only. The edge plane runs as system services (Docker/systemd) and is managed by Ansible modules, not Argo CD.

Default policy: `standard@v1` (cost-aware baseline), enforced by the blueprint/profile layer.

Required edits before real use:
- Replace `REPLACE_GIT_REPO_URL` in Application specs that still use placeholders.
- Replace `REPLACE_CHART_REPO_URL` and chart versions for Helm apps.
- Update destination server if you are not using in-cluster Argo CD.

Validation:
- Draft validation (allows placeholders): `./scripts/validate.sh`
- Release validation (fails on placeholders): `./scripts/validate.sh --strict`
- Targeted validation: `./scripts/validate.sh --target <name>`

Layout:
- `clusters/<target>`: enabled apps for a Kubernetes cluster (`apps.yaml` + `kustomization.yaml`)
- `apps/<domain>/<app>`: Application definitions and values
- `docs`: architecture and policy references
- `scripts/validate.sh`: repo guard checks

## Rollout targets

- `clusters/onprem-smoke`
  - purpose: prove Argo CD and cluster plumbing with one minimal app
- `clusters/onprem-stage1`
  - purpose: first curated baseline (`smoke/guestbook`, `platform/velero`, `observability/loki`)
  - guide: `docs/onprem-stage1-rollout.md`
- `clusters/onprem`
  - purpose: full app catalog (requires additional placeholder resolution and integration)

RKE2 integration contract (recommended):
- `platform/onprem/rke2-cluster` should only provision and validate cluster infrastructure.
- Argo CD bootstrap should be a separate module/step that receives only:
  - workloads repo URL
  - revision
  - target path (for example `clusters/onprem`)
- Do not pass full workload app lists into the RKE2 module spec.
- Compose both in blueprint orchestration: `rke2-cluster -> argocd-bootstrap -> workloads sync`.

SME starter bundle:
- `docs/sme-starter-bundle.md`

Policy references:
- `docs/studio-ai-assistant.md`
- `docs/learn-platform-topology.md`
- `docs/learn-auth-entitlements-stage1.md`
- `docs/entitlements-api-stage1-contract.md`
- `docs/policy-centralization.md`
- `docs/policy-execution-architecture.md`
