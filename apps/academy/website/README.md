# Academy Website

Purpose
- Serves the Academy learning portal as an Astro Node.js SSR application.

Runtime contract
- Namespace: `academy`
- Service: `academy-website`
- Ingress host: overlay-defined
- Runtime model: public `node:22-slim` base image plus `academy-website-runtime` synced by `platform/k8s/runtime-bundle-secret`

Required secret
- `academy-website-secrets`
  - projected by `ExternalSecret` from `gcp-secret-manager` (see your cluster overlay)
  - `LEARN_SESSION_SECRET`
  - `ENTITLEMENTS_API_TOKEN`
  - `STRIPE_SECRET_KEY`
- `academy-website-runtime`
  - runtime bundle containing `dist/`, `package.json`, and `package-lock.json`
  - normative sync path: `platform/k8s/runtime-bundle-secret`

On-prem secret source
- For long-lived application credentials, the normative path is:
  - runtime vault
  - GCP Secret Manager
  - `ExternalSecret`
- Treat hand-applied long-lived copies of `academy-website-secrets` as break-glass only.

Non-secret config
- `academy-website-env` ConfigMap is generated from manifests and sets:
  - `LEARN_AUTH_MODE=keycloak`
  - `LEARN_AUTH_PUBLIC_BASE_URL` (set by overlay)
  - `LEARN_KEYCLOAK_ISSUER_URL` (set by overlay)
  - `ENTITLEMENTS_API_URL=http://platform-entitlements-api.entitlements.svc.cluster.local:8080`
  - optional `ACADEMY_LMS_BASE_URL`
  - optional `DOCS_PAID_URL` for a separate paid-docs / academy-docs host
  - `STRIPE_PRICE_ID` (preferred for subscription checkout)
  - optional plan-specific overrides:
    - `STRIPE_PRICE_ID_NETWORKING`
    - `STRIPE_PRICE_ID_AUTOMATION`
    - `STRIPE_PRICE_ID_DOCS_MONTHLY`
    - `STRIPE_PRICE_ID_DOCS_YEARLY`
    - `STRIPE_PRICE_ID_BOOTCAMP_CCNA_INTENSIVE`
    - `STRIPE_PRICE_ID_BOOTCAMP_MULTI_WAN`
    - `STRIPE_PRICE_ID_BOOTCAMP_DEVNET_ACCELERATED`
  - optional sandbox fallback when `STRIPE_PRICE_ID` is empty:
    - `STRIPE_SANDBOX_CURRENCY`
    - `STRIPE_SANDBOX_AMOUNT_CENTS`
    - `STRIPE_SANDBOX_INTERVAL`
    - `STRIPE_SANDBOX_PRODUCT_NAME`

Notes
- The app serves the full Astro site bundle, but this workload is intended for the Learn surface.
- Keep the product/docs static surfaces outside the cluster unless you explicitly choose otherwise.
- This app is typically composed into a Learn integration target when SSR routes and middleware are required.
- Current overlays cover `onprem`, `edge-hetzner`, and the first stateless `burst` target.
- The burst overlay switches the ingress class and carries a hostless fallback so a front-door proxy can reach the service without a matching `Host` header at the load balancer.
- If you use a private runtime renderer or secret-generation flow, keep that helper outside the public workload contract.
