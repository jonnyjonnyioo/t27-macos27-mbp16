#!/usr/bin/env bash
# verify.sh — check every published file against MANIFEST-PUBLIC.sha256.
#
# Usage: TOOLS/verify.sh
#
# Exits 0 when every listed file exists and matches its recorded SHA-256,
# 1 when anything is missing or changed.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 1
cd "$ROOT" || exit 1

MANIFEST=MANIFEST-PUBLIC.sha256
[ -f "$MANIFEST" ] || { echo "error: $MANIFEST not found in $ROOT"; exit 1; }

if command -v shasum >/dev/null 2>&1; then
  SHA="shasum -a 256"
else
  SHA="sha256sum"
fi

ok=0
bad=0
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  want=${line%%  *}
  path=${line#*  }
  if [ ! -f "$path" ]; then
    echo "MISSING  $path"
    bad=$((bad + 1))
    continue
  fi
  got=$($SHA "$path" | awk '{print $1}')
  if [ "$got" = "$want" ]; then
    ok=$((ok + 1))
  else
    echo "CHANGED  $path"
    bad=$((bad + 1))
  fi
done < "$MANIFEST"

echo "verified=$ok failed=$bad"
[ "$bad" -eq 0 ]
