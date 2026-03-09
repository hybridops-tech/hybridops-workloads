# Learn Platform Topology (Stage 1 -> Stage 2)

Purpose
- Lock the deployment topology for paid docs access, HyOps Copilot, and later Moodle integration.
- Keep platform recovery aligned to the stateless-cluster + external-state model.

## Platform Invariant (Locked)

- Kubernetes clusters are disposable execution planes.
- Authoritative state is externalized.
- External HA PostgreSQL is the DB system of record for auth, entitlements, and later Moodle DB.
- Moodle file storage (`moodledata`) must be external object storage before production use.

## Hostnames (Target)

- `docs.hybridops.tech`: public docs + HyOps Copilot
- `learn.hybridops.tech`: Learn portal, login, pricing, Academy access UX
- `learn-docs.hybridops.tech` (or equivalent paid path/host): richer paid docs build if you keep it separate from public docs
- `auth.hybridops.tech`: Keycloak

## Stage 1 (No Moodle Required)

Goal
- Ship paid docs, HyOps Copilot, and Academy access before Moodle exists.

Components
- Cloudflare static hosting: public docs build and paid docs build
- Cloudflare Worker: HyOps Copilot API (`/api/docs-chat`)
- RKE2 + Argo CD workloads:
  - `platform/keycloak` (OIDC)
  - `platform/entitlements-api` (Stripe webhook + entitlement checks)
  - `academy/website` (`learn.hybridops.tech` SSR app)
- External HA PostgreSQL
- Stripe
- OpenAI API (`gpt-5-nano`) for Copilot synthesis

User flow
1. Anonymous user accesses `docs.hybridops.tech`
2. Copilot/docs preview gate prompts sign-in or join Learn
3. User signs in and purchases a specific offer via `learn.hybridops.tech`
4. Stripe webhook updates explicit entitlement rows
5. Same identity receives only the capabilities granted by those entitlements

## Stage-1 Access Rules

Authorization is capability-based.

- Paid docs access: `docs_paid`, `docs_paid_monthly`, or `docs_paid_yearly`
- Paid Copilot access: `copilot_paid` if sold separately, or the same docs entitlement if you intentionally bundle them
- Academy full access: `academy_all`
- Academy track access: `academy_track:<slug>`
- Legacy compatibility only: `learn_member` as temporary Academy bundle fallback

Contract rule
- Being authenticated does not imply being entitled.
- Being “a member” is marketing language, not the runtime authorization model.

## Stage 2 (Moodle Added)

Goal
- Add course delivery without changing the docs/Copilot entitlement model.

Additions
- `education/moodle` workload in RKE2
- External object storage for `moodledata`
- Same Keycloak OIDC provider
- Same Entitlements API as the source of truth

Notes
- Moodle is not the docs renderer; docs remain on MkDocs/Cloudflare.
- Moodle enrollment should be driven from explicit Academy entitlements, not a generic member role.

### Stage-2 SSO assumptions

- Moodle uses the same Keycloak realm as Learn.
- Moodle gets its own client; it must not reuse the Learn client directly.
- Learn remains the public entry surface; Moodle is the course-delivery surface.
- Authentication in Moodle does not by itself grant course access.

### Stage-2 enrollment rule

Recommended rule:

- entitlements stay authoritative
- Moodle reflects access through enrollment sync or launch-time checks
- do not recreate billing or entitlement authority inside Moodle

This means:

- `academy_all` or `academy_track:<slug>` should map to course access
- a generic authenticated session should not map to course access

### Stage-2 rollout order

1. stand up `education/moodle`
2. confirm external PostgreSQL and object storage
3. configure Keycloak SSO for Moodle
4. create one course per canonical Academy track
5. set `ACADEMY_LMS_BASE_URL` in Learn runtime
6. validate member launch from:
   - Academy workspace
   - Account page
   - track outline page
7. verify fallback behavior with `ACADEMY_LMS_BASE_URL` unset

## Argo CD Workloads (Stage 1 Minimum)

Enable in the low-cost hybrid target:
- `platform/keycloak`
- `platform/entitlements-api`
- `academy/website`
- `studio/docsgpt` only if you later choose a self-hosted Copilot API instead of the Cloudflare Worker

## Anti-Drift Rules

- Do not add cluster-local databases for auth, entitlements, or Moodle production data.
- Do not make Copilot access control frontend-only; backend entitlement checks remain source of truth.
- Do not duplicate technical docs into Moodle; link to the docs site.
- Keep public and paid docs indexes separate for Copilot retrieval.
- Do not let Moodle become the public marketing surface for Academy.
- Do not hardcode Moodle hostnames in Learn routes; use `ACADEMY_LMS_BASE_URL` plus per-track course paths.

## Stage-1 Identity and Entitlements

Identity provider
- Reuse `platform/keycloak` before introducing another IdP.
- Keycloak realm placeholder: `hybridops`.
- Preferred host: `auth.hybridops.tech`.

Entitlements authority
- `platform/entitlements-api` stores and serves entitlement state backed by external HA PostgreSQL.
- Stripe webhooks update explicit entitlement rows.
- Learn, docs, and Copilot should read the same entitlement source directly or through validated claims.

Copilot corpus/limit behavior
- Anonymous users -> public docs index + public quota.
- Paid docs users -> paid docs index + paid quota policy.
- Academy access should influence Academy CTAs and module links, not public docs authorization by itself.

Implementation note
- The Worker already supports public/paid corpus selection and a temporary trusted-header tier mode.
- Replace the trusted-header stub with Keycloak JWT/session validation before public paid rollout.
