# Learn Platform Topology

Purpose
- Define the public workload baseline for Learn, Auth, and entitlement-backed access.
- Keep the public repo focused on the customer-consumable Stage 1 platform boundary.

## Platform invariant

- Kubernetes clusters are disposable execution planes.
- Authoritative state is externalized.
- Identity and entitlement state must survive cluster rebuilds.

## Public hostnames

- `docs.hybridops.tech`: public docs and HyOps Copilot
- `learn.hybridops.tech`: Learn portal, sign-in, pricing, and Academy access UX
- `learn-docs.hybridops.tech`: paid/private docs surface when operated separately from public docs
- `auth.hybridops.tech`: Keycloak

## Stage 1 baseline

Goal
- Ship paid docs, HyOps Copilot, and Academy access without introducing a separate LMS workload into the public baseline.

Components
- Cloudflare static hosting for docs surfaces
- Cloudflare Worker for HyOps Copilot (`/api/docs-chat`)
- RKE2 + Argo CD workloads:
  - `platform/keycloak`
  - `platform/entitlements-api`
  - `academy/website`
- External PostgreSQL
- Stripe
- OpenAI API for Copilot synthesis

User flow
1. Anonymous user accesses `docs.hybridops.tech`.
2. Copilot or docs gating sends the user to Learn sign-in or purchase.
3. User signs in and purchases a specific offer via `learn.hybridops.tech`.
4. Stripe webhooks update explicit entitlement rows.
5. Docs, Copilot, and Academy routes read the same entitlement source.

## Access rules

Authorization is capability-based.

- Paid docs access: `docs_paid`, `docs_paid_monthly`, or `docs_paid_yearly`
- Paid Copilot access: `copilot_paid` if sold separately, or the same docs entitlement if intentionally bundled
- Academy full access: `academy_all`
- Academy track access: `academy_track:<slug>`
- Legacy compatibility only: `learn_member` as temporary bundle fallback

Contract rule
- Authentication does not imply entitlement.
- Marketing membership language does not replace runtime authorization rules.

## Argo CD workloads

Public baseline targets may include:
- `platform/keycloak`
- `platform/entitlements-api`
- `academy/website`
- `platform/external-secrets`
- `platform/secret-stores`

## Internal boundary

HybridOps may operate additional private Academy delivery components outside the public workload baseline. Those private workloads and rollout notes must not define the public repo contract.

## Anti-drift rules

- Do not add cluster-local databases for identity or entitlement production data.
- Do not make Copilot access control frontend-only; backend entitlement checks remain source of truth.
- Keep public and paid docs indexes separate for Copilot retrieval.
- Do not let internal Academy delivery choices redefine the public workload baseline.
