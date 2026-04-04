# Deployment Targets

Targets define the published deployment paths for the HybridOps workload catalog.

## Cluster targets

- `onprem-smoke` (minimal validation target)
- `onprem-stage1` (curated baseline)
- `onprem` (broader reusable catalog)
- `burst` (stateless secondary-cluster baseline)

Published paths:

- `clusters/onprem-smoke`
- `clusters/onprem-stage1`
- `clusters/onprem`
- `clusters/burst` (optional)

Profiles (`standard@v1`, `enterprise@v1`) are enforced by blueprint/profile
layers and are not encoded in workload paths.

Notes:

- Edge services are deployment-specific and are not implied by this repo alone.
- The first public burst target is intentionally stateless: `platform/external-secrets` plus `smoke/guestbook`.
- Remote-write, object-store, and broader platform app promotion can be layered onto burst after the target cluster contract is stable.
