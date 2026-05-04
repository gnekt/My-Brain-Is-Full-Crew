#!/usr/bin/env bash
# =============================================================================
# tests/regression/run.sh — Diff dist/claude-code against the pre-refactor snapshot
# =============================================================================
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_DIR="$SCRIPT_DIR/snapshot"

[[ -d "$SNAPSHOT_DIR" ]] || { echo "no snapshot at $SNAPSHOT_DIR — run take-snapshot.sh before refactoring"; exit 1; }

# Build claude-code
bash "$REPO_DIR/scripts/build.sh" --platform claude-code

DIST_DIR="$REPO_DIR/dist/claude-code"
[[ -d "$DIST_DIR" ]] || { echo "build did not produce $DIST_DIR"; exit 1; }

# Files that exist only at install-time or are generated outside the adapter pipeline.
# These are excluded from both sides of the comparison.
EXCLUDE_PATTERNS=(
  "./.claude/.mbifc-manifest"    # runtime install manifest, not a build artifact
  "./.claude-plugin/plugin.json" # adapter-only artifact, not present in old install
)

# Temp files for comparison (cleaned up on exit)
SNAP_LIST="$(mktemp)"
DIST_LIST="$(mktemp)"
trap 'rm -f "$SNAP_LIST" "$DIST_LIST"' EXIT

# Build a grep exclusion pattern
GREP_EXCLUDE=""
for p in "${EXCLUDE_PATTERNS[@]}"; do
  escaped="${p//./\\.}"   # escape dots for grep
  escaped="${escaped//\//\\\/}"  # escape slashes
  if [[ -z "$GREP_EXCLUDE" ]]; then
    GREP_EXCLUDE="^${escaped}$"
  else
    GREP_EXCLUDE="${GREP_EXCLUDE}|^${escaped}$"
  fi
done

# Compare structure first (excluding known non-comparable files)
echo "── File list comparison ──"
(cd "$SNAPSHOT_DIR" && find . -type f | sort | grep -vE "$GREP_EXCLUDE") > "$SNAP_LIST"
(cd "$DIST_DIR" && find . -type f | sort | grep -vE "$GREP_EXCLUDE") > "$DIST_LIST"
if ! diff -u "$SNAP_LIST" "$DIST_LIST"; then
  echo "FAIL: file lists differ"
  exit 1
fi
echo "File lists match."

# Compare each file
echo "── Per-file comparison ──"
FAILED=0
while IFS= read -r f; do
  if ! diff --strip-trailing-cr -q "$SNAPSHOT_DIR/$f" "$DIST_DIR/$f" >/dev/null 2>&1; then
    echo "DIFF: $f"
    diff --strip-trailing-cr "$SNAPSHOT_DIR/$f" "$DIST_DIR/$f" | head -20
    FAILED=$((FAILED + 1))
  fi
done < "$SNAP_LIST"

[[ $FAILED -eq 0 ]] && echo "PASS: dist matches snapshot" || { echo "FAIL: $FAILED files differ"; exit 1; }
