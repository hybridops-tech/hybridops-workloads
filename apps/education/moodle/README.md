# Moodle

Purpose
- Deliver Academy course workspaces after the Learn/docs stage-1 surface is already live.
- Reuse the existing Keycloak and Entitlements API platform components instead of creating a second identity or billing authority.

Status
- Stage 2 chart and image strategy defined.
- Public Learn remains the entry surface.
- Moodle becomes the authenticated course-delivery surface only.

Runtime contract
- Namespace: `moodle`
- Argo CD application: `education-moodle`
- Helm chart: Bitnami Moodle `28.0.0`
- Chart repo: `https://charts.bitnami.com/bitnami`
- Ingress host: overlay-defined, recommended pattern `learn-lms.<domain>`
- Database: external PostgreSQL read-write endpoint
- DR database endpoint: optional read-only replica
- Runtime image: pre-baked custom image derived from `docker.io/bitnami/moodle:5.0.2-debian-12-r1`
- File state bridge: pre-provisioned claim via `persistence.existingClaim`

Production state rule
- Do not use chart-managed database state for production.
- Do not use default chart-created PVCs as the authoritative production `moodledata` path.

Secrets contract

Authority
- Secret values come from the HyOps runtime vault bundle and external secret authority, not from handwritten Kubernetes Secret YAML kept in Git.
- In steady state, the Kubernetes workload consumes one Secret projected by External Secrets Operator:
  - `education-moodle-secrets`
- The runtime vault is the controller-side seed/cache used to generate or sync the required values before they are persisted to the external authority.

Runtime-vault env keys
- Required:
  - `MOODLE_ADMIN_PASSWORD`
  - `MOODLE_DB_PASSWORD`
  - `MOODLE_OIDC_CLIENT_SECRET`
- Optional:
  - `MOODLE_SMTP_PASSWORD`

HyOps generation/persistence pattern
- Generate missing values with `hyops secrets ensure --env <env> ...`
- Read current values with `hyops secrets show --env <env> ...`
- Persist the Moodle values into the selected external authority before cluster bring-up:
  - preferred on-prem path: `hyops secrets gsm-persist --env <env> --scope education`
- If your authority is external (HashiCorp Vault, GSM, AKV), sync into the runtime vault first; do not bypass the runtime-vault contract for this workload.

Projected Kubernetes Secret shape
- Secret name: `education-moodle-secrets`
- Required keys:
  - `moodle-password`
  - `mariadb-password`
- Optional keys:
  - `smtp-password`
  - `oidc-client-secret`

Anti-drift rule
- Do not split admin password, SMTP password, and external DB password across multiple handwritten Kubernetes secrets.
- One target secret name is the contract unless the chart itself forces a different model.
- The steady-state cluster object must be reconciled by ESO, not by a hand-applied secret manifest.

External database contract
- Moodle follows the same externalized PostgreSQL approach as Keycloak.
- Use the read-write endpoint published by `platform/postgresql-ha`.
- Preferred source:
  - state output `endpoint_target`
- Fallback compatibility outputs:
  - `cluster_vip`
  - `db_host`
  - `pg_host`
- Do not point Moodle at a cluster member IP directly unless you are debugging a broken HA endpoint.

ESO contract
- Backend: GCP Secret Manager on the on-prem platform path, per ADR-0504
- Store ref: `gcp-secret-manager`
- Moodle chart values embed an `ExternalSecret` via `extraDeploy` so the chart release and the projected secret stay coupled
- The Moodle `ExternalSecret` must map:
  - `moodle-password` <- `MOODLE_ADMIN_PASSWORD`
  - `mariadb-password` <- `MOODLE_DB_PASSWORD`
  - `oidc-client-secret` <- `MOODLE_OIDC_CLIENT_SECRET`
  - optional `smtp-password` <- `MOODLE_SMTP_PASSWORD`

Authoritative config surface
- `base/values.yaml`
- `base/keycloak-client.template.json`
- `image/README.md`

SSO contract

Moodle side
- Use Moodle's OpenID Connect login plugin: `auth_oidc`
- Configure the provider through Moodle's OAuth 2 / OpenID Connect service flow
- Provider display name: `HybridOps SSO`
- Login flow: `Authorization Request`
- Allow first-login account creation so Academy users can be provisioned on demand
- Minimum mappings to require:
  - `email` -> email
  - `given_name` -> firstname
  - `family_name` -> lastname
- Stable identifier:
  - keep `sub` as the authoritative external subject
  - map it into `idnumber` only if the selected Moodle/plugin version supports that field mapping cleanly
  - do not make custom username-claim mapping part of the base contract until it is tested end to end

Keycloak side
- Client ID: `academy-moodle`
- Access type: confidential client
- Standard flow: enabled
- Direct access grants: disabled
- Implicit flow: disabled
- Service accounts: disabled
- Redirect URI: `https://<moodle-host>/admin/oauth2callback.php`
- Base / root URL: `https://<moodle-host>/`
- Template: `base/keycloak-client.template.json`

Anti-drift rule
- Do not reuse the Academy web client (`academy-web`) for Moodle.
- Learn and Moodle are different relying parties with different redirect and logout behavior.

Plugin packaging contract
- `auth_oidc` must be present in the Moodle runtime before SSO configuration begins.
- Chosen delivery model:
  - pre-baked Moodle image with the plugin installed
- Tracked image scaffold:
  - `image/Dockerfile.template`
- Chart interaction:
  - `global.security.allowInsecureImages=true` is required because the chosen image is custom, not stock Bitnami
- Do not depend on ad hoc web-admin plugin installation as the production path.

Enrollment sync contract

Authoritative source
- `platform/entitlements-api`

Rules
- Authentication does not grant course access.
- A Moodle user may exist without any course enrollments.
- Only explicit Academy entitlements grant Moodle access:
  - `academy_all`
  - `academy_track:<slug>`
- `learn_member` remains compatibility-only and must not become the long-term Moodle access rule.

Delivery model
- Login-time reconcile: enabled
- Background reconcile: enabled
- Learn remains the commercial and routing surface
- Moodle reflects course availability only

Implementation boundary
- This repo defines the required enrollment-sync contract.
- It does not yet ship the reconciler implementation itself.
- Before go-live, choose and build one delivery path:
  - dedicated sync job
  - service inside the Moodle workload
  - external controller

Canonical track-to-course mapping
- Course shortname must match the canonical Learn track slug:
  - `networking-foundations`
  - `contract-driven-automation`
  - `verification-driven-operations`
  - `platform-services`
  - `ipam-driven-infrastructure`
  - `disaster-recovery-automation`

Compatibility note
- The old Learn alias `evidence-first-operations` remains only for route stability in Learn.
- Moodle should use `verification-driven-operations` as the canonical course shortname.

Bring-up order
1. Set the overlay host and TLS settings.
2. Build and publish the pre-baked Moodle image with `auth_oidc`.
3. Wire external PostgreSQL and the pre-provisioned data claim.
4. Create the Keycloak `academy-moodle` client from the tracked template.
5. Configure the Moodle OIDC service and claim mappings.
6. Create one Moodle course per canonical track shortname.
7. Wire the Entitlements API token and enrollment sync path.
8. Set `ACADEMY_LMS_BASE_URL` in Learn runtime.
9. Validate member launch from Learn workspace, account page, and track detail pages.

Launch contract with Learn
- Learn keeps public discovery and purchase UX.
- When `ACADEMY_LMS_BASE_URL` is unset, members stay on Learn track routes.
- When `ACADEMY_LMS_BASE_URL` is set, member launch switches to Moodle course URLs derived from the per-track course path.

What not to do
- Do not make Moodle the public marketing surface.
- Do not duplicate docs content into Moodle.
- Do not let Moodle become the authority for billing or entitlement state.
- Do not use the stock Bitnami image directly if `auth_oidc` is required for sign-in.
