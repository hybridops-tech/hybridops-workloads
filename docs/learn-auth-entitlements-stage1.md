# Learn Auth and Entitlements (Stage 1, Pre-Moodle)

Purpose
- Define the minimum self-hosted auth + payments integration required for paid docs, HyOps Copilot, and Academy access.
- Keep Moodle out of the critical path for the first paid release.

Contract reference
- `docs/entitlements-api-stage1-contract.md`

## Scope (Stage 1)

In scope
- Keycloak OIDC login (`auth.hybridops.tech`)
- Learn portal entry (`learn.hybridops.tech`)
- Stripe checkout + webhooks
- Entitlements API + external HA PostgreSQL
- Docs/Copilot tiering from explicit entitlements
- Academy access from explicit bundle or track entitlements

Out of scope (Stage 2)
- Moodle course delivery and enrollment synchronization

## Components

- `platform/keycloak` (RKE2): identity provider (OIDC)
- `platform/entitlements-api` (RKE2): webhook intake + entitlement source of truth
- External HA PostgreSQL: stores entitlements and billing-derived access state
- Cloudflare Worker (`docs-chat-worker.js`): reads identity and entitlement state, then selects docs corpus + quota
- Cloudflare static docs hosting: public docs build and paid docs build
- Stripe: payments + subscription lifecycle

## Stage-1 Access Model

Identity
- `auth` proves who the user is
- `entitlement` proves what the user paid for

Canonical entitlement families
- `docs_paid`, `docs_paid_monthly`, `docs_paid_yearly`
- `copilot_paid`
- `academy_all`
- `academy_track:<slug>`
- legacy `learn_member` remains supported only as a compatibility Academy bundle key

Runtime rules
- Paid docs access is derived from `docs_paid*`
- Paid Copilot access is derived from `copilot_paid` or from docs access if you intentionally bundle them commercially
- Academy access is derived from `academy_all` or `academy_track:<slug>`
- Do not treat a generic `member` label as blanket authorization

## Hosts and Clients

Realm
- `hybridops`

Hosts
- `auth.hybridops.tech` (Keycloak)
- `learn.hybridops.tech` (portal/login/payment UX)
- `docs.hybridops.tech` (public docs + Copilot)

Clients (initial)
- `hyops-learn` in the Stage 1 rollout (public PKCE client for the Learn surface)
- a public baseline may choose a different client ID, but the client remains overlay-defined rather than hardcoded into the Stage 1 contract
- `hyops-docs` (public or BFF-backed; depends on final login UX for the docs host)
- `hyops-entitlements-api` (confidential, optional for service-level calls)

Claims / roles
- `learn_admin` (staff/admin override)
- `learn_member` may still be used as the Academy convenience role in the current stage-1 rollout
- Docs and Copilot should not depend on `learn_member` for authorization

Cookie/session requirement
- Session/cookie must be usable across subdomains (`Domain=.hybridops.tech`)
- `Secure`, `HttpOnly`, `SameSite=Lax`

## Stripe -> Entitlement Flow

1. User checks out from `learn.hybridops.tech`
2. Checkout metadata includes `hyops_entitlement_key`
3. Stripe webhook hits `platform/entitlements-api` (`/webhooks/stripe`)
4. Entitlements API upserts billing state and the named entitlement in external PostgreSQL
5. User signs in or refreshes session
6. Runtime checks derive docs, Copilot, and Academy access from explicit entitlements

Examples
- Docs monthly -> `docs_paid_monthly`
- Docs yearly -> `docs_paid_yearly`
- Academy networking track -> `academy_track:networking-foundations`
- Academy full bundle -> `academy_all`
- Separate Copilot add-on -> `copilot_paid`

## Worker Integration

Current
- Worker supports separate public and paid docs corpora (`DOCGPT_PUBLIC_*`, `DOCGPT_MEMBER_*`)
- Worker supports public quota enforcement and paid-tier bypass or higher quota
- Worker can validate Keycloak JWTs or use Entitlements API summary fallback

Required contract
- Worker should key off `docs_paid*` using `DOCGPT_DOCS_ENTITLEMENT`
- `DOCGPT_MEMBER_ENTITLEMENT` remains fallback compatibility only
- Academy suggestions and Learn CTAs can still be returned separately from docs entitlement checks

## Anti-Drift Rules

- Do not make paid access depend on frontend-only gating.
- Do not duplicate docs into the Learn app.
- Do not store authoritative entitlement state in cluster-local PVs.
- Do not collapse docs, Copilot, and Academy authorization into one generic `member` flag.
