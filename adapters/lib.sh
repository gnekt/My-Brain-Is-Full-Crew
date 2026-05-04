#!/usr/bin/env bash
# =============================================================================
# adapters/lib.sh — Shared helpers for framework adapters
# =============================================================================
# Sourced by scripts/build.sh BEFORE the framework-specific adapter.sh.
# Provides vocabulary tables, parsing helpers, filtering, and JSON utilities.
# Do NOT execute directly.
# =============================================================================

# ── Vocabulary constants ─────────────────────────────────────────────────────
# The closed set of capabilities the source frontmatter may declare.
# Adapters consult this list to validate frontmatter before translating.
CAPABILITY_VOCAB="read write edit bash webfetch websearch notebook task todo"

# The closed set of hook event names the source .hook.yaml may declare.
EVENT_VOCAB="before-tool-use after-tool-use on-notification on-session-start on-prompt-submit"

# The closed set of model names the source agents may declare.
MODEL_VOCAB="low mid high"

# ── Path rewriting ───────────────────────────────────────────────────────────

# rewrite_platform_paths <file> <platform_dir> <dispatcher_name>
# Rewrites platform-neutral path references in a text file.
# Source files use .platform/ and DISPATCHER.md as neutral placeholders.
# Each adapter calls this after copying any text file from source to dist,
# passing its platform-specific directory name and dispatcher filename.
rewrite_platform_paths() {
  local file="$1" platform_dir="$2" dispatcher="$3"
  local tmp; tmp="$(mktemp)"
  sed "s|\.platform/|.${platform_dir}/|g; s|DISPATCHER\.md|${dispatcher}|g" "$file" > "$tmp"
  mv "$tmp" "$file"
}

# ── Parsing helpers ──────────────────────────────────────────────────────────

# parse_frontmatter <file> <key>
# Echoes the value of a top-level YAML key from the file's --- ... --- block.
# Returns nothing (empty) if the key is not found.
# Supports scalar values and flat list values; preserves the raw value as-written.
parse_frontmatter() {
  local file="$1" key="$2"
  awk -v key="$key" '
    { sub(/\r$/, "") }
    /^---$/ { fm++; next }
    fm == 1 {
      # Match "key: value" — strip leading whitespace, capture value after first ":"
      sub(/^[[:space:]]+/, "")
      if (match($0, "^" key ":[[:space:]]*")) {
        value = substr($0, RLENGTH + 1)
        sub(/[[:space:]]+$/, "", value)
        print value
        exit
      }
    }
    fm >= 2 { exit }
  ' "$file"
}

# parse_capabilities <agent_file>
# Echoes the agent's capabilities as space-separated tokens.
# Empty output if capabilities is missing or [].
parse_capabilities() {
  local file="$1"
  local raw; raw="$(parse_frontmatter "$file" capabilities)"
  # Strip [ and ] and commas, leaving space-separated tokens
  echo "$raw" | tr -d '[]' | tr ',' ' ' | xargs
}

# should_include <component_file> <framework>
# Exit 0 if the component should be included in the given framework's build.
# Exit 1 if the component's exclude: list contains the framework.
# Supports both frontmatter-delimited files (agents, skills) and plain YAML
# files (hook .yaml) — falls back to a direct key read if no frontmatter found.
should_include() {
  local file="$1" framework="$2"
  local raw; raw="$(parse_frontmatter "$file" exclude)"
  # If parse_frontmatter returned nothing, try reading exclude: as a plain YAML key
  # (hook .yaml files don't have --- delimiters)
  if [[ -z "$raw" ]]; then
    raw="$(awk '/^exclude:/ { sub(/^exclude:[[:space:]]*/, ""); print; exit }' "$file")"
  fi
  # Treat missing or empty exclude as "include"
  [[ -z "$raw" || "$raw" == "[]" ]] && return 0
  # Tokenize the list and check membership
  local tokens; tokens="$(echo "$raw" | tr -d '[]' | tr ',' ' ' | xargs)"
  for t in $tokens; do
    [[ "$t" == "$framework" ]] && return 1
  done
  return 0
}

# parse_hook_yaml <hook_yaml_file>
# Emits key=value lines for each top-level scalar AND for trigger fields.
# Output keys: name, script, event, match-tool (space-separated tokens), exclude.
#
# NOTE: This flattens all triggers into a single stream. When a hook has
# multiple triggers, the association between event and match-tool is lost.
# Currently all hooks use a single trigger, so this is not an issue in
# practice. If multi-trigger hooks are needed, this output format must be
# changed to emit delimited records (one per trigger).
parse_hook_yaml() {
  local file="$1"
  awk '
    /^name:/    { sub(/^name:[[:space:]]*/, ""); print "name=" $0 }
    /^script:/  { sub(/^script:[[:space:]]*/, ""); print "script=" $0 }
    /^[[:space:]]*-[[:space:]]*event:/ {
      sub(/^[[:space:]]*-[[:space:]]*event:[[:space:]]*/, "")
      print "event=" $0
    }
    /^[[:space:]]*match-tool:/ {
      sub(/^[[:space:]]*match-tool:[[:space:]]*/, "")
      gsub(/[\[\],]/, " ")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      gsub(/[[:space:]]+/, " ")
      print "match-tool=" $0
    }
    /^exclude:/ { sub(/^exclude:[[:space:]]*/, ""); print "exclude=" $0 }
  ' "$file"
}

# agent_body <agent_file>
# Echoes everything after the closing --- of the frontmatter block.
agent_body() {
  local file="$1"
  awk '
    { sub(/\r$/, "") }
    fm < 2 && /^---$/ { fm++; next }
    fm >= 2 { print }
  ' "$file"
}

# enumerate_agents <dir>
# Echoes one agent file path per line.
enumerate_agents() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  for f in "$dir"/*.md; do
    [[ -f "$f" ]] && echo "$f"
  done
}

# enumerate_hooks <dir>
# Echoes one .hook.yaml file path per line.
enumerate_hooks() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  for f in "$dir"/*.hook.yaml; do
    [[ -f "$f" ]] && echo "$f"
  done
}
