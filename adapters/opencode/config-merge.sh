#!/usr/bin/env bash
# =============================================================================
# adapters/opencode/config-merge.sh — JSON config merge for opencode.json
# =============================================================================
# Merges a built opencode.json with an existing one in the vault, preserving
# user keys and formatting. Only the "mcp" key is managed; everything else
# belongs to the user.
#
# Sourced by the opencode adapter. Requires jq.
# =============================================================================

# Provide a fallback warn() if scripts/lib.sh has not been sourced yet.
if ! declare -f warn >/dev/null 2>&1; then
  warn() { echo "   ! $*" >&2; }
fi

# oc_detect_indent <file>
# Detects the indentation unit used in a JSON file.
# Returns the number of spaces (2 or 4). Defaults to 2.
oc_detect_indent() {
  local file="$1"
  local indent_str; indent_str="$(awk '/^[[:space:]]+[^[:space:]]/ { match($0, /^[[:space:]]+/); print substr($0, 1, RLENGTH); exit }' "$file")"
  if [[ -z "$indent_str" ]]; then
    echo "2"
    return
  fi
  case "$indent_str" in
    $'\t'*) echo "tab" ;;
    "    "*) echo "4" ;;
    *)       echo "2" ;;
  esac
}

# oc_config_merge <built_file> <existing_file> <output_file>
# Merges built opencode.json into an existing one:
#   - If existing doesn't exist → copy built as-is
#   - If existing is malformed → overwrite with built (with warning)
#   - Otherwise → merge: our mcp entries overwrite same-name, user keys preserved
oc_config_merge() {
  local built="$1" existing="$2" output="$3"

  # Fresh install — no existing file
  if [[ ! -f "$existing" ]]; then
    cp "$built" "$output"
    return 0
  fi

  # Validate existing file is JSON
  if ! jq empty "$existing" 2>/dev/null; then
    warn "Existing opencode.json is malformed — overwriting with built version"
    cp "$built" "$output"
    return 0
  fi

  # Detect indentation from existing file
  local indent; indent="$(oc_detect_indent "$existing")"
  local jq_indent
  case "$indent" in
    tab) jq_indent="--tab" ;;
    4)   jq_indent="--indent 4" ;;
    *)   jq_indent="--indent 2" ;;
  esac

  # Read our managed MCP entries
  local our_mcp; our_mcp="$(jq '.mcp // {}' "$built")"

  # Merge: start with existing, overlay our mcp entries.
  # Always write to a temp file first to support in-place merges (output == existing).
  local tmp; tmp="$(mktemp)"
  # shellcheck disable=SC2086
  jq $jq_indent --argjson our_mcp "$our_mcp" '
    .mcp = ((.mcp // {}) + $our_mcp)
  ' "$existing" > "$tmp"
  mv "$tmp" "$output"
}
