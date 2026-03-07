#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/tmp/onprem-learn-stage1}"
RKE2_HOST="${RKE2_HOST:-10.10.0.2}"
RKE2_USER="${RKE2_USER:-opsadmin}"
JUMP_HOST="${JUMP_HOST:-root@192.168.0.27}"
SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout=5
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o "ProxyCommand=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${JUMP_HOST} nc %h %p"
)

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

require_file() {
  [[ -f "$1" ]] || {
    echo "missing required file: $1" >&2
    exit 1
  }
}

ssh_remote() {
  ssh "${SSH_OPTS[@]}" "${RKE2_USER}@${RKE2_HOST}" "$@"
}

kubectl_remote() {
  ssh_remote "sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml $*"
}

require_cmd kubectl
require_cmd ssh
require_file "${ARTIFACTS_DIR}/20-secret-keycloak.yaml"
require_file "${ARTIFACTS_DIR}/21-secret-entitlements.yaml"
require_file "${ARTIFACTS_DIR}/22-secret-academy.yaml"
require_file "${ARTIFACTS_DIR}/23-secret-entitlements-runtime.yaml"
require_file "${ARTIFACTS_DIR}/24-secret-academy-runtime.yaml"

kubectl_remote "create namespace keycloak --dry-run=client -o yaml" | kubectl_remote "apply -f -"
kubectl_remote "create namespace entitlements --dry-run=client -o yaml" | kubectl_remote "apply -f -"
kubectl_remote "create namespace academy --dry-run=client -o yaml" | kubectl_remote "apply -f -"

kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/20-secret-keycloak.yaml"
if [[ -f "${ARTIFACTS_DIR}/20a-secret-keycloak-theme.yaml" ]]; then
  # Avoid "RequestEntityTooLarge" from apply last-applied annotation duplication on large theme jars.
  kubectl_remote "-n keycloak delete secret platform-keycloak-theme --ignore-not-found"
  kubectl_remote "create -f -" < "${ARTIFACTS_DIR}/20a-secret-keycloak-theme.yaml"
fi
kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/21-secret-entitlements.yaml"
kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/22-secret-academy.yaml"
kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/23-secret-entitlements-runtime.yaml"
kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/24-secret-academy-runtime.yaml"

kubectl kustomize "${ROOT_DIR}/apps/platform/keycloak/manifests/overlays/onprem" | kubectl_remote "-n keycloak apply -f -"
kubectl kustomize "${ROOT_DIR}/apps/platform/entitlements-api/manifests/overlays/onprem" | kubectl_remote "-n entitlements apply -f -"
kubectl kustomize "${ROOT_DIR}/apps/academy/website/manifests/overlays/onprem" | kubectl_remote "apply -f -"

kubectl_remote "-n keycloak rollout restart deployment/platform-keycloak"
kubectl_remote "-n keycloak rollout status deployment/platform-keycloak --timeout=300s"
kubectl_remote "-n entitlements rollout restart deployment/platform-entitlements-api"
kubectl_remote "-n entitlements rollout status deployment/platform-entitlements-api --timeout=300s"
kubectl_remote "-n academy rollout restart deployment/academy-website"
kubectl_remote "-n academy rollout status deployment/academy-website --timeout=300s"

if [[ -f "${ARTIFACTS_DIR}/25-secret-cloudflared-tunnel.yaml" ]]; then
  kubectl_remote "create namespace cloudflare-tunnel --dry-run=client -o yaml" | kubectl_remote "apply -f -"
  kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/25-secret-cloudflared-tunnel.yaml"
  kubectl kustomize "${ROOT_DIR}/apps/platform/cloudflared-tunnel/manifests/overlays/onprem" | kubectl_remote "apply -f -"
fi

echo "applied keycloak, entitlements, and academy workloads to the dev cluster via ${JUMP_HOST}"
