# Entitlements API Contract (Stage 1, Pre-Moodle)

Purpose
- Define the minimum Entitlements API required to unlock paid docs access, HyOps Copilot, and Academy track access before Moodle is introduced.
- Keep implementation aligned to the stateless-cluster + externalized state model.

Scope (Stage 1)
- Stripe webhook ingestion and idempotent processing
- Entitlement persistence in external HA PostgreSQL
- Internal read API for entitlement checks
- Optional Keycloak role synchronization for Academy access only

Out of scope (Stage 1)
- Moodle enrollment sync (Stage 2)
- Complex plan catalogs/discount logic
- Customer support/admin UI

Reference implementation skeleton
- `hybridops-docs/control/backend/entitlements-api`

## Architecture Placement

- Workload: `apps/platform/entitlements-api` (RKE2 / Argo CD)
- Namespace: `entitlements`
- Database: external HA PostgreSQL (authoritative)
- Identity provider: Keycloak (`auth.hybridops.tech`)
- Payment processor: Stripe

State rule
- Do not store authoritative entitlement or webhook processing state in cluster-local PVs.

## Canonical Source of Truth

Canonical truth for access is the Entitlements DB state in external PostgreSQL.

Keycloak role sync is a delivery mechanism for Academy UX and claims convenience, not the authoritative billing record.

Implication
- If role sync temporarily fails, the DB still reflects the correct entitlement status.
- Retry role sync and keep an audit trail.

## Entitlement Model (Stage 1)

Canonical entitlement families
- `docs_paid`: generic paid-docs access for manual grants or non-recurring offers
- `docs_paid_monthly`: monthly paid-docs billing SKU
- `docs_paid_yearly`: yearly paid-docs billing SKU
- `copilot_paid`: paid Copilot tier if sold separately
- `academy_all`: full Academy bundle
- `academy_track:<slug>`: track-specific Academy access

Legacy compatibility
- `learn_member` is treated as a legacy Academy bundle key during transition.
- New docs/Copilot authorization must not depend on `learn_member`.

Expected behavior
- Any active `docs_paid*` entitlement => paid docs tier
- Active `copilot_paid` entitlement => paid Copilot tier
- Active `academy_all` => full Academy access
- Active `academy_track:<slug>` => access only to that Academy track
- Active `learn_member` => legacy Academy bundle compatibility only

## API Endpoints (Stage 1)

### 1) Health

`GET /healthz`

Purpose
- Basic liveness/readiness and dependency summary (no secrets)

Example response
```json
{
  "ok": true,
  "service": "entitlements-api",
  "db": "ok",
  "stripe_webhook": "configured",
  "keycloak_sync": "enabled"
}
```

### 2) Stripe Webhook (required)

`POST /webhooks/stripe`

Requirements
- Verify Stripe signature using `STRIPE_WEBHOOK_SECRET`
- Use raw request body for signature verification
- Idempotent processing using Stripe `event.id`
- Return `2xx` only after durable DB write / accepted-for-processing semantics

Handled events (minimum)
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- Optional: `invoice.payment_failed`

Behavior
- Map Stripe customer/subscription to a HybridOps subject (`subject_id`)
- Upsert subscription status
- Read `hyops_entitlement_key` from Stripe metadata
- Upsert the exact entitlement named by `hyops_entitlement_key`
- Record webhook event in `stripe_events`
- Trigger or queue Keycloak role sync if the entitlement affects Academy access

Response (success)
```json
{
  "received": true,
  "event_id": "evt_123",
  "processed": true
}
```

Response (duplicate replay)
```json
{
  "received": true,
  "event_id": "evt_123",
  "processed": false,
  "reason": "duplicate_event"
}
```

### 3) Subject Entitlements (internal)

`GET /v1/subjects/{subject_id}/entitlements`

Purpose
- Internal service lookup for exact entitlement state

Auth
- Internal service authentication only (`x-internal-token` in the current stage-1 implementation)

Example response
```json
{
  "subject_id": "kc:8d4b...",
  "entitlements": [
    {
      "key": "docs_paid_monthly",
      "status": "active",
      "starts_at": "2026-02-24T00:00:00Z",
      "ends_at": null,
      "updated_at": "2026-02-24T12:00:00Z"
    },
    {
      "key": "academy_track:networking-foundations",
      "status": "active",
      "starts_at": "2026-02-24T00:00:00Z",
      "ends_at": null,
      "updated_at": "2026-02-24T12:00:00Z"
    }
  ]
}
```

### 4) Subject Entitlement Summary (internal convenience)

`GET /v1/subjects/{subject_id}/summary`

Purpose
- Shortcut response for runtime gates in Learn, docs, and Copilot

Example response
```json
{
  "subject_id": "kc:8d4b...",
  "tier": "academy",
  "academy_access": true,
  "academy_all_access": false,
  "academy_scope": "track",
  "academy_tracks": ["networking-foundations"],
  "docs_access": true,
  "docs_plan": "monthly",
  "docs_tier": "paid",
  "copilot_access": false,
  "copilot_tier": "public",
  "entitlements": ["academy_track:networking-foundations", "docs_paid_monthly"],
  "source": "db"
}
```

Rules
- `tier` is an Academy-oriented convenience field and must not be used as the sole docs/Copilot authorization check.
- Docs gating keys off `docs_access` / `docs_tier`.
- Copilot gating keys off `copilot_access` / `copilot_tier`, or `docs_access` if your commercial policy intentionally bundles them.

### 5) Admin or Backoffice Reconcile (optional)

`POST /internal/reconcile/subject/{subject_id}`

Purpose
- Recompute entitlement state from subscription rows and retry Keycloak sync for one subject

Auth
- Internal admin auth only

## Database Schema (Minimal, Stage 1)

Use external HA PostgreSQL. The exact SQL can evolve; the logical tables below are the minimum contract.

### `subjects`
Represents a stable identity anchor (typically Keycloak `sub`).

Fields (logical)
- `id` (PK)
- `subject_id` (unique, for example Keycloak `sub`)
- `email` (nullable)
- `provider` (default `keycloak`)
- `created_at`
- `updated_at`

### `billing_subscriptions`
Tracks Stripe subscription/customer linkage and billing status.

Fields (logical)
- `id` (PK)
- `subject_id` (FK -> `subjects.subject_id`)
- `stripe_customer_id`
- `stripe_subscription_id` (unique, nullable until subscription exists)
- `status` (`active`, `trialing`, `past_due`, `canceled`, and so on)
- `current_period_end` (nullable)
- `raw_last_event_type`
- `raw_last_event_id`
- `created_at`
- `updated_at`

### `entitlements`
Authoritative access state used by Learn, docs, and Copilot.

Fields (logical)
- `id` (PK)
- `subject_id` (FK -> `subjects.subject_id`)
- `entitlement_key` (for example `docs_paid_monthly` or `academy_track:networking-foundations`)
- `status` (`active`, `inactive`, `revoked`)
- `source` (`stripe`, `admin`)
- `source_ref` (subscription/customer id)
- `starts_at`
- `ends_at` (nullable)
- `updated_at`

Constraints
- Unique record semantics per `(subject_id, entitlement_key)`
- Webhook processing must be idempotent across replayed events

### `stripe_events`
Idempotency and audit for webhook processing.

Fields (logical)
- `event_id` (PK, Stripe event id)
- `event_type`
- `received_at`
- `processed_at` (nullable)
- `status` (`processed`, `ignored`, `failed`)
- `error_message` (nullable)

### `sync_outbox` (recommended)
Queue for Keycloak role sync retries.

Fields (logical)
- `id` (PK)
- `subject_id`
- `operation` (`grant_role`, `revoke_role`)
- `role_name` (for example `learn_member` in the current stage-1 rollout)
- `payload` (JSON)
- `attempts`
- `next_attempt_at`
- `status` (`pending`, `done`, `failed`)
- `last_error` (nullable)

## Stripe Event Handling Rules (Stage 1)

Mapping goal
- Stripe checkout metadata names the entitlement to grant or revoke.

Recommended mapping
- `checkout.session.completed`
  - Create or confirm subject linkage (customer <-> subject)
  - Persist `hyops_entitlement_key` metadata for later subscription events
- `customer.subscription.created` / `updated`
  - Upsert subscription row
  - Set the named entitlement active when status is `active` or `trialing`
  - Set inactive or revoked when status is not entitled
- `customer.subscription.deleted`
  - Revoke or inactivate the named entitlement

Product examples
- Docs monthly subscription -> `docs_paid_monthly`
- Docs yearly subscription -> `docs_paid_yearly`
- Academy full bundle -> `academy_all`
- Networking track -> `academy_track:networking-foundations`
- Separate Copilot add-on -> `copilot_paid`

Idempotency
- Ignore already processed `stripe_events.event_id`
- Webhooks can be replayed or arrive out of order; current state must be recomputed safely from the latest subscription status

## Keycloak Role Sync (Optional, Academy Only)

Goal
- Mirror Academy access into one Keycloak role for Learn UX and claims convenience

Behavior
- `academy_all` or `academy_track:<slug>` becomes active -> ensure `KEYCLOAK_ACADEMY_ROLE` is granted
- Academy entitlement becomes inactive or revoked -> remove `KEYCLOAK_ACADEMY_ROLE` when no Academy access remains
- Legacy `learn_member` continues to map to the same Academy role during migration

Rules
- DB entitlement state remains canonical
- Role sync failures do not roll back DB updates
- Docs and Copilot authorization must not depend on the Academy role alone

Inputs (placeholders)
- Keycloak issuer: `https://auth.hybridops.tech/realms/hybridops`
- Admin API client credentials supplied via Kubernetes Secret

## Docs and Copilot Integration Contract (Stage 1)

Worker behavior
- `public` users -> public docs index + public quota
- `paid` docs users -> paid docs index + higher docs quota behavior
- optional separate `copilot_paid` users -> higher Copilot tier when sold separately

Identity source
- Current: Worker supports a trusted-header tier mode for controlled internal testing (`x-hyops-tier`, `x-hyops-sub`, `x-hyops-entitlements`)
- Target: Worker validates Keycloak JWT/session and derives docs access from explicit entitlements or the Entitlements API summary lookup

Contract rule
- Docs/Copilot code should key off `docs_paid*` and `copilot_paid`, not `learn_member`.

## Security Requirements

- No secrets in Git (Stripe keys, webhook secret, DB credentials, Keycloak admin creds)
- Verify Stripe webhook signatures on raw body
- Internal entitlement endpoints require service authentication
- Audit admin/reconcile actions
- TLS everywhere (external and internal where practical)

## Environment Variables (Contract-Level Placeholders)

Required
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_SSLMODE`
- `DATABASE_USER` / `DATABASE_PASSWORD` (via Secret)
- `STRIPE_SECRET_KEY` (via Secret)
- `STRIPE_WEBHOOK_SECRET` (via Secret)

Entitlement model
- `ENTITLEMENT_ACADEMY_ALL_KEY` (default `academy_all`)
- `ENTITLEMENT_LEGACY_ACADEMY_BUNDLE_KEY` (default `learn_member`)
- `ENTITLEMENT_ACADEMY_TRACK_PREFIX` (default `academy_track:`)
- `ENTITLEMENT_DOCS_PAID_KEY` (default `docs_paid`)
- `ENTITLEMENT_DOCS_MONTHLY_KEY` (default `docs_paid_monthly`)
- `ENTITLEMENT_DOCS_YEARLY_KEY` (default `docs_paid_yearly`)
- `ENTITLEMENT_COPILOT_PAID_KEY` (default `copilot_paid`)

Keycloak sync (if enabled)
- `KEYCLOAK_ISSUER_URL`
- `KEYCLOAK_ADMIN_BASE_URL`
- `KEYCLOAK_ADMIN_REALM`
- `KEYCLOAK_ADMIN_CLIENT_ID`
- `KEYCLOAK_ADMIN_CLIENT_SECRET` (via Secret)
- `KEYCLOAK_ACADEMY_ROLE` (current stage-1 rollout uses `learn_member`)

Portal and docs URLs
- `LEARN_PORTAL_URL`
- `DOCS_PUBLIC_URL`
- `DOCS_PAID_URL` (if separate paid-docs host is used)

## Acceptance Criteria (Stage 1)

- Stripe webhook endpoint is signature-verified and idempotent
- Explicit entitlement keys are persisted in external PostgreSQL
- Duplicate webhook events do not create duplicate entitlement changes
- Learn, docs, and Copilot can derive access from one entitlement source (claims or lookup)
- Keycloak role sync, if enabled, mirrors Academy access without becoming the source of truth
- No authoritative entitlement state depends on cluster-local storage
