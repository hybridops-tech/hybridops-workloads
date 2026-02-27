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

What is currently in this workload folder
- `base/application.yaml`: Argo CD `Application` placeholder for the chart + values repo reference.
- `base/values.yaml`: chart-agnostic deployment values draft (hosts, external Postgres endpoints, env placeholders, secrets).
- `overlays/onprem/values.yaml`: on-prem overlay values draft.
- `base/namespace.yaml`: target namespace (`entitlements`).

Implementation/deploy next steps (stateless + external DB)
- Replace chart/image placeholders in `base/application.yaml` and `base/values.yaml`.
- Keep `persistence` disabled for the app workload (stateless API pods only).
- Wire `DATABASE_*` host/name/ssl env values to the external PostgreSQL RW endpoint.
- Wire `DATABASE_USER` / `DATABASE_PASSWORD` from existing K8s Secrets (do not inline credentials).
- Create/apply Secrets for Stripe + internal token (`stripe-webhook`, `stripe-api`, `entitlements-app`) before sync.
- Apply SQL schema (`control/backend/entitlements-api/sql/001_init.sql`) to the external DB before enabling webhook traffic.
- Scale replicas independently of state (`replicaCount` > 1 is valid because state is externalized).
