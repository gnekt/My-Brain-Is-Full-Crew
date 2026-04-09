#!/usr/bin/env bash
# =============================================================================
# Hook: Validate Frontmatter (PostToolUse / AfterTool on Write)
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
# Cross-platform: CREW_PLATFORM_DIR selects the platform directory to skip.
#
# Exit codes:
#   0 = all good
#   1 = warning (issue found, but operation is not blocked)
# =============================================================================

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

PLATFORM_DIR="${CREW_PLATFORM_DIR:-.claude}"
PLATFORM_DIRS=".claude .gemini .codex .opencode"

resolve_platform_dir() {
  if [[ -n "${CREW_PLATFORM_DIR:-}" ]]; then
    printf '%s' "$CREW_PLATFORM_DIR"
    return 0
  fi

  for pd in $PLATFORM_DIRS; do
    if [[ "$FILE" == *"${pd}/"* || "$COMMAND" == *"${pd}/"* ]]; then
      printf '%s' "$pd"
      return 0
    fi
  done

  printf '%s' "$PLATFORM_DIR"
}

ACTIVE_PD="$(resolve_platform_dir)"

validate_markdown_file() {
  local file="$1"
  local first_line delimiter_count frontmatter tab_char tab_lines problem_lines

  [[ -n "$file" ]] || return 0
  [[ "$file" == *.md ]] || return 0

  [[ "$file" == *"${ACTIVE_PD}/"* ]] && return 0

  [[ -f "$file" ]] || return 0

  first_line=$(head -1 "$file")
  if [[ "$first_line" == "---" ]]; then
    delimiter_count=$(grep -c "^---$" "$file" 2>/dev/null || echo "0")
    if [[ "$delimiter_count" -lt 2 ]]; then
      echo "WARNING: Frontmatter in $(basename "$file") is missing the closing '---' delimiter. Obsidian will not parse metadata correctly."
      return 1
    fi

    frontmatter=$(sed -n '2,/^---$/p' "$file" | head -n -1)

    tab_char="$(printf '\t')"
    if echo "$frontmatter" | grep -q "$tab_char"; then
      tab_lines=$(echo "$frontmatter" | grep -n "$tab_char" | head -3)
      echo "WARNING: Frontmatter in $(basename "$file") contains tabs. YAML requires spaces for indentation. Lines with tabs: $tab_lines"
      return 1
    fi

    if echo "$frontmatter" | grep -qE '^[a-zA-Z_-]+: .+: '; then
      problem_lines=$(echo "$frontmatter" | grep -nE '^[a-zA-Z_-]+: .+: ' | head -3)
      echo "WARNING: Frontmatter in $(basename "$file") may have unquoted colons in values. Wrap the value in quotes to avoid YAML parse errors. Problem lines: $problem_lines"
      return 1
    fi
  fi

  return 0
}

extract_markdown_paths_from_command() {
  local command="$1"
  local remaining
  local match
  local candidate

  [[ -n "$command" ]] || return 0

  remaining="$command"
  while [[ "$remaining" =~ (\"([^\"\\]|\\.)+\.md\"|\'([^\'\\]|\\.)+\.md\'|([.]{1,2}/)?([^[:space:]\"\'\|\&\;\<\>\\]|\\.)+\.md) ]]; do
    match="${BASH_REMATCH[1]}"
    candidate="$match"

    if [[ "$candidate" == \"*\" || "$candidate" == \'*\' ]]; then
      candidate="${candidate:1:${#candidate}-2}"
    fi

    candidate="${candidate//\\ / }"
    printf '%s\n' "$candidate"

    remaining="${remaining#*"$match"}"
  done | sort -u
}

if [[ -n "$FILE" ]]; then
  validate_markdown_file "$FILE"
  exit $?
fi

candidate_paths=$(extract_markdown_paths_from_command "$COMMAND")
[[ -n "$candidate_paths" ]] || exit 0

while IFS= read -r candidate; do
  [[ -n "$candidate" ]] || continue
  if ! validate_markdown_file "$candidate"; then
    exit 1
  fi
done <<< "$candidate_paths"

exit 0
