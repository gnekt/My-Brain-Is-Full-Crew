#!/usr/bin/env bash
# =============================================================================
# Validate Build Output
# =============================================================================
# Scans a build output directory for common issues:
#   1. Unresolved template variables ({{VAR_NAME}})
#   2. Invalid YAML frontmatter in .md files
#   3. Invalid TOML in .toml files
#   4. Expected file structure (agents count, skills count)
#   5. Empty files
#
# Usage: ./scripts/validate.sh <build-output-dir>
# Exit: 0 = clean (warnings OK), 1 = errors found
# =============================================================================

set -euo pipefail

# ── Prerequisites ────────────────────────────────────────────────────────────

if ! command -v yq &>/dev/null; then
  echo "yq is required. Install: brew install yq (macOS) or snap install yq (Linux)"
  exit 1
fi

# ── Arguments ────────────────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <build-output-dir>"
  exit 1
fi

BUILD_DIR="$1"

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "[ERROR] Directory does not exist: $BUILD_DIR"
  exit 1
fi

ERROR_COUNT=0

# ── Check 1: Unresolved variables ───────────────────────────────────────────
# Scan .md and .toml files for {{BUILD_VAR}} patterns (must contain underscore).
# Skip .tmpl files, test fixtures, and lines inside fenced code blocks.

while IFS= read -r -d '' file; do
  [[ "$file" == *.tmpl ]] && continue
  [[ "$file" == *tests/fixtures/invalid-*.md ]] && continue

  # Strip code-fenced lines, then scan for unresolved build variables
  while IFS=: read -r line_num line_content; do
    remaining="$line_content"
    while [[ "$remaining" =~ \{\{([A-Z][A-Z_]*_[A-Z_]*)\}\} ]]; do
      var_name="${BASH_REMATCH[1]}"
      match="${BASH_REMATCH[0]}"
      echo "[ERROR] ${file}:${line_num}: unresolved variable {{${var_name}}}"
      ERROR_COUNT=$((ERROR_COUNT + 1))
      remaining="${remaining#*"$match"}"
    done
  done < <(awk 'BEGIN{f=0} /^```/{f=!f; next} !f{print NR":"$0}' "$file" | grep '{{[A-Z_]*_[A-Z_]*}}' 2>/dev/null || true)
done < <(find "$BUILD_DIR" -type f \( -name '*.md' -o -name '*.toml' \) -print0)

# ── Check 2: YAML frontmatter validity ──────────────────────────────────────
# For each .md file starting with ---, extract and validate frontmatter.
# Files without frontmatter are OK.

while IFS= read -r -d '' file; do
  first_line=$(head -n 1 "$file")
  [[ "$first_line" != "---" ]] && continue

  # Extract YAML between first and second --- delimiters
  frontmatter=$(awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print}' "$file")

  if [[ -z "$frontmatter" ]]; then
    continue
  fi

  if ! yq eval '.' - <<< "$frontmatter" &>/dev/null; then
    echo "[ERROR] ${file}: invalid YAML frontmatter"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done < <(find "$BUILD_DIR" -type f -name '*.md' -print0)

# ── Check 3: TOML validity ──────────────────────────────────────────────────

while IFS= read -r -d '' file; do
  if ! yq eval -p toml '.' "$file" &>/dev/null; then
    echo "[ERROR] ${file}: invalid TOML"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done < <(find "$BUILD_DIR" -type f -name '*.toml' -print0)

# ── Check 4: Required file structure ────────────────────────────────────────
# Warn (don't fail) if agent/skill counts are unexpected.

if [[ -d "${BUILD_DIR}/agents" ]]; then
  agent_count=$(find "${BUILD_DIR}/agents" -maxdepth 1 -type f -name '*.md' | wc -l)
  if [[ "$agent_count" -ne 8 ]]; then
    echo "[WARN] agents/ has ${agent_count} files (expected 8)"
  fi
fi

if [[ -d "${BUILD_DIR}/skills" ]]; then
  skill_count=$(find "${BUILD_DIR}/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [[ "$skill_count" -ne 13 ]]; then
    echo "[WARN] skills/ has ${skill_count} subdirectories (expected 13)"
  fi
fi

# ── Check 5: Empty files ────────────────────────────────────────────────────

while IFS= read -r -d '' file; do
  echo "[ERROR] ${file}: empty file (zero bytes)"
  ERROR_COUNT=$((ERROR_COUNT + 1))
done < <(find "$BUILD_DIR" -type f \( -name '*.md' -o -name '*.toml' \) -empty -print0)

# ── Result ───────────────────────────────────────────────────────────────────

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  echo ""
  echo "Validation failed: ${ERROR_COUNT} error(s) found."
  exit 1
fi

echo "Validation passed."
exit 0
