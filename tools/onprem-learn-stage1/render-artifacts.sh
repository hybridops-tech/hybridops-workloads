#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/onprem-learn-stage1}"
WEBSITE_DIR="${ROOT_DIR}/../hybridops-docs/hybridops.tech"
ENTITLEMENTS_DIR="${ROOT_DIR}/../hybridops-docs/control/backend/entitlements-api"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

rand_b64url() {
  openssl rand -base64 "$1" | tr '+/' '-_' | tr -d '=\n'
}

require_cmd openssl
require_cmd npm
require_cmd tar
require_cmd base64
mkdir -p "$OUTPUT_DIR"

if [[ "${REUSE_EXISTING_ENV:-1}" != "0" && -f "${OUTPUT_DIR}/00-env.sh" ]]; then
  # Reuse previously generated credentials unless the operator explicitly rotates them.
  # shellcheck disable=SC1090
  source "${OUTPUT_DIR}/00-env.sh"
fi

DB_HOST="${DB_HOST_OVERRIDE:-${DB_HOST:-10.21.0.2}}"
DB_PORT="${DB_PORT:-5432}"
DB_SSLMODE="${DB_SSLMODE:-require}"
PATRONI_SUPERUSER_PASSWORD="${PATRONI_SUPERUSER_PASSWORD:-}"

KEYCLOAK_DB_NAME="${KEYCLOAK_DB_NAME:-keycloak}"
KEYCLOAK_DB_USER="${KEYCLOAK_DB_USER:-keycloak}"
KEYCLOAK_DB_PASSWORD="${KEYCLOAK_DB_PASSWORD:-$(rand_b64url 24)}"
KEYCLOAK_ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-$(rand_b64url 24)}"
KEYCLOAK_EVENTS_SHARED_SECRET="${KEYCLOAK_EVENTS_SHARED_SECRET:-$(rand_b64url 32)}"
KEYCLOAK_LOGIN_THEME="${KEYCLOAK_LOGIN_THEME:-keycloak}"
KEYCLOAK_THEME_JAR_PATH="${KEYCLOAK_THEME_JAR_PATH:-}"
DEFAULT_KEYCLOAK_THEME_JAR_PATH="${ROOT_DIR}/apps/platform/keycloak/theme/hybridops-keycloakify/dist_keycloak/hybridops-theme.jar"

if [[ -z "${KEYCLOAK_THEME_JAR_PATH}" && -f "${DEFAULT_KEYCLOAK_THEME_JAR_PATH}" ]]; then
  KEYCLOAK_THEME_JAR_PATH="${DEFAULT_KEYCLOAK_THEME_JAR_PATH}"
fi

if [[ -n "${KEYCLOAK_THEME_JAR_PATH}" && "${KEYCLOAK_LOGIN_THEME}" == "keycloak" ]]; then
  KEYCLOAK_LOGIN_THEME="hybridops"
fi

ENTITLEMENTS_DB_NAME="${ENTITLEMENTS_DB_NAME:-hyops_entitlements}"
ENTITLEMENTS_DB_USER="${ENTITLEMENTS_DB_USER:-hyops_entitlements}"
ENTITLEMENTS_DB_PASSWORD="${ENTITLEMENTS_DB_PASSWORD:-$(rand_b64url 24)}"
ENTITLEMENTS_INTERNAL_API_TOKEN="${ENTITLEMENTS_INTERNAL_API_TOKEN:-$(rand_b64url 32)}"
STRIPE_SECRET_KEY="${STRIPE_SECRET_KEY:-REPLACE_STRIPE_SECRET_KEY}"
STRIPE_WEBHOOK_SECRET="${STRIPE_WEBHOOK_SECRET:-REPLACE_STRIPE_WEBHOOK_SECRET}"

ACADEMY_LEARN_SESSION_SECRET="${ACADEMY_LEARN_SESSION_SECRET:-$(rand_b64url 48)}"
ACADEMY_ENTITLEMENTS_API_TOKEN="${ACADEMY_ENTITLEMENTS_API_TOKEN:-$ENTITLEMENTS_INTERNAL_API_TOKEN}"
ACADEMY_STRIPE_SECRET_KEY="${ACADEMY_STRIPE_SECRET_KEY:-$STRIPE_SECRET_KEY}"
ACADEMY_STRIPE_PRICE_ID="${ACADEMY_STRIPE_PRICE_ID:-}"
ACADEMY_STRIPE_PRICE_ID_NETWORKING="${ACADEMY_STRIPE_PRICE_ID_NETWORKING:-}"
ACADEMY_STRIPE_PRICE_ID_AUTOMATION="${ACADEMY_STRIPE_PRICE_ID_AUTOMATION:-}"
ACADEMY_STRIPE_SANDBOX_CURRENCY="${ACADEMY_STRIPE_SANDBOX_CURRENCY:-gbp}"
ACADEMY_STRIPE_SANDBOX_AMOUNT_CENTS="${ACADEMY_STRIPE_SANDBOX_AMOUNT_CENTS:-500}"
ACADEMY_STRIPE_SANDBOX_INTERVAL="${ACADEMY_STRIPE_SANDBOX_INTERVAL:-month}"
ACADEMY_STRIPE_SANDBOX_PRODUCT_NAME="${ACADEMY_STRIPE_SANDBOX_PRODUCT_NAME:-HybridOps Learn Sandbox Membership}"

WORKLOADS_REPO_URL="${WORKLOADS_REPO_URL:-https://github.com/hybridops-tech/hybridops-workloads.git}"
WORKLOADS_REVISION="${WORKLOADS_REVISION:-main}"
WORKLOADS_TARGET_PATH="${WORKLOADS_TARGET_PATH:-clusters/onprem-learn-stage1}"
ROOT_APP_NAME="${ROOT_APP_NAME:-hyops-onprem-learn-stage1}"
ROOT_APP_NAMESPACE="${ROOT_APP_NAMESPACE:-argocd}"
ROOT_APP_PROJECT="${ROOT_APP_PROJECT:-default}"
ROOT_DESTINATION_NAMESPACE="${ROOT_DESTINATION_NAMESPACE:-argocd}"
DESTINATION_SERVER="${DESTINATION_SERVER:-https://kubernetes.default.svc}"
CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-}"

KEYCLOAK_DB_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${KEYCLOAK_DB_NAME}?sslmode=${DB_SSLMODE}"
ENTITLEMENTS_SCHEMA_DIR="${ROOT_DIR}/../hybridops-docs/control/backend/entitlements-api/sql"
ACADEMY_RUNTIME_ARCHIVE="${OUTPUT_DIR}/academy-website-dist.tgz"
ENTITLEMENTS_RUNTIME_ARCHIVE="${OUTPUT_DIR}/entitlements-api-runtime.tgz"

cat >"${OUTPUT_DIR}/00-env.sh" <<EOF
export DB_HOST='${DB_HOST}'
export DB_PORT='${DB_PORT}'
export DB_SSLMODE='${DB_SSLMODE}'

export KEYCLOAK_DB_NAME='${KEYCLOAK_DB_NAME}'
export KEYCLOAK_DB_USER='${KEYCLOAK_DB_USER}'
export KEYCLOAK_DB_PASSWORD='${KEYCLOAK_DB_PASSWORD}'
export KEYCLOAK_ADMIN_USER='${KEYCLOAK_ADMIN_USER}'
export KEYCLOAK_ADMIN_PASSWORD='${KEYCLOAK_ADMIN_PASSWORD}'
export KEYCLOAK_EVENTS_SHARED_SECRET='${KEYCLOAK_EVENTS_SHARED_SECRET}'
export KEYCLOAK_LOGIN_THEME='${KEYCLOAK_LOGIN_THEME}'
export KEYCLOAK_THEME_JAR_PATH='${KEYCLOAK_THEME_JAR_PATH}'
export KEYCLOAK_DB_URL='${KEYCLOAK_DB_URL}'

export ENTITLEMENTS_DB_NAME='${ENTITLEMENTS_DB_NAME}'
export ENTITLEMENTS_DB_USER='${ENTITLEMENTS_DB_USER}'
export ENTITLEMENTS_DB_PASSWORD='${ENTITLEMENTS_DB_PASSWORD}'
export ENTITLEMENTS_INTERNAL_API_TOKEN='${ENTITLEMENTS_INTERNAL_API_TOKEN}'
export STRIPE_SECRET_KEY='${STRIPE_SECRET_KEY}'
export STRIPE_WEBHOOK_SECRET='${STRIPE_WEBHOOK_SECRET}'

export ACADEMY_LEARN_SESSION_SECRET='${ACADEMY_LEARN_SESSION_SECRET}'
export ACADEMY_ENTITLEMENTS_API_TOKEN='${ACADEMY_ENTITLEMENTS_API_TOKEN}'
export ACADEMY_STRIPE_SECRET_KEY='${ACADEMY_STRIPE_SECRET_KEY}'
export ACADEMY_STRIPE_PRICE_ID='${ACADEMY_STRIPE_PRICE_ID}'
export ACADEMY_STRIPE_PRICE_ID_NETWORKING='${ACADEMY_STRIPE_PRICE_ID_NETWORKING}'
export ACADEMY_STRIPE_PRICE_ID_AUTOMATION='${ACADEMY_STRIPE_PRICE_ID_AUTOMATION}'
export ACADEMY_STRIPE_SANDBOX_CURRENCY='${ACADEMY_STRIPE_SANDBOX_CURRENCY}'
export ACADEMY_STRIPE_SANDBOX_AMOUNT_CENTS='${ACADEMY_STRIPE_SANDBOX_AMOUNT_CENTS}'
export ACADEMY_STRIPE_SANDBOX_INTERVAL='${ACADEMY_STRIPE_SANDBOX_INTERVAL}'
export ACADEMY_STRIPE_SANDBOX_PRODUCT_NAME='${ACADEMY_STRIPE_SANDBOX_PRODUCT_NAME}'

export WORKLOADS_REPO_URL='${WORKLOADS_REPO_URL}'
export WORKLOADS_REVISION='${WORKLOADS_REVISION}'
export WORKLOADS_TARGET_PATH='${WORKLOADS_TARGET_PATH}'
export ROOT_APP_NAME='${ROOT_APP_NAME}'
export ROOT_APP_NAMESPACE='${ROOT_APP_NAMESPACE}'
export ROOT_APP_PROJECT='${ROOT_APP_PROJECT}'
export ROOT_DESTINATION_NAMESPACE='${ROOT_DESTINATION_NAMESPACE}'
export DESTINATION_SERVER='${DESTINATION_SERVER}'
EOF

cat >"${OUTPUT_DIR}/10-create-databases.sql" <<EOF
\set ON_ERROR_STOP on

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${KEYCLOAK_DB_USER}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${KEYCLOAK_DB_USER}', '${KEYCLOAK_DB_PASSWORD}');
  ELSE
    EXECUTE format('ALTER ROLE %I LOGIN PASSWORD %L', '${KEYCLOAK_DB_USER}', '${KEYCLOAK_DB_PASSWORD}');
  END IF;
END
\$\$;

SELECT format('CREATE DATABASE %I OWNER %I', '${KEYCLOAK_DB_NAME}', '${KEYCLOAK_DB_USER}')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${KEYCLOAK_DB_NAME}')
\gexec

ALTER DATABASE "${KEYCLOAK_DB_NAME}" OWNER TO "${KEYCLOAK_DB_USER}";
GRANT ALL PRIVILEGES ON DATABASE "${KEYCLOAK_DB_NAME}" TO "${KEYCLOAK_DB_USER}";

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${ENTITLEMENTS_DB_USER}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${ENTITLEMENTS_DB_USER}', '${ENTITLEMENTS_DB_PASSWORD}');
  ELSE
    EXECUTE format('ALTER ROLE %I LOGIN PASSWORD %L', '${ENTITLEMENTS_DB_USER}', '${ENTITLEMENTS_DB_PASSWORD}');
  END IF;
END
\$\$;

SELECT format('CREATE DATABASE %I OWNER %I', '${ENTITLEMENTS_DB_NAME}', '${ENTITLEMENTS_DB_USER}')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${ENTITLEMENTS_DB_NAME}')
\gexec

ALTER DATABASE "${ENTITLEMENTS_DB_NAME}" OWNER TO "${ENTITLEMENTS_DB_USER}";
GRANT ALL PRIVILEGES ON DATABASE "${ENTITLEMENTS_DB_NAME}" TO "${ENTITLEMENTS_DB_USER}";
EOF

cat >"${OUTPUT_DIR}/10a-repair-entitlements-ownership.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

if [[ -z "\${PATRONI_SUPERUSER_PASSWORD:-}" ]]; then
  echo "PATRONI_SUPERUSER_PASSWORD is required to repair ownership on ${ENTITLEMENTS_DB_NAME}" >&2
  exit 1
fi

PGPASSWORD="\${PATRONI_SUPERUSER_PASSWORD}" \
psql "postgresql://postgres@${DB_HOST}:${DB_PORT}/${ENTITLEMENTS_DB_NAME}?sslmode=${DB_SSLMODE}" <<'SQL'
\set ON_ERROR_STOP on

ALTER SCHEMA public OWNER TO "${ENTITLEMENTS_DB_USER}";
GRANT USAGE, CREATE ON SCHEMA public TO "${ENTITLEMENTS_DB_USER}";

DO \$\$
DECLARE
  obj record;
BEGIN
  FOR obj IN
    SELECT format('%I.%I', schemaname, tablename) AS ident
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tableowner <> '${ENTITLEMENTS_DB_USER}'
  LOOP
    EXECUTE format('ALTER TABLE %s OWNER TO %I', obj.ident, '${ENTITLEMENTS_DB_USER}');
  END LOOP;

  FOR obj IN
    SELECT format('%I.%I', schemaname, sequencename) AS ident
    FROM pg_sequences
    WHERE schemaname = 'public'
      AND sequenceowner <> '${ENTITLEMENTS_DB_USER}'
  LOOP
    EXECUTE format('ALTER SEQUENCE %s OWNER TO %I', obj.ident, '${ENTITLEMENTS_DB_USER}');
  END LOOP;
END
\$\$;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA public TO "${ENTITLEMENTS_DB_USER}";
GRANT USAGE, SELECT, UPDATE
  ON ALL SEQUENCES IN SCHEMA public TO "${ENTITLEMENTS_DB_USER}";
SQL
EOF
chmod +x "${OUTPUT_DIR}/10a-repair-entitlements-ownership.sh"

cat >"${OUTPUT_DIR}/11-apply-entitlements-schema.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
for sql_file in "${ENTITLEMENTS_SCHEMA_DIR}"/*.sql; do
  echo "[entitlements-schema] applying: \${sql_file}"
  psql "postgresql://${ENTITLEMENTS_DB_USER}:${ENTITLEMENTS_DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${ENTITLEMENTS_DB_NAME}?sslmode=${DB_SSLMODE}" -f "\${sql_file}"
done
EOF
chmod +x "${OUTPUT_DIR}/11-apply-entitlements-schema.sh"

cat >"${OUTPUT_DIR}/20-secret-keycloak.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-keycloak-secrets
  namespace: keycloak
type: Opaque
stringData:
  KC_DB_URL: "${KEYCLOAK_DB_URL}"
  KC_DB_USERNAME: "${KEYCLOAK_DB_USER}"
  KC_DB_PASSWORD: "${KEYCLOAK_DB_PASSWORD}"
  KEYCLOAK_ADMIN: "${KEYCLOAK_ADMIN_USER}"
  KEYCLOAK_ADMIN_PASSWORD: "${KEYCLOAK_ADMIN_PASSWORD}"
  KEYCLOAK_EVENTS_SHARED_SECRET: "${KEYCLOAK_EVENTS_SHARED_SECRET}"
  KEYCLOAK_LOGIN_THEME: "${KEYCLOAK_LOGIN_THEME}"
EOF

if [[ -n "${KEYCLOAK_THEME_JAR_PATH}" ]]; then
  if [[ ! -f "${KEYCLOAK_THEME_JAR_PATH}" ]]; then
    echo "KEYCLOAK_THEME_JAR_PATH is set but file was not found: ${KEYCLOAK_THEME_JAR_PATH}" >&2
    exit 1
  fi
  KEYCLOAK_THEME_JAR_B64="$(base64 <"${KEYCLOAK_THEME_JAR_PATH}" | tr -d '\n')"
  cat >"${OUTPUT_DIR}/20a-secret-keycloak-theme.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-keycloak-theme
  namespace: keycloak
type: Opaque
data:
  hybridops-theme.jar: ${KEYCLOAK_THEME_JAR_B64}
EOF
fi

cat >"${OUTPUT_DIR}/21-secret-entitlements.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-entitlements-api-secrets
  namespace: entitlements
type: Opaque
stringData:
  DATABASE_HOST: "${DB_HOST}"
  DATABASE_USER: "${ENTITLEMENTS_DB_USER}"
  DATABASE_PASSWORD: "${ENTITLEMENTS_DB_PASSWORD}"
  INTERNAL_API_TOKEN: "${ENTITLEMENTS_INTERNAL_API_TOKEN}"
  STRIPE_SECRET_KEY: "${STRIPE_SECRET_KEY}"
  STRIPE_WEBHOOK_SECRET: "${STRIPE_WEBHOOK_SECRET}"
  KEYCLOAK_EVENTS_SHARED_SECRET: "${KEYCLOAK_EVENTS_SHARED_SECRET}"
EOF

cat >"${OUTPUT_DIR}/22-secret-academy.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: academy-website-secrets
  namespace: academy
type: Opaque
stringData:
  LEARN_SESSION_SECRET: "${ACADEMY_LEARN_SESSION_SECRET}"
  ENTITLEMENTS_API_TOKEN: "${ACADEMY_ENTITLEMENTS_API_TOKEN}"
  STRIPE_SECRET_KEY: "${ACADEMY_STRIPE_SECRET_KEY}"
  STRIPE_PRICE_ID: "${ACADEMY_STRIPE_PRICE_ID}"
  STRIPE_PRICE_ID_NETWORKING: "${ACADEMY_STRIPE_PRICE_ID_NETWORKING}"
  STRIPE_PRICE_ID_AUTOMATION: "${ACADEMY_STRIPE_PRICE_ID_AUTOMATION}"
  STRIPE_SANDBOX_CURRENCY: "${ACADEMY_STRIPE_SANDBOX_CURRENCY}"
  STRIPE_SANDBOX_AMOUNT_CENTS: "${ACADEMY_STRIPE_SANDBOX_AMOUNT_CENTS}"
  STRIPE_SANDBOX_INTERVAL: "${ACADEMY_STRIPE_SANDBOX_INTERVAL}"
  STRIPE_SANDBOX_PRODUCT_NAME: "${ACADEMY_STRIPE_SANDBOX_PRODUCT_NAME}"
EOF

(
  cd "${WEBSITE_DIR}"
  npm run build
  tar -czf "${ACADEMY_RUNTIME_ARCHIVE}" dist package.json package-lock.json
)

(
  cd "${ENTITLEMENTS_DIR}"
  tar -czf "${ENTITLEMENTS_RUNTIME_ARCHIVE}" package.json src sql
)

ACADEMY_RUNTIME_B64="$(base64 <"${ACADEMY_RUNTIME_ARCHIVE}" | tr -d '\n')"
ENTITLEMENTS_RUNTIME_B64="$(base64 <"${ENTITLEMENTS_RUNTIME_ARCHIVE}" | tr -d '\n')"

cat >"${OUTPUT_DIR}/23-secret-entitlements-runtime.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-entitlements-api-runtime
  namespace: entitlements
type: Opaque
data:
  app.tgz: ${ENTITLEMENTS_RUNTIME_B64}
EOF

cat >"${OUTPUT_DIR}/24-secret-academy-runtime.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: academy-website-runtime
  namespace: academy
type: Opaque
data:
  dist.tgz: ${ACADEMY_RUNTIME_B64}
EOF

cat >"${OUTPUT_DIR}/30-argocd-root-application.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${ROOT_APP_NAME}
  namespace: ${ROOT_APP_NAMESPACE}
spec:
  project: ${ROOT_APP_PROJECT}
  destination:
    server: ${DESTINATION_SERVER}
    namespace: ${ROOT_DESTINATION_NAMESPACE}
  source:
    repoURL: ${WORKLOADS_REPO_URL}
    targetRevision: ${WORKLOADS_REVISION}
    path: ${WORKLOADS_TARGET_PATH}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN}" ]]; then
cat >"${OUTPUT_DIR}/25-secret-cloudflared-tunnel.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-cloudflared-tunnel-secrets
  namespace: cloudflare-tunnel
type: Opaque
stringData:
  TUNNEL_TOKEN: "${CLOUDFLARE_TUNNEL_TOKEN}"
EOF
else
  rm -f "${OUTPUT_DIR}/25-secret-cloudflared-tunnel.yaml"
fi

cat >"${OUTPUT_DIR}/31-cloudflare-public-hostnames.md" <<EOF
# Cloudflare Tunnel Public Hostnames

Use a remotely-managed Cloudflare Tunnel and map these public hostnames:

- \`auth.hybridops.tech\` -> \`http://platform-keycloak.keycloak.svc.cluster.local:80\`
- \`learn.hybridops.tech\` -> \`http://academy-website.academy.svc.cluster.local:80\`
- \`entitlements.hybridops.tech\` -> \`http://platform-entitlements-api.entitlements.svc.cluster.local:8080\`

Notes
- The current RKE2 ingress addresses are private \`10.10.0.x\`, so public DNS alone is not sufficient.
- Cloudflare Tunnel removes the need for public NAT rules to these runtime services.
- Public/docs static hosting remains on Cloudflare-hosted surfaces outside the cluster.
EOF

cat >"${OUTPUT_DIR}/README.md" <<EOF
# On-Prem Learn Stage 1 Bootstrap Artifacts

Generated output directory: \`${OUTPUT_DIR}\`

Credential reuse
- By default, rerunning this script reuses the existing \`00-env.sh\` values in \`${OUTPUT_DIR}\`.
- To rotate the generated credentials, delete \`${OUTPUT_DIR}/00-env.sh\` first or run with \`REUSE_EXISTING_ENV=0\`.
- To keep the current credentials but point at a different PostgreSQL endpoint, rerun with \`DB_HOST_OVERRIDE=<new-host>\`.

Load the generated environment first:

\`\`\`bash
source "${OUTPUT_DIR}/00-env.sh"
\`\`\`

Before step 2, ensure the Patroni superuser password is available in your shell:

\`\`\`bash
export PATRONI_SUPERUSER_PASSWORD='...'
\`\`\`

1. Create or update the external PostgreSQL roles and databases:

\`\`\`bash
psql "postgresql://postgres@${DB_HOST}:${DB_PORT}/postgres?sslmode=${DB_SSLMODE}" -f "${OUTPUT_DIR}/10-create-databases.sql"
\`\`\`

2. Normalize entitlements ownership and grants on an existing database:

\`\`\`bash
"${OUTPUT_DIR}/10a-repair-entitlements-ownership.sh"
\`\`\`

3. Apply the entitlements schema:

\`\`\`bash
"${OUTPUT_DIR}/11-apply-entitlements-schema.sh"
\`\`\`

4. Apply the Kubernetes Secrets:

\`\`\`bash
kubectl apply -f "${OUTPUT_DIR}/20-secret-keycloak.yaml"
if [[ -f "${OUTPUT_DIR}/20a-secret-keycloak-theme.yaml" ]]; then
  kubectl -n keycloak delete secret platform-keycloak-theme --ignore-not-found
  kubectl create -f "${OUTPUT_DIR}/20a-secret-keycloak-theme.yaml"
fi
kubectl apply -f "${OUTPUT_DIR}/21-secret-entitlements.yaml"
kubectl apply -f "${OUTPUT_DIR}/22-secret-academy.yaml"
kubectl apply -f "${OUTPUT_DIR}/23-secret-entitlements-runtime.yaml"
kubectl apply -f "${OUTPUT_DIR}/24-secret-academy-runtime.yaml"
\`\`\`

5. Choose one deployment path:

- GitOps after push:

\`\`\`bash
kubectl apply -f "${OUTPUT_DIR}/30-argocd-root-application.yaml"
\`\`\`

- Direct dev apply before push:

\`\`\`bash
"${ROOT_DIR}/tools/onprem-learn-stage1/apply-dev-direct.sh"
\`\`\`

5. Optional Cloudflare Tunnel secret render:

\`\`\`bash
CLOUDFLARE_TUNNEL_TOKEN='<token from Cloudflare Zero Trust tunnel>' "${ROOT_DIR}/tools/onprem-learn-stage1/render-artifacts.sh"
\`\`\`

If you provide the token, the script renders:
- \`${OUTPUT_DIR}/25-secret-cloudflared-tunnel.yaml\`
- \`${OUTPUT_DIR}/31-cloudflare-public-hostnames.md\`

6. Optional local image path if you prefer published/sideloaded app images instead of runtime payload Secrets:

\`\`\`bash
"${ROOT_DIR}/tools/onprem-learn-stage1/build-local-images.sh"
"${ROOT_DIR}/tools/onprem-learn-stage1/sideload-rke2-images.sh"
\`\`\`
EOF

echo "rendered bootstrap artifacts into ${OUTPUT_DIR}"
