# Academy Website

Purpose
- Host the Learn portal inside the existing RKE2 cluster.
- Serve the Astro Node SSR build from `hybridops-docs/hybridops.tech`.

Runtime contract
- Namespace: `academy`
- Service: `academy-website`
- Ingress host: overlay-defined
- Runtime model: public `node:22-slim` base image plus generated `academy-website-runtime` Secret payload

Required secret
- `academy-website-secrets`
  - `LEARN_SESSION_SECRET`
  - `ENTITLEMENTS_API_TOKEN`
  - optional `DOCS_PAID_URL` for a separate paid-docs / academy-docs host
  - `STRIPE_SECRET_KEY`
  - `STRIPE_PRICE_ID` (preferred for subscription checkout)
  - optional plan-specific overrides:
    - `STRIPE_PRICE_ID_NETWORKING`
    - `STRIPE_PRICE_ID_AUTOMATION`
  - optional sandbox fallback when `STRIPE_PRICE_ID` is empty:
    - `STRIPE_SANDBOX_CURRENCY`
    - `STRIPE_SANDBOX_AMOUNT_CENTS`
    - `STRIPE_SANDBOX_INTERVAL`
    - `STRIPE_SANDBOX_PRODUCT_NAME`
- `academy-website-runtime`
  - generated bundle containing `dist/`, `package.json`, and `package-lock.json`

Non-secret config
- `academy-website-env` ConfigMap is generated from manifests and sets:
  - `LEARN_AUTH_MODE=keycloak`
  - `LEARN_AUTH_PUBLIC_BASE_URL` (set by overlay)
  - `LEARN_KEYCLOAK_ISSUER_URL` (set by overlay)
  - `ENTITLEMENTS_API_URL=http://platform-entitlements-api.entitlements.svc.cluster.local:8080`

Notes
- The app serves the full Astro site bundle, but this workload is intended for the Learn surface.
- Keep the product/docs static surfaces outside the cluster unless you explicitly choose otherwise.
- This app is typically composed into a Learn integration target when SSR routes and middleware are required.
- If you use a private runtime renderer or secret-generation flow, keep that helper outside the public workload contract.
