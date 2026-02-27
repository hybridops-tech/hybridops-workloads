# Entitlements API Contract (Stage 1, Pre-Moodle)

Purpose
- Define the minimum Entitlements API required to unlock paid docs access and HyOps Copilot member tiering before Moodle is introduced.
- Keep implementation aligned to the stateless-cluster + externalized state model.

Scope (Stage 1)
- Stripe webhook ingestion and idempotent processing
- Entitlement persistence in external HA PostgreSQL
- Internal read API for entitlement checks (optional if Worker relies only on Keycloak role claims)
- Optional Keycloak role synchronization (`learn_member`)

Out of scope (Stage 1)
- Moodle enrollment sync (Stage 2)
- Complex plan catalogs/discount logic
- Customer support/admin UI

Reference implementation skeleton
- `/Users/jeleel/Downloads/vsc/hybridops-docs/control/backend/entitlements-api`

## Architecture Placement

- Workload: `apps/platform/entitlements-api` (RKE2 / Argo CD)
- Namespace: `entitlements`
- Database: external HA PostgreSQL (authoritative)
- Identity provider: Keycloak (`auth.hybridops.tech`)
- Payment processor: Stripe

State rule
- Do not store authoritative entitlement or webhook processing state in cluster-local PVs.

## Trust Boundaries

External callers
- Stripe -> `POST /webhooks/stripe`
- (Optionally) Learn portal backend -> internal authenticated endpoints

Internal callers
- Docs/Copilot Worker (service-to-service) if entitlement lookup is used
- Keycloak Admin API (outbound) for role sync

## Canonical Source of Truth

Canonical truth for paid access is the Entitlements DB state (external Postgres).

Keycloak role sync is a delivery mechanism for faster access checks, not the authoritative billing record.

Implication
- If role sync temporarily fails, the DB still reflects the correct entitlement status.
- Retry role sync and keep an audit trail.

## Entitlement Model (Minimal)

Primary unlock for Stage 1
- Entitlement key: `learn_member`

Expected behavior
- `learn_member` active => unlock member docs corpus + higher/unlimited Copilot quota
- `learn_member` inactive => public docs corpus + public Copilot quota

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
- Map Stripe customer/subscription to a HyOps subject (`user_id`)
- Upsert subscription status
- Upsert `learn_member` entitlement state
- Record webhook event in `stripe_events` table
- Trigger/queue Keycloak role sync if enabled

Response (success)
```json
{
  "received": true,
  "event_id": "evt_123",
  "processed": true
}
```

Response (duplicate/idempotent replay)
```json
{
  "received": true,
  "event_id": "evt_123",
  "processed": false,
  "reason": "duplicate_event"
}
```

### 3) Subject Entitlements (internal, recommended)

`GET /v1/subjects/{subject_id}/entitlements`

Purpose
- Internal service lookup (Copilot Worker or docs BFF) when claims-only checks are insufficient

Auth
- Internal service authentication only (mTLS, service JWT, or signed shared secret header; choose one and standardize)

Example response
```json
{
  "subject_id": "kc:8d4b...",
  "entitlements": [
    {
      "key": "learn_member",
      "status": "active",
      "starts_at": "2026-02-24T00:00:00Z",
      "ends_at": null
    }
  ],
  "updated_at": "2026-02-24T12:00:00Z"
}
```

### 4) Subject Entitlement Summary (internal, optional convenience)

`GET /v1/subjects/{subject_id}/summary`

Purpose
- Shortcut response for runtime gates (docs/Copilot)

Example response
```json
{
  "subject_id": "kc:8d4b...",
  "tier": "member",
  "copilot_tier": "member",
  "docs_tier": "member",
  "entitlements": ["learn_member"],
  "source": "db"
}
```

### 5) Admin/Backoffice Reconcile (internal, optional)

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
- `subject_id` (unique, e.g. Keycloak `sub`)
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
- `status` (`active`, `trialing`, `past_due`, `canceled`, etc.)
- `current_period_end` (nullable)
- `raw_last_event_type`
- `raw_last_event_id`
- `created_at`
- `updated_at`

### `entitlements`
Authoritative access state used by docs/Copilot.

Fields (logical)
- `id` (PK)
- `subject_id` (FK -> `subjects.subject_id`)
- `entitlement_key` (e.g. `learn_member`)
- `status` (`active`, `inactive`, `revoked`)
- `source` (`stripe`, `admin`)
- `source_ref` (subscription/customer id)
- `starts_at`
- `ends_at` (nullable)
- `updated_at`

Constraints
- Unique active record strategy per `(subject_id, entitlement_key)` (implementation choice: partial unique index or upsert semantics)

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
Queue for Keycloak role sync retries (optional but strongly recommended).

Fields (logical)
- `id` (PK)
- `subject_id`
- `operation` (`grant_role`, `revoke_role`)
- `role_name` (`learn_member`)
- `payload` (JSON)
- `attempts`
- `next_attempt_at`
- `status` (`pending`, `done`, `failed`)
- `last_error` (nullable)

## Stripe Event Handling Rules (Stage 1)

Mapping goal
- Paid active subscription => `learn_member: active`

Recommended mapping (minimal)
- `checkout.session.completed`
  - Create/confirm subject linkage (customer <-> subject)
  - Do not assume final long-lived entitlement without subscription confirmation if checkout is asynchronous
- `customer.subscription.created` / `updated`
  - Upsert subscription row
  - Set `learn_member` active when status is `active` or `trialing` (policy choice)
  - Set inactive/revoked when status is not entitled
- `customer.subscription.deleted`
  - Revoke/inactivate `learn_member`

Idempotency
- Ignore already processed `stripe_events.event_id`
- Webhooks can be replayed or arrive out of order; current state must be recomputed safely from the latest subscription status

## Keycloak Role Sync (Stage 1, Optional but Recommended)

Goal
- Mirror DB entitlement `learn_member` into Keycloak role claim for fast docs/Copilot checks

Behavior
- `learn_member` becomes active -> ensure Keycloak realm role `learn_member` is granted
- `learn_member` becomes inactive/revoked -> remove Keycloak role `learn_member`

Rules
- DB entitlement state remains canonical
- Role sync failures do not roll back entitlement DB updates
- Record failures and retry via outbox/reconcile

Inputs (placeholders)
- Keycloak issuer: `https://auth.hybridops.tech/realms/hybridops`
- Admin API client credentials supplied via Kubernetes Secret

## Copilot/Docs Integration Contract (Stage 1)

Worker behavior (already partially implemented)
- `public` users -> public docs index + public quota
- `member` users -> member docs index + member quota bypass/higher quota

Identity source (current vs target)
- Current: Worker supports a trusted-header tier mode for controlled internal testing (`x-hyops-tier`, `x-hyops-sub`, `x-hyops-entitlements`)
- Target: Worker validates Keycloak JWT/session and derives `learn_member` from claims/roles (or verified entitlements lookup)

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

Keycloak sync (if enabled)
- `KEYCLOAK_ISSUER_URL` (for example `https://auth.hybridops.tech/realms/hybridops`)
- `KEYCLOAK_ADMIN_BASE_URL`
- `KEYCLOAK_ADMIN_REALM`
- `KEYCLOAK_ADMIN_CLIENT_ID`
- `KEYCLOAK_ADMIN_CLIENT_SECRET` (via Secret)
- `KEYCLOAK_MEMBER_ROLE` (default `learn_member`)

Portal/docs URLs
- `LEARN_PORTAL_URL`
- `DOCS_PUBLIC_URL`
- `DOCS_MEMBER_URL` (if separate host is used)

## Acceptance Criteria (Stage 1)

- Stripe webhook endpoint is signature-verified and idempotent
- `learn_member` entitlement state is persisted in external Postgres
- Duplicate webhook events do not create duplicate entitlement changes
- Copilot/docs runtime can determine `public` vs `member` from a single entitlement source (claims or lookup)
- Keycloak role sync (if enabled) can be retried without corrupting entitlement state
- No authoritative entitlement state depends on cluster-local storage
