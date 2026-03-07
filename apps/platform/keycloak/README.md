# Platform Keycloak

Purpose
- Host the HybridOps OIDC realm for Learn sign-in at `auth.hybridops.tech`.
- Keep Keycloak stateless in-cluster by using an external PostgreSQL database.

Runtime contract
- Namespace: `keycloak`
- Service: `platform-keycloak`
- Ingress host: `auth.hybridops.tech`
- Image: `quay.io/keycloak/keycloak:24.0`
- Declarative realm sync: `adorsys/keycloak-config-cli` (`CronJob`)
- Realm config source: `manifests/base/realm-config.json`

Required secret
- `platform-keycloak-secrets`
  - `KC_DB_URL`
  - `KC_DB_USERNAME`
  - `KC_DB_PASSWORD`
  - `KEYCLOAK_ADMIN`
  - `KEYCLOAK_ADMIN_PASSWORD`
  - `KEYCLOAK_EVENTS_SHARED_SECRET`
  - `KEYCLOAK_LOGIN_THEME` (`keycloak` default, set `hybridops` when your Keycloakify jar is installed)

Optional secret
- `platform-keycloak-theme`
  - key: `hybridops-theme.jar`
  - Purpose: mount a Keycloakify-built theme jar without rebuilding the Keycloak image.

Non-secret config
- `platform-keycloak-env` ConfigMap is generated from manifests and sets:
  - `KC_DB=postgres`
  - `KC_HTTP_ENABLED=true`
  - `KC_HEALTH_ENABLED=true`
  - `KC_METRICS_ENABLED=true`
  - `KC_PROXY_HEADERS=xforwarded`
  - `KC_HOSTNAME=auth.hybridops.tech`
  - `KC_HOSTNAME_STRICT=true`
  - `KEYCLOAK_EVENTS_EXTENSION_JAR_URL=https://repo1.maven.org/maven2/io/phasetwo/keycloak/keycloak-events/0.29/keycloak-events-0.29.jar`

Notes
- The deployment now installs providers during pod init:
  - `keycloak-events` extension jar (HTTP sender listener)
  - optional `hybridops-theme.jar` from `platform-keycloak-theme`
- Realm state is reconciled against `realm-config.json` through the in-cluster config-cli jobs.
- To force an immediate sync (outside the cron schedule), run:
  - `kubectl -n keycloak create job --from=cronjob/platform-keycloak-realm-sync platform-keycloak-realm-sync-manual-$(date +%s)`
- `realm-config.json` enables `ext-event-http-sender` to post signed events to:
  - `http://platform-entitlements-api.entitlements.svc.cluster.local:8080/webhooks/keycloak`
- The current stage-1 realm uses the `hyops-learn` public PKCE client and the `learn_member` / `learn_admin` realm roles.
- In the explicit entitlement model, `learn_member` is treated as an Academy convenience role only; docs and Copilot authorization should read explicit entitlements (`docs_paid*`, `copilot_paid`) instead.
- Keep the Keycloak database outside the cluster so the workload can be rebuilt without losing identity state.

Keycloakify quick path
- Build the tracked HybridOps theme jar:
  - `cd apps/platform/keycloak/theme/hybridops-keycloakify`
  - `./scripts/build-keycloak-theme.sh`
  - output: `dist_keycloak/hybridops-theme.jar`
- Render artifacts with the jar path:
  - `KEYCLOAK_THEME_JAR_PATH=/absolute/path/to/hybridops-theme.jar KEYCLOAK_LOGIN_THEME=hybridops ./tools/onprem-learn-stage1/render-artifacts.sh`
- Apply the generated secret (`20a-secret-keycloak-theme.yaml`) and restart `platform-keycloak`.
