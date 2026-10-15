#!/usr/bin/env bash
# Verify a set of CLI tools are present and report versions. Read-only.
#
# Usage:
#   verify_tools.sh bin1 bin2 ...
#   verify_tools.sh --from-file verify.txt     # one binary name per line
#
# Exit 0 if all present, 1 if any missing. Prints a table.
set -euo pipefail

BINS=()
if [ "${1:-}" = "--from-file" ]; then
  [ -f "${2:-}" ] || { echo "file not found: ${2:-}" >&2; exit 2; }
  mapfile -t BINS < <(grep -vE '^\s*(#|$)' "$2" | awk 'NF{print $1}')
else
  BINS=("$@")
fi
[ "${#BINS[@]}" -gt 0 ] || { echo "usage: $0 bin1 bin2 ... | --from-file verify.txt" >&2; exit 2; }

missing=0
printf '%-18s %-8s %s\n' "TOOL" "STATUS" "PATH / VERSION"
for b in "${BINS[@]}"; do
  if path="$(command -v "$b" 2>/dev/null)"; then
    ver="$("$b" --version 2>/dev/null | head -1 || true)"
    printf '%-18s %-8s %s\n' "$b" "OK" "${path} ${ver:+| $ver}"
  else
    printf '%-18s %-8s %s\n' "$b" "MISSING" "-"
    missing=$((missing + 1))
  fi
done

echo
if [ "$missing" -eq 0 ]; then echo "all ${#BINS[@]} tools present"; else
  echo "$missing/${#BINS[@]} tools missing" >&2; exit 1
fi
