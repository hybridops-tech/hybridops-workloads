# Targets

Targets define Kubernetes topology and rollout maturity.

## Cluster targets

- `onprem-smoke` (minimal smoke proof)
- `onprem-stage1` (curated baseline)
- `onprem` (full catalog)
- `burst` (GKE/AKS when provisioned)

Paths:

- `clusters/onprem-smoke`
- `clusters/onprem-stage1`
- `clusters/onprem`
- `clusters/burst` (optional)

Profiles (`standard@v1`, `enterprise@v1`) are enforced by blueprint/profile
layers and are not encoded in workload paths.

Notes:

- Edge services are deployment-specific and are not implied by this repo alone.
- The first public burst target is intentionally stateless: `smoke/guestbook` plus `academy/website`.
- Remote-write, object-store, and broader platform app promotion can be layered onto burst after the target cluster contract is stable.
