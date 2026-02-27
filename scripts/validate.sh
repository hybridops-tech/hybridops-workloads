#!/usr/bin/env bash
# purpose: Lightweight validation for workload repo hygiene and cluster app wiring.
# maintainer: HybridOps.Studio

# Re-exec under bash when invoked via sh (script uses bash features).
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STRICT=0
TARGET="onprem"

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --strict)
      STRICT=1
      shift
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<USAGE
Usage: scripts/validate.sh [--strict] [--target <name>]

Checks:
- no .DS_Store files
- clusters/<target>/kustomization.yaml resources exist
- clusters/<target>/apps.yaml matches kustomization resources
- (strict) no unresolved REPLACE_* placeholders in apps/ and clusters/
USAGE
      exit 0
      ;;
    *)
      echo "ERR: unknown option: $1" >&2
      exit 2
      ;;
  esac
done

CLUSTER_DIR="$ROOT/clusters/$TARGET"
KUSTOMIZATION="$CLUSTER_DIR/kustomization.yaml"
APPS_INDEX="$CLUSTER_DIR/apps.yaml"

fail=0

err() {
  echo "ERR: $*" >&2
  fail=1
}

warn() {
  echo "WARN: $*" >&2
}

info() {
  echo "[validate] $*"
}

[[ -f "$KUSTOMIZATION" ]] || {
  echo "ERR: missing file: $KUSTOMIZATION" >&2
  exit 1
}
[[ -f "$APPS_INDEX" ]] || {
  echo "ERR: missing file: $APPS_INDEX" >&2
  exit 1
}

ds_files=()
while IFS= read -r _f; do
  ds_files+=("$_f")
done < <(find "$ROOT" -type f -name ".DS_Store" | sort)
if (( ${#ds_files[@]} > 0 )); then
  err "found .DS_Store files"
  printf '  - %s\n' "${ds_files[@]}" >&2
fi

resources_raw=()
while IFS= read -r _r; do
  resources_raw+=("$_r")
done < <(
  awk '
    /^resources:[[:space:]]*$/ { in_resources=1; next }
    in_resources && /^[[:space:]]*-[[:space:]]+/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]+/, "", line)
      print line
      next
    }
    in_resources && $0 !~ /^[[:space:]]*$/ { in_resources=0 }
  ' "$KUSTOMIZATION"
)

if (( ${#resources_raw[@]} == 0 )); then
  err "no resources found in $KUSTOMIZATION"
fi

resources_tmp="$(mktemp)"
apps_tmp="$(mktemp)"
trap 'rm -f "$resources_tmp" "$apps_tmp"' EXIT

for rel in "${resources_raw[@]}"; do
  [[ -n "$rel" ]] || continue
  if [[ "$rel" =~ ^\.\./\.\./apps/([^/]+)/([^/]+)/overlays/([^/]+)$ ]]; then
    app_ref="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    overlay_target="${BASH_REMATCH[3]}"
    [[ "$overlay_target" == "$TARGET" ]] || err "resource target mismatch in $KUSTOMIZATION: $rel"
    full_path="$CLUSTER_DIR/$rel"
    [[ -d "$full_path" ]] || err "resource path does not exist: $rel"
    printf '%s\n' "$app_ref" >> "$resources_tmp"
  else
    err "unsupported resource path format in $KUSTOMIZATION: $rel"
  fi
done

awk '
  /^[[:space:]]*apps:[[:space:]]*$/ { in_apps=1; next }
  in_apps && /^[[:space:]]*-[[:space:]]+/ {
    line=$0
    sub(/^[[:space:]]*-[[:space:]]+/, "", line)
    print line
    next
  }
  in_apps && $0 !~ /^[[:space:]]*$/ { in_apps=0 }
' "$APPS_INDEX" | sed '/^[[:space:]]*$/d' > "$apps_tmp"

if [[ ! -s "$apps_tmp" ]]; then
  err "no app entries found in $APPS_INDEX"
fi

sort -u -o "$resources_tmp" "$resources_tmp"
sort -u -o "$apps_tmp" "$apps_tmp"

if ! diff -u "$resources_tmp" "$apps_tmp" >/dev/null; then
  err "apps index mismatch: $APPS_INDEX does not match $KUSTOMIZATION"
  echo "[validate] expected apps from kustomization:" >&2
  sed 's/^/  - /' "$resources_tmp" >&2
  echo "[validate] apps listed in apps.yaml:" >&2
  sed 's/^/  - /' "$apps_tmp" >&2
fi

placeholders="$({ rg -n 'REPLACE_[A-Z0-9_]+' "$ROOT/apps" "$ROOT/clusters" || true; } | awk -F: '$0 !~ /^[^:]+:[0-9]+:[[:space:]]*#/ {print}')"
if [[ -n "$placeholders" ]]; then
  if [[ "$STRICT" == "1" ]]; then
    err "unresolved REPLACE_* placeholders found (strict mode)"
    printf '%s\n' "$placeholders" >&2
  else
    warn "unresolved REPLACE_* placeholders detected (allowed in non-strict mode)"
  fi
fi

if [[ "$fail" != "0" ]]; then
  exit 1
fi

info "ok: target=$TARGET strict=$STRICT"
