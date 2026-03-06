# On-Prem Learn Stage 1 Tools

Purpose
- Prepare the existing dev RKE2 cluster for the low-cost hybrid Learn rollout.
- Keep PostgreSQL outside Kubernetes and support both GitOps and direct dev validation paths.

Files
- `render-artifacts.sh`
  - Generates DB SQL, Kubernetes Secret manifests, runtime payload Secrets for the app workloads, and a second Argo root `Application`.
  - Default external PostgreSQL host is `10.21.0.2`.
  - Also generates a shared Keycloak webhook HMAC secret for both `platform-keycloak-secrets` and `platform-entitlements-api-secrets`.
  - Optional: set `KEYCLOAK_THEME_JAR_PATH=/path/to/hybridops-theme.jar` to generate `20a-secret-keycloak-theme.yaml`.
- `apply-dev-direct.sh`
  - Dev-only fallback that applies the workloads directly with `kubectl` before the repo changes are pushed.
- `apply-dev-via-jump.sh`
  - Applies the same workload set through `hybridhub` when the workstation cannot reach the dev kube-apiserver directly.
- `apps/platform/cloudflared-tunnel`
  - Optional Cloudflare Tunnel workload for publishing the private RKE2 services without inbound NAT.
- `build-local-images.sh`
  - Optional fallback that builds the Learn SSR image and entitlements API image locally and exports them as tar files.
- `sideload-rke2-images.sh`
  - Optional fallback that imports those local images into all current RKE2 nodes.

Typical flow

```bash
cd hybridops-workloads
./tools/onprem-learn-stage1/render-artifacts.sh
```

Run the cluster-touching steps from a host that can reach:
- the external PostgreSQL endpoint (`10.21.0.2:5432` in the current dev state)
- the dev Kubernetes API via `~/.hybridops/envs/dev/state/kubeconfigs/rke2.yaml`
- the RKE2 node IPs if you use the local image sideload path

Then choose:

- GitOps path after pushing `hybridops-workloads`:
  - `kubectl apply -f /tmp/onprem-learn-stage1/30-argocd-root-application.yaml`

- Direct dev validation path before pushing:
  - `./tools/onprem-learn-stage1/apply-dev-direct.sh`
  - or `./tools/onprem-learn-stage1/apply-dev-via-jump.sh` from this workstation/jump-host topology

Default runtime model
- `academy/website` and `platform/entitlements-api` now run from public `node:22-*` base images plus generated runtime payload Secrets.
- This removes the private GHCR dependency for the current dev rollout.
- Public exposure for `auth.hybridops.tech`, `learn.hybridops.tech`, and `entitlements.hybridops.tech` should be done with Cloudflare Tunnel, not direct public A records to the private cluster IPs.

If you still want image-based delivery:

```bash
./tools/onprem-learn-stage1/build-local-images.sh
./tools/onprem-learn-stage1/sideload-rke2-images.sh
```
