#!/usr/bin/env bash
# rebuild-public.sh — re-derive this public tree from a private T27 tree.
#
# Usage: TOOLS/rebuild-public.sh /path/to/private/T27 [outdir]
#        (default outdir: ./rebuild, removed and recreated on each run)
#
# The canonical restore of what is published here is `git clone`: that returns
# the exact bytes, byte for byte. This script covers the other case — the
# private source tree is still present and the sanitized public copy has to be
# produced again from it. It walks MANIFEST-PUBLIC.sha256, copies each path from
# the private tree, applies the same path sanitization, and compares the result
# with the recorded checksum. Files whose sanitization does not reproduce
# exactly are listed as DIFFERS instead of being silently accepted.
set -uo pipefail

SRC=${1:?usage: rebuild-public.sh /path/to/private/T27 [outdir]}
OUT=${2:-./rebuild}

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 1
cd "$ROOT" || exit 1

MANIFEST=MANIFEST-PUBLIC.sha256
[ -f "$MANIFEST" ] || { echo "error: $MANIFEST not found in $ROOT"; exit 1; }

if command -v shasum >/dev/null 2>&1; then
  SHA="shasum -a 256"
else
  SHA="sha256sum"
fi

rm -rf "$OUT"
mkdir -p "$OUT" || exit 1

sanitize() {
  sed -E \
    -e 's|/Users/IMAC/Desktop/HAO-PROJECT|<PROJECT_ROOT>|g' \
    -e 's|<PROJECT_ROOT>/T27/|<PROJECT_ROOT>/|g' \
    -e 's|/Users/IMAC/Desktop|<DESKTOP>|g' \
    -e 's|/Users/IMAC|<HOME>|g' \
    -e 's|/System/Volumes|/System<VOLUME>|g' \
    -e 's|/private/tmp/hao91-sys27|<TARGET_ROOT>|g' \
    -e 's|/private/tmp/hao93-kdk25|<DONOR_VOLUME>|g' \
    -e 's|/private/tmp|<TMP>|g' \
    -e 's|/Volumes/msu-target-X87eLfva|<DONOR_VOLUME>|g' \
    -e 's|msu-target-X87eLfva|<DONOR_VOLUME>|g' \
    -e 's|/Volumes/|<VOLUME>/|g' \
    -e 's|SESSION-HAO-[0-9]+|<SESSION>|g' \
    "$1"
}

# Where a published path comes from. Public-only files (README, RESTORE,
# .gitignore, TOOLS/) live in this repository itself, and AGENT-AMD/qwen-loop.sh
# was made path-independent by hand when it was published; the raw evidence tree
# was stored under AGENT-AMD/.tmp/ in the private copy; everything else keeps its
# relative path.
source_for() {
  case "$1" in
    README.md|RESTORE.md|EXCLUDED-FILES.tsv|.gitignore|TOOLS/*|AGENT-AMD/qwen-loop.sh) printf '%s/%s' "$ROOT" "$1" ;;
    # one evidence filename carried the donor volume identifier; renamed here
    AGENT-AMD/evidence/r185/vol_donor-volume.tsv) printf '%s/AGENT-AMD/.tmp/r185/vol_msu-target-X87eLfva.tsv' "$SRC" ;;
    # authored tooling that lived in .tmp in the private tree
    AGENT-AMD/scan_iokit_calls.py) printf '%s/AGENT-AMD/.tmp/scan_iokit_calls.py' "$SRC" ;;
    AGENT-AMD/evidence/*) printf '%s/AGENT-AMD/.tmp/%s' "$SRC" "${1#AGENT-AMD/evidence/}" ;;
    *) printf '%s/%s' "$SRC" "$1" ;;
  esac
}

ok=0
diff=0
missing=0
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  want=${line%%  *}
  path=${line#*  }
  src=$(source_for "$path")

  if [ ! -f "$src" ]; then
    echo "MISSING  $path"
    missing=$((missing + 1))
    continue
  fi

  mkdir -p "$OUT/$(dirname "$path")"
  case "$path" in
    README.md|RESTORE.md|EXCLUDED-FILES.tsv|.gitignore|TOOLS/*|AGENT-AMD/qwen-loop.sh) cp "$src" "$OUT/$path" ;;
    *) sanitize "$src" > "$OUT/$path" ;;
  esac

  got=$($SHA "$OUT/$path" | awk '{print $1}')
  if [ "$got" = "$want" ]; then
    ok=$((ok + 1))
  else
    echo "DIFFERS  $path"
    diff=$((diff + 1))
  fi
done < "$MANIFEST"

echo
echo "identical=$ok differing=$diff missing_source=$missing -> $OUT"
echo "A byte-identical copy is always available with: git clone <this repository>"
[ "$missing" -eq 0 ] && [ "$diff" -eq 0 ]
