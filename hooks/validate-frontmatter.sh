#!/usr/bin/env bash
# =============================================================================
# Hook: Validate Frontmatter (PostToolUse on Write)
# =============================================================================
# After writing a .md file to the vault, checks that YAML frontmatter is
# properly formed. Obsidian relies on frontmatter for metadata, Dataview
# queries, tags, and search. Broken frontmatter silently breaks all of this.
#
# Checks:
#   1. If the file starts with ---, there must be a closing ---
#   2. No tabs in frontmatter (YAML uses spaces only)
#   3. Colons in values must be quoted
#
# Exit codes:
#   0 = all good
#   1 = warning (issue found, but operation is not blocked)
# =============================================================================

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.args.file_path // ""' 2>/dev/null)

# Skip if we can't extract a path
[[ -z "$FILE" ]] && exit 0

# Only check .md files
[[ "$FILE" == *.md ]] || exit 0

# Skip system files (agents, skills, references)
[[ "$FILE" == *".claude/"* ]] && exit 0

# Skip if file doesn't exist (deleted or moved)
[[ -f "$FILE" ]] || exit 0

# ── Check 1: frontmatter delimiters ─────────────────────────────────────────
FIRST_LINE=$(head -1 "$FILE")
if [[ "$FIRST_LINE" == "---" ]]; then
  # Count opening and closing delimiters (lines that are exactly ---)
  DELIMITER_COUNT=$(grep -c "^---$" "$FILE" 2>/dev/null || echo "0")
  if [[ "$DELIMITER_COUNT" -lt 2 ]]; then
    echo "WARNING: Frontmatter in $(basename "$FILE") is missing the closing '---' delimiter. Obsidian will not parse metadata correctly."
    exit 1
  fi

  # Extract frontmatter content (between first and second ---)
  FRONTMATTER=$(sed -n '2,/^---$/p' "$FILE" | head -n -1)

  # ── Check 2: tabs in frontmatter ────────────────────────────────────────
  TAB_CHAR="$(printf '\t')"
  if echo "$FRONTMATTER" | grep -q "$TAB_CHAR"; then
    TAB_LINES=$(echo "$FRONTMATTER" | grep -n "$TAB_CHAR" | head -3)
    echo "WARNING: Frontmatter in $(basename "$FILE") contains tabs. YAML requires spaces for indentation. Lines with tabs: $TAB_LINES"
    exit 1
  fi

  # ── Check 3: common YAML errors ────────────────────────────────────────
  # Unquoted values with colons (e.g., "title: My Note: Part 2" breaks YAML)
  if echo "$FRONTMATTER" | grep -qE '^[a-zA-Z_-]+: .+: '; then
    PROBLEM_LINES=$(echo "$FRONTMATTER" | grep -nE '^[a-zA-Z_-]+: .+: ' | head -3)
    echo "WARNING: Frontmatter in $(basename "$FILE") may have unquoted colons in values. Wrap the value in quotes to avoid YAML parse errors. Problem lines: $PROBLEM_LINES"
    exit 1
  fi
fi

exit 0
