# Learn Auth and Entitlements (Stage 1, Pre-Moodle)

Purpose
- Define the minimum self-hosted auth + payments integration required to unlock member docs and HyOps Copilot.
- Keep Moodle out of the critical path for the first paid release.

## Scope (Stage 1)

Contract reference
- `docs/entitlements-api-stage1-contract.md`


In scope
- Keycloak OIDC login (`auth.hybridops.tech`)
- Learn portal/member entry (`learn.hybridops.tech`)
- Stripe checkout + webhooks
- Entitlements API + external HA PostgreSQL
- Docs/Copilot tier unlock (`public` vs `learn_member`)

Out of scope (Stage 2)
- Moodle course delivery and enrollment synchronization

## Components

- `platform/keycloak` (RKE2): identity provider (OIDC)
- `platform/entitlements-api` (RKE2): webhook intake + entitlement source of truth
- External HA PostgreSQL: stores entitlements (and Keycloak DB if you choose)
- Cloudflare Worker (`docs-chat-worker.js`): reads identity/tier and selects docs corpus + quota
- Cloudflare static docs hosting: public docs and member docs builds
- Stripe: payments + subscription lifecycle

## Keycloak Placeholders

Realm
- `hybridops`

Hosts
- `auth.hybridops.tech` (Keycloak)
- `learn.hybridops.tech` (portal/login/payment UX)
- `docs.hybridops.tech` (public docs + Copilot)

Clients (initial)
- `hyops-learn-web` (confidential)
- `hyops-docs` (public or BFF-backed; depends final login UX for docs host)
- `hyops-entitlements-api` (confidential, optional for service-level calls/introspection)

Claims / roles
- `learn_member` (paid docs + Copilot entitlement)
- `learn_admin` (staff/admin override)

Cookie/session requirement
- Session/cookie must be usable across subdomains (`Domain=.hybridops.tech`)
- `Secure`, `HttpOnly`, `SameSite=Lax`

## Stripe -> Entitlement Flow

1. User checks out via Stripe from `learn.hybridops.tech`
2. Stripe webhook hits `platform/entitlements-api` (`/webhooks/stripe`)
3. Entitlements API upserts subscription/entitlement status in external Postgres
4. User signs in / refreshes session
5. Keycloak-issued session/token (or API entitlement lookup) reflects `learn_member`
6. Docs/Copilot unlocks member corpus + higher quota

## Entitlements Table (Minimal Placeholder)

Suggested logical fields (implementation can vary):
- `user_id` (stable subject from Keycloak)
- `entitlement` (`learn_member`)
- `status` (`active`, `past_due`, `canceled`)
- `starts_at`
- `ends_at` (nullable)
- `source` (`stripe`)
- `source_ref` (subscription/customer id)
- `updated_at`

## Worker Integration (Current vs Next)

Current
- Worker supports `public`/`member` corpus selection (`DOCGPT_PUBLIC_*`, `DOCGPT_MEMBER_*`)
- Worker supports public quota enforcement and member bypass
- Worker identity mode is currently a stub (`DOCGPT_AUTH_MODE=none`) with optional trusted-header mode for controlled testing

Next
- Validate Keycloak JWT/session in Worker
- Derive tier from roles/claims (or verified entitlements lookup)
- Keep backend as source of truth for quota and corpus selection

## Anti-Drift Rules

- Do not make paid access depend on frontend-only gating.
- Do not duplicate docs into the learn portal CMS/app. Keep docs in the docs builds.
- Do not store authoritative entitlements state in cluster-local PVs.
- Treat `learn_member` (or successor entitlement) as the single unlock for both member docs and Copilot tier.
