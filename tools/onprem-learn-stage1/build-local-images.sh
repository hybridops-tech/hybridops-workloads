#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/onprem-learn-stage1/images}"
WEBSITE_TAG="${WEBSITE_TAG:-ghcr.io/hybridops-studio/hybridops-tech:0.1.0}"
ENTITLEMENTS_TAG="${ENTITLEMENTS_TAG:-ghcr.io/hybridops-studio/hyops-entitlements-api:0.1.0}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

require_cmd docker
require_cmd npm
mkdir -p "${OUTPUT_DIR}"

(
  cd "${ROOT_DIR}/../hybridops-docs/hybridops.tech"
  npm run build
  docker build -t "${WEBSITE_TAG}" -f deploy/Dockerfile .
  docker save "${WEBSITE_TAG}" -o "${OUTPUT_DIR}/academy-website.tar"
)

(
  cd "${ROOT_DIR}/../hybridops-docs/control/backend/entitlements-api"
  docker build -t "${ENTITLEMENTS_TAG}" .
  docker save "${ENTITLEMENTS_TAG}" -o "${OUTPUT_DIR}/entitlements-api.tar"
)

echo "built and exported local images into ${OUTPUT_DIR}"
