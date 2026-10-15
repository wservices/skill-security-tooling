#!/usr/bin/env bash
# Idempotently install APT packages listed in a manifest, then verify.
#
# Usage:
#   install_from_manifest.sh <packages.txt> [--verify-bin b1,b2,...] [--dry-run]
#
# Manifest format: one package per line; '#' comments and blank lines ignored;
# an inline '# ...' comment after a package name is stripped.
#
# Design:
#   * idempotent: apt-get install is safe to re-run; already-present packages
#     are skipped by APT. A missing package aborts (no partial silent success).
#   * no untrusted curl|bash: installs only from configured APT repos.
#   * requires root OR passwordless sudo (containers run as root; see policy §4).
#   * verifies requested binaries exist on PATH after install.
set -euo pipefail

MANIFEST="${1:-}"
shift || true
VERIFY_BINS=""
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --verify-bin) VERIFY_BINS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$MANIFEST" ] && [ -f "$MANIFEST" ] || { echo "usage: $0 <packages.txt> [--verify-bin a,b] [--dry-run]" >&2; exit 2; }

SUDO=()
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO=(sudo -n); else
    echo "error: not root and no sudo available" >&2; exit 1
  fi
fi

# Parse manifest -> package list (strip inline comments, keep first field).
mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$MANIFEST" | sed 's/#.*//' | awk 'NF{print $1}')
[ "${#PKGS[@]}" -gt 0 ] || { echo "no packages in manifest"; exit 0; }

echo "manifest: $MANIFEST"
echo "packages (${#PKGS[@]}): ${PKGS[*]}"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] would: apt-get update && apt-get install -y --no-install-recommends ${PKGS[*]}"
else
  "${SUDO[@]}" apt-get update -qq
  DEBIAN_FRONTEND=noninteractive "${SUDO[@]}" apt-get install -y --no-install-recommends "${PKGS[@]}"
fi

# Verify requested binaries.
rc=0
if [ -n "$VERIFY_BINS" ]; then
  IFS=',' read -ra BINS <<< "$VERIFY_BINS"
  for b in "${BINS[@]}"; do
    if command -v "$b" >/dev/null 2>&1; then
      echo "OK  $b -> $(command -v "$b")"
    else
      echo "MISSING  $b" >&2; rc=1
    fi
  done
fi
[ "$rc" -eq 0 ] && echo "install+verify complete" || echo "verification failed" >&2
exit "$rc"
