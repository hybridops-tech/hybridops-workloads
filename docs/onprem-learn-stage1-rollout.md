# On-Prem Learn Stage 1 Rollout

Purpose
- Deploy the cost-effective Stage 1 Learn stack on the existing hybrid Cloudflare + RKE2 setup.
- Keep the current baseline target (`onprem-stage1`) intact while you validate Keycloak, entitlements, and the Learn SSR app behind Cloudflare-hosted public/docs surfaces.
- For public cutover, use Cloudflare Tunnel for the runtime services because the current RKE2 ingress addresses are private.

Target contents
- `platform/keycloak`
- `platform/entitlements-api`
- `academy/website`

Required secrets
- `platform-keycloak-secrets` in namespace `keycloak`
  - `KC_DB_URL`
  - `KC_DB_USERNAME`
  - `KC_DB_PASSWORD`
  - `KEYCLOAK_ADMIN`
  - `KEYCLOAK_ADMIN_PASSWORD`
  - `KEYCLOAK_EVENTS_SHARED_SECRET`
  - `KEYCLOAK_LOGIN_THEME`
- `platform-entitlements-api-secrets` in namespace `entitlements`
  - `DATABASE_HOST`
  - `DATABASE_USER`
  - `DATABASE_PASSWORD`
  - `INTERNAL_API_TOKEN`
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
  - `KEYCLOAK_EVENTS_SHARED_SECRET`
- `academy-website-secrets` in namespace `academy`
  - `LEARN_SESSION_SECRET`
  - `ENTITLEMENTS_API_TOKEN`
- `platform-entitlements-api-runtime` in namespace `entitlements`
  - generated runtime payload Secret for the API source bundle
- `academy-website-runtime` in namespace `academy`
  - generated runtime payload Secret for the built Astro SSR bundle plus runtime package metadata

Notes
- Apply all SQL migrations in `hybridops-docs/control/backend/entitlements-api/sql/*.sql` to the external entitlements database before enabling traffic.
- Public/docs/member static surfaces are expected to run on Cloudflare.
- `learn.hybridops.tech` remains in-cluster for Stage 1 because the current Astro app already uses SSR routes and middleware.
- Wrangler-backed Cloudflare Worker routes remain the preferred path for HyOps Copilot and other edge logic.
- Keycloak and the entitlements API both assume external PostgreSQL backing services.
- The current dev rollout avoids private GHCR dependencies by running `academy/website` and `platform/entitlements-api` from public `node:22-*` images plus generated runtime payload Secrets.
- The current dev rollout does not yet include `platform/cloudflared-tunnel`; add that only after you have the real tunnel token.
- The child Argo `Application` manifests currently use `targetRevision: main`; cut a workload tag/commit and pin those revisions before treating this target as release-grade.
- If you later move `learn.hybridops.tech` to Cloudflare Workers/Pages Functions, remove `academy/website` from this target after the edge auth/session path is proven.

Bootstrap example

```bash
HYOPS_INPUT_root_app_name=hyops-onprem-learn-stage1 \
HYOPS_INPUT_workloads_repo_url=https://github.com/hybridops-tech/hybridops-workloads.git \
HYOPS_INPUT_workloads_revision=<tag-or-commit> \
HYOPS_INPUT_workloads_target_path=clusters/onprem-learn-stage1 \
HYOPS_INPUT_root_destination_namespace=argocd \
./.venv/bin/hyops --verbose apply --env dev \
  --module platform/k8s/argocd-bootstrap \
  --inputs modules/platform/k8s/argocd-bootstrap/examples/inputs.typical.yml
```

Validation

```bash
./scripts/validate.sh --strict --target onprem-learn-stage1
```

Bootstrap helpers

```bash
./tools/onprem-learn-stage1/render-artifacts.sh
```

- Run the apply/sideload steps from a host that has L3 reachability to the external PostgreSQL endpoint, the dev kube-apiserver, and the RKE2 node IPs.
- On this workstation, use `./tools/onprem-learn-stage1/apply-dev-via-jump.sh` because direct kube-apiserver reachability is not available.
- Use the generated Argo root `Application` after pushing the workload repo revision that contains this target.
- Use `./tools/onprem-learn-stage1/apply-dev-direct.sh` only for pre-push dev validation when you need to test against the running cluster immediately.
- See `hybridops-workloads/docs/onprem-learn-stage1-cutover-checklist.md` for the domain, Cloudflare, tunnel, and final public cutover sequence.
