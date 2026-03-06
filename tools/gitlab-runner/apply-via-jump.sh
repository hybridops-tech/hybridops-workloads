#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/tmp/gitlab-runner}"
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
require_file "${ARTIFACTS_DIR}/10-secret-gitlab-runner.yaml"

kubectl_remote "create namespace ci --dry-run=client -o yaml" | kubectl_remote "apply -f -"
kubectl_remote "apply -f -" < "${ARTIFACTS_DIR}/10-secret-gitlab-runner.yaml"
kubectl kustomize "${ROOT_DIR}/apps/platform/gitlab-runner/overlays/onprem" | kubectl_remote "apply -f -"

echo "applied GitLab runner secret and Argo app to the dev cluster via ${JUMP_HOST}"
