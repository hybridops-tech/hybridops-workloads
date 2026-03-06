#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/tmp/onprem-learn-stage1/images}"
RKE2_HOSTS="${RKE2_HOSTS:-10.10.0.2 10.10.0.3 10.10.0.4 10.20.0.5 10.20.0.6}"
RKE2_USER="${RKE2_USER:-opsadmin}"
JUMP_HOST="${JUMP_HOST:-root@192.168.0.27}"
SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=5
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

require_cmd ssh
require_file "${OUTPUT_DIR}/academy-website.tar"
require_file "${OUTPUT_DIR}/entitlements-api.tar"

for host in ${RKE2_HOSTS}; do
  ssh "${SSH_OPTS[@]}" "${RKE2_USER}@${host}" 'mkdir -p /tmp/hyops-images'
  cat "${OUTPUT_DIR}/academy-website.tar" | ssh "${SSH_OPTS[@]}" "${RKE2_USER}@${host}" 'cat >/tmp/hyops-images/academy-website.tar && sudo /var/lib/rancher/rke2/bin/ctr -n k8s.io images import /tmp/hyops-images/academy-website.tar'
  cat "${OUTPUT_DIR}/entitlements-api.tar" | ssh "${SSH_OPTS[@]}" "${RKE2_USER}@${host}" 'cat >/tmp/hyops-images/entitlements-api.tar && sudo /var/lib/rancher/rke2/bin/ctr -n k8s.io images import /tmp/hyops-images/entitlements-api.tar'
done

echo "sideloaded local images into RKE2 nodes: ${RKE2_HOSTS}"
