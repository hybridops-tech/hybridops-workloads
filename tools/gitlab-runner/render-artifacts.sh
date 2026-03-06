#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/tmp/gitlab-runner}"
GITLAB_RUNNER_AUTH_TOKEN="${GITLAB_RUNNER_AUTH_TOKEN:-}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

require_cmd mkdir

if [[ -z "${GITLAB_RUNNER_AUTH_TOKEN}" ]]; then
  echo "GITLAB_RUNNER_AUTH_TOKEN is required" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

cat >"${OUTPUT_DIR}/10-secret-gitlab-runner.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-gitlab-runner-auth
  namespace: ci
type: Opaque
stringData:
  runner-token: "${GITLAB_RUNNER_AUTH_TOKEN}"
  runner-registration-token: ""
EOF

cat >"${OUTPUT_DIR}/README.md" <<EOF
# GitLab Runner Bootstrap Artifacts

Generated output directory: \`${OUTPUT_DIR}\`

1. Create a runner in GitLab first and copy the runner authentication token.
2. Apply the secret:

\`\`\`bash
kubectl apply -f "${OUTPUT_DIR}/10-secret-gitlab-runner.yaml"
\`\`\`

3. Apply the runner app:

\`\`\`bash
kubectl apply -k apps/platform/gitlab-runner/overlays/onprem
\`\`\`
EOF

echo "rendered GitLab runner artifacts into ${OUTPUT_DIR}"
