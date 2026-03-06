# Platform Keycloak

Purpose
- Host the HybridOps OIDC realm for Learn sign-in at `auth.hybridops.tech`.
- Keep Keycloak stateless in-cluster by using an external PostgreSQL database.

Runtime contract
- Namespace: `keycloak`
- Service: `platform-keycloak`
- Ingress host: `auth.hybridops.tech`
- Image: `quay.io/keycloak/keycloak:24.0`
- Realm import: `manifests/base/realm.json`

Required secret
- `platform-keycloak-secrets`
  - `KC_DB_URL`
  - `KC_DB_USERNAME`
  - `KC_DB_PASSWORD`
  - `KEYCLOAK_ADMIN`
  - `KEYCLOAK_ADMIN_PASSWORD`

Non-secret config
- `platform-keycloak-env` ConfigMap is generated from manifests and sets:
  - `KC_DB=postgres`
  - `KC_HTTP_ENABLED=true`
  - `KC_HEALTH_ENABLED=true`
  - `KC_METRICS_ENABLED=true`
  - `KC_PROXY_HEADERS=xforwarded`
  - `KC_HOSTNAME=auth.hybridops.tech`
  - `KC_HOSTNAME_STRICT=true`

Notes
- The deployment starts Keycloak with `--import-realm` and mounts `realm.json` into `/opt/keycloak/data/import`.
- The imported realm uses the `hyops-learn` public PKCE client and the `learn_member` / `learn_admin` realm roles.
- Keep the Keycloak database outside the cluster so the workload can be rebuilt without losing identity state.
