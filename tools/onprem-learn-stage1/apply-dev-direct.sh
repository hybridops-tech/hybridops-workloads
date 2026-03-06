#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.hybridops/envs/dev/state/kubeconfigs/rke2.yaml}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/tmp/onprem-learn-stage1}"

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

require_cmd kubectl
require_file "${KUBECONFIG_PATH}"
require_file "${ARTIFACTS_DIR}/20-secret-keycloak.yaml"
require_file "${ARTIFACTS_DIR}/21-secret-entitlements.yaml"
require_file "${ARTIFACTS_DIR}/22-secret-academy.yaml"
require_file "${ARTIFACTS_DIR}/23-secret-entitlements-runtime.yaml"
require_file "${ARTIFACTS_DIR}/24-secret-academy-runtime.yaml"

kubectl_cmd() {
  KUBECONFIG="${KUBECONFIG_PATH}" kubectl "$@"
}

kubectl_cmd create namespace keycloak --dry-run=client -o yaml | kubectl_cmd apply -f -
kubectl_cmd create namespace entitlements --dry-run=client -o yaml | kubectl_cmd apply -f -
kubectl_cmd create namespace academy --dry-run=client -o yaml | kubectl_cmd apply -f -

kubectl_cmd apply -f "${ARTIFACTS_DIR}/20-secret-keycloak.yaml"
kubectl_cmd apply -f "${ARTIFACTS_DIR}/21-secret-entitlements.yaml"
kubectl_cmd apply -f "${ARTIFACTS_DIR}/22-secret-academy.yaml"
kubectl_cmd apply -f "${ARTIFACTS_DIR}/23-secret-entitlements-runtime.yaml"
kubectl_cmd apply -f "${ARTIFACTS_DIR}/24-secret-academy-runtime.yaml"

kubectl_cmd -n keycloak apply -k "${ROOT_DIR}/apps/platform/keycloak/manifests/overlays/onprem"
kubectl_cmd -n entitlements apply -k "${ROOT_DIR}/apps/platform/entitlements-api/manifests/overlays/onprem"
kubectl_cmd apply -k "${ROOT_DIR}/apps/academy/website/manifests/overlays/onprem"

if [[ -f "${ARTIFACTS_DIR}/25-secret-cloudflared-tunnel.yaml" ]]; then
  kubectl_cmd create namespace cloudflare-tunnel --dry-run=client -o yaml | kubectl_cmd apply -f -
  kubectl_cmd apply -f "${ARTIFACTS_DIR}/25-secret-cloudflared-tunnel.yaml"
  kubectl_cmd apply -k "${ROOT_DIR}/apps/platform/cloudflared-tunnel/manifests/overlays/onprem"
fi

echo "applied keycloak, entitlements, and academy workloads directly to the dev cluster"
