# Platform Entitlements API

Purpose
- Stripe webhook ingestion and entitlement state for Learn/Copilot access control.
- Stateless service deployed in Kubernetes, backed by external HA PostgreSQL.

Anti-drift
- Do not run the authoritative entitlements DB inside the cluster.
- Use external PostgreSQL endpoints and existing Secrets for credentials.
- Keep this service independent of Moodle so Stage 1 can ship before Moodle.

Contract:
- `docs/entitlements-api-stage1-contract.md` (repo-level implementation contract)

Runtime contract
- Namespace: `entitlements`
- Service: `platform-entitlements-api`
- Ingress host: overlay-defined
- Runtime model: public `node:22-alpine` base image plus `platform-entitlements-api-runtime` synced by `platform/k8s/runtime-bundle-secret`
- External DB: PostgreSQL remains outside the cluster

Required secret
- `platform-entitlements-api-secrets`
  - projected by `ExternalSecret` from `gcp-secret-manager` in the internal on-prem target
  - `DATABASE_PASSWORD`
  - `INTERNAL_API_TOKEN`
  - `STRIPE_SECRET_KEY`
    - Stage 1 uses the same Stripe secret as the Academy website checkout path.
  - `STRIPE_WEBHOOK_SECRET`
  - `KEYCLOAK_EVENTS_SHARED_SECRET` (required when Keycloak event webhook verification is enabled)
- `platform-entitlements-api-runtime`
  - runtime bundle containing `package.json`, `src/`, and `sql/`
  - normative sync path: `platform/k8s/runtime-bundle-secret`

Optional secret overrides
- `platform-entitlements-api-secrets`
  - `DATABASE_PORT`
  - `DATABASE_NAME`
  - `DATABASE_SSLMODE`
  - `KEYCLOAK_ADMIN_CLIENT_SECRET`
  - `KEYCLOAK_SYNC_ENABLED`
  - `KEYCLOAK_SYNC_POLL_INTERVAL_MS`
  - `KEYCLOAK_SYNC_MAX_ATTEMPTS`

On-prem secret source
- For long-lived application credentials, the normative path is:
  - runtime vault
  - GCP Secret Manager
  - `ExternalSecret`
- Treat hand-applied long-lived copies of `platform-entitlements-api-secrets` as break-glass only.

Non-secret config
- `platform-entitlements-api-env` ConfigMap is generated from manifests and sets:
  - `PORT=8080`
  - `NODE_ENV=production`
  - `LOG_LEVEL=info`
  - `DATABASE_HOST` (set by overlay)
  - `DATABASE_USER` (set by overlay)
  - `DATABASE_NAME=hyops_entitlements`
  - `DATABASE_PORT=5432`
  - `DATABASE_SSLMODE=require`
  - `ENTITLEMENT_ACADEMY_ALL_KEY=academy_all`
  - `ENTITLEMENT_LEGACY_ACADEMY_BUNDLE_KEY=learn_member`
  - `ENTITLEMENT_ACADEMY_TRACK_PREFIX=academy_track:`
  - `ENTITLEMENT_DOCS_PAID_KEY=docs_paid`
  - `ENTITLEMENT_DOCS_MONTHLY_KEY=docs_paid_monthly`
  - `ENTITLEMENT_DOCS_YEARLY_KEY=docs_paid_yearly`
  - `ENTITLEMENT_COPILOT_PAID_KEY=copilot_paid`
  - `KEYCLOAK_SYNC_ENABLED=false`
  - `KEYCLOAK_ISSUER_URL` (set by overlay)
  - `KEYCLOAK_ADMIN_BASE_URL` (set by overlay)
  - `KEYCLOAK_ADMIN_REALM=hybridops`
  - `KEYCLOAK_ADMIN_CLIENT_ID=hyops-entitlements-api`
  - `KEYCLOAK_ACADEMY_ROLE=learn_member`
    - Stage-1 compatibility role for Academy claims. Docs and Copilot should key off explicit entitlements, not this role alone.
  - `KEYCLOAK_EVENTS_WEBHOOK_ENABLED=true`
  - `KEYCLOAK_EVENTS_HMAC_ALGORITHM=sha256`

Notes
- This workload deploys only the HTTP API. The optional outbox worker remains off until role sync is needed.
- Apply all SQL migrations in `hybridops-docs/control/backend/entitlements-api/sql/*.sql` to the external database before enabling Stripe traffic.
- Keep authoritative entitlement state in the external PostgreSQL service, not cluster-local storage.
- If you use a runtime bundle or secret-generation helper, keep that helper outside the public workload contract.
