#!/usr/bin/env bash
# purpose: Fill required placeholder values for clusters/onprem-stage1 target.
# maintainer: HybridOps.Studio

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

REPO_URL=""
GIT_REVISION=""
VELERO_CHART_REPO="https://vmware-tanzu.github.io/helm-charts"
LOKI_CHART_REPO="https://grafana.github.io/helm-charts"
VELERO_VERSION=""
LOKI_VERSION=""

usage() {
  cat <<USAGE
Usage: scripts/fill-onprem-stage1.sh \\
  --repo-url <git-url> \\
  --git-revision <git-tag-or-sha> \\
  --velero-version <version> \\
  --loki-version <version> \\
  [--velero-chart-repo <url>] \\
  [--loki-chart-repo <url>]

Fills placeholders for Stage 1 target apps:
- apps/platform/velero/base/application.yaml
- apps/observability/loki/base/application.yaml

Then runs:
- scripts/validate.sh --strict --target onprem-stage1
USAGE
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --repo-url)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --git-revision)
      GIT_REVISION="${2:-}"
      shift 2
      ;;
    --velero-version)
      VELERO_VERSION="${2:-}"
      shift 2
      ;;
    --loki-version)
      LOKI_VERSION="${2:-}"
      shift 2
      ;;
    --velero-chart-repo)
      VELERO_CHART_REPO="${2:-}"
      shift 2
      ;;
    --loki-chart-repo)
      LOKI_CHART_REPO="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$REPO_URL" || -z "$GIT_REVISION" || -z "$VELERO_VERSION" || -z "$LOKI_VERSION" ]]; then
  echo "ERR: missing required arguments" >&2
  usage >&2
  exit 2
fi

VELERO_APP="$ROOT/apps/platform/velero/base/application.yaml"
LOKI_APP="$ROOT/apps/observability/loki/base/application.yaml"

for f in "$VELERO_APP" "$LOKI_APP"; do
  [[ -f "$f" ]] || { echo "ERR: missing file: $f" >&2; exit 1; }
done

escape_sed() {
  printf '%s' "$1" | sed 's/[&|]/\\&/g'
}

replace_placeholder() {
  local file="$1"
  local placeholder="$2"
  local value="$3"
  local esc
  esc="$(escape_sed "$value")"
  sed -i "s|$placeholder|$esc|g" "$file"
}

replace_placeholder "$VELERO_APP" "REPLACE_CHART_REPO_URL" "$VELERO_CHART_REPO"
replace_placeholder "$VELERO_APP" "REPLACE_CHART_VERSION" "$VELERO_VERSION"
replace_placeholder "$VELERO_APP" "REPLACE_GIT_REPO_URL" "$REPO_URL"
replace_placeholder "$VELERO_APP" "REPLACE_GIT_REVISION" "$GIT_REVISION"

replace_placeholder "$LOKI_APP" "REPLACE_CHART_REPO_URL" "$LOKI_CHART_REPO"
replace_placeholder "$LOKI_APP" "REPLACE_CHART_VERSION" "$LOKI_VERSION"
replace_placeholder "$LOKI_APP" "REPLACE_GIT_REPO_URL" "$REPO_URL"
replace_placeholder "$LOKI_APP" "REPLACE_GIT_REVISION" "$GIT_REVISION"

echo "[stage1-fill] substitutions applied"
echo "  repo_url=$REPO_URL"
echo "  git_revision=$GIT_REVISION"
echo "  velero_chart_repo=$VELERO_CHART_REPO"
echo "  velero_version=$VELERO_VERSION"
echo "  loki_chart_repo=$LOKI_CHART_REPO"
echo "  loki_version=$LOKI_VERSION"

echo "[stage1-fill] validating target=onprem-stage1 (strict)"
bash "$ROOT/scripts/validate.sh" --strict --target onprem-stage1

echo "[stage1-fill] done"
