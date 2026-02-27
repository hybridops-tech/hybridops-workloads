# Learn Platform Topology (Stage 1 -> Stage 2)

Purpose
- Lock the deployment topology for paid docs access, HyOps Copilot, and later Moodle integration.
- Keep platform recovery aligned to the stateless-cluster + external-state model.

## Platform Invariant (Locked)

- Kubernetes clusters are disposable execution planes.
- Authoritative state is externalized.
- External HA PostgreSQL is the DB system of record for auth, entitlements, and later Moodle DB.
- Moodle file storage (`moodledata`) must be external object storage (Azure Blob or GCS) before production use.

## Hostnames (Target)

- `docs.hybridops.tech`: public docs + HyOps Copilot (preview for anonymous users)
- `learn.hybridops.tech`: member login/payment portal first, Moodle later
- `learn-docs.hybridops.tech` (or equivalent member docs path/host): richer/member docs build (current `academy` docs build)
- `auth.hybridops.tech` (recommended): Keycloak

## Stage 1 (No Moodle Required)

Goal
- Ship paid docs + HyOps Copilot access before Moodle exists.

Components
- Cloudflare static hosting: public docs build and member docs build
- Cloudflare Worker: HyOps Copilot API (`/api/docs-chat`)
- RKE2 + Argo CD workloads:
  - `platform/keycloak` (OIDC)
  - `platform/entitlements-api` (Stripe webhook + entitlement checks)
- External HA PostgreSQL (already available; use placeholders in workloads until final endpoint is assigned)
- Stripe (payments)
- OpenAI API (`gpt-5-nano`) for Copilot synthesis

User flow
1. Anonymous user accesses `docs.hybridops.tech`
2. Copilot/docs preview gate prompts sign-in / join Learn
3. User signs in and pays via `learn.hybridops.tech`
4. Stripe webhook updates entitlements
5. Same identity unlocks member docs + higher Copilot quota

## Stage 2 (Moodle Added)

Goal
- Add course delivery without changing the docs/Copilot entitlement model.

Additions
- `education/moodle` workload in RKE2
- External object storage for `moodledata` (Azure Blob or GCS)
- Same Keycloak OIDC provider
- Same entitlements source of truth

Notes
- Moodle is not the docs renderer; docs remain on MkDocs/Cloudflare.
- Moodle links to docs pages and docs can link back to course modules.

## External State Placeholders (Stage 1)

Use placeholders until production endpoints are assigned:

- RW Postgres endpoint: `REPLACE_EXT_POSTGRES_RW_HOST`
- RO/DR Postgres endpoint: `REPLACE_EXT_POSTGRES_RO_DR_HOST`
- DB port: `5432`
- TLS/SSL mode: `require`

## Argo CD Workloads (Stage 1 Minimum)

Enable in `clusters/onprem/apps.yaml`:
- `platform/keycloak`
- `platform/entitlements-api`
- `academy/website` (member/login portal surface as needed)
- `studio/docsgpt` (optional only if self-hosting Copilot API; current preferred path is Cloudflare Worker)

## Anti-Drift Rules

- Do not add cluster-local databases for auth/entitlements/Moodle production data.
- Do not make Copilot access control frontend-only; backend entitlement checks remain source of truth.
- Do not duplicate technical docs into Moodle; link to the docs site.
- Keep public and member docs indexes separate for Copilot retrieval.

## Stage 1 Identity and Entitlements (Detailed Placeholder Plan)

Identity provider (self-hosted)
- Reuse `platform/keycloak` before introducing another IdP.
- Keycloak realm placeholder: `hybridops`.
- Preferred host: `auth.hybridops.tech`.

Entitlements authority
- `platform/entitlements-api` stores and serves entitlement state backed by external HA PostgreSQL.
- Stripe webhooks update entitlement rows (for example `learn_member` active/inactive).
- Copilot and member docs access checks should read the same entitlement source (directly or via signed claims issued after login).

Copilot corpus/limit behavior
- Anonymous users -> public docs index + public quota.
- Paid users (`learn_member`) -> member docs index + higher/unlimited quota.

Implementation note
- The Worker already supports public/member index selection and a temporary trusted-header tier mode.
- Replace the trusted-header stub with Keycloak JWT/session validation before public paid rollout.
