# Moodle

Purpose
- Deliver Academy course workspaces after the Learn/docs stage-1 surface is already live.
- Reuse the existing Keycloak and Entitlements API platform components instead of creating a second identity or billing authority.

Status
- Stage 2 contract defined.
- Public Learn remains the entry surface.
- Moodle becomes the authenticated course-delivery surface only.

Runtime contract
- Namespace: `moodle`
- Argo CD application: `education-moodle`
- Ingress host: overlay-defined, recommended pattern `learn-lms.<domain>`
- Database: external PostgreSQL read-write endpoint
- DR database endpoint: optional read-only replica
- File state: external object storage for `moodledata`

Production state rule
- Do not use chart-managed database state for production.
- Do not use cluster-local PVs as the authoritative `moodledata` store.

Authoritative config surface
- `base/values.yaml`
- `base/keycloak-client.template.json`

SSO contract

Moodle side
- Use Moodle's OpenID Connect login plugin: `auth_oidc`
- Configure the provider through Moodle's OAuth 2 / OpenID Connect service flow
- Provider display name: `HybridOps SSO`
- Login flow: `Authorization Request`
- Allow first-login account creation so Academy users can be provisioned on demand
- Map the following claims:
  - `preferred_username` -> username
  - `email` -> email
  - `given_name` -> firstname
  - `family_name` -> lastname
  - `sub` -> `idnumber`

Keycloak side
- Client ID: `hyops-moodle`
- Access type: confidential client
- Standard flow: enabled
- Direct access grants: disabled
- Implicit flow: disabled
- Service accounts: disabled
- Redirect URI: `https://<moodle-host>/admin/oauth2callback.php`
- Base / root URL: `https://<moodle-host>/`
- Template: `base/keycloak-client.template.json`

Anti-drift rule
- Do not reuse the Learn client (`hyops-learn`) for Moodle.
- Learn and Moodle are different relying parties with different redirect and logout behavior.

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
2. Wire external PostgreSQL and object storage.
3. Ensure the selected Moodle image/chart includes `auth_oidc`.
4. Create the Keycloak `hyops-moodle` client from the tracked template.
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
