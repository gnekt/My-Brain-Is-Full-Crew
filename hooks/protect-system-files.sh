#!/usr/bin/env bash
# =============================================================================
# Hook: Protect System Files (PreToolUse / BeforeTool on Write/Edit)
# =============================================================================
# Prevents agents from accidentally overwriting core crew files at runtime.
# Custom agents in <platform_dir>/agents/ are allowed (the Architect creates
# them).  User-mutable references (agents-registry.md, agents.md) are also
# allowed.
#
# Cross-platform invocation contract:
#   - Payload arrives on stdin as JSON.
#   - CREW_PLATFORM_DIR env var names the platform directory (e.g. .claude,
#     .gemini, .codex, .opencode).  Falls back to auto-detection.
#   - Exit 0 = allow, exit 2 = block (hard reject).
# =============================================================================

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# ── Resolve platform directory ──────────────────────────────────────────────
# Prefer explicit env var; fall back to matching any known platform dir in the
# path.  This keeps Claude behavior identical while supporting Gemini/Codex.
PLATFORM_DIR="${CREW_PLATFORM_DIR:-.claude}"
PLATFORM_DIRS=".claude .gemini .codex .opencode"

resolve_platform_dir() {
  for pd in $PLATFORM_DIRS; do
    if [[ "$FILE" == *"${pd}/"* || "$COMMAND" == *"${pd}/"* ]]; then
      printf '%s' "$pd"
      return 0
    fi
  done
  printf '%s' "$PLATFORM_DIR"
}
ACTIVE_PD="$(resolve_platform_dir)"

command_has_write_intent() {
  local command="$1"

  printf '%s' "$command" | grep -Eq '(^|[^<])>>?|[[:space:]]tee([[:space:]]|$)|sed[[:space:]]+-i([[:space:]]|$)|perl[[:space:]]+-pi([[:space:]]|$)|(^|[[:space:];|&])(mv|rm|touch|truncate|install|dd|cp|chmod|chown|chgrp)[[:space:]]' && return 0
  printf '%s' "$command" | grep -Eq 'write_text\(|writeFileSync\(|writeFile\(|appendFileSync\(|appendFile\(|open\([^)]*,[[:space:]]*["'"'"'](w|a)' && return 0

  return 1
}

block_command() {
  echo "BLOCKED: $1"
  exit 2
}

check_command_mode() {
  local command="$1"

  [[ -z "$command" ]] && return 0
  command_has_write_intent "$command" || return 0

  for df in CLAUDE.md GEMINI.md AGENTS.md; do
    if [[ "$command" == *"$df"* ]]; then
      block_command "$df is a system file. Update it in the repo and run updateme.sh."
    fi
  done

  for core in architect.md scribe.md sorter.md seeker.md connector.md librarian.md transcriber.md postman.md architect.toml scribe.toml sorter.toml seeker.toml connector.toml librarian.toml transcriber.toml postman.toml; do
    if [[ "$command" == *"${ACTIVE_PD}/agents/${core}"* ]]; then
      block_command "$core is a core agent definition. Update it in the repo and run updateme.sh."
    fi
  done

  if [[ "$command" == *"${ACTIVE_PD}/skills/"* ]]; then
    block_command "Skill files are managed by the repo. Update them in the repo and run updateme.sh."
  fi

  if [[ "$command" == *"${ACTIVE_PD}/references/"* ]]; then
    if [[ "$command" == *"${ACTIVE_PD}/references/agents-registry.md"* || "$command" == *"${ACTIVE_PD}/references/agents.md"* ]]; then
      return 0
    fi
    block_command "Core reference files are managed by the repo. Update them in the repo and run updateme.sh."
  fi

  return 0
}

if [[ -z "$FILE" ]]; then
  check_command_mode "$COMMAND"
  exit 0
fi

BASENAME=$(basename "$FILE")

# ── Dispatcher files: never modify at runtime ───────────────────────────────
DISPATCHER_FILES="CLAUDE.md GEMINI.md AGENTS.md"
for df in $DISPATCHER_FILES; do
  if [[ "$BASENAME" == "$df" && "$FILE" != *"${ACTIVE_PD}/"* ]]; then
    echo "BLOCKED: $df is a system file. Update it in the repo and run updateme.sh."
    exit 2
  fi
done

# ── Core agent definitions: never modify at runtime ─────────────────────────
CORE_AGENTS="architect.md scribe.md sorter.md seeker.md connector.md librarian.md transcriber.md postman.md"
CORE_AGENTS_TOML="architect.toml scribe.toml sorter.toml seeker.toml connector.toml librarian.toml transcriber.toml postman.toml"
if [[ "$FILE" == *"${ACTIVE_PD}/agents/"* ]]; then
  for core in $CORE_AGENTS $CORE_AGENTS_TOML; do
    if [[ "$BASENAME" == "$core" ]]; then
      echo "BLOCKED: $BASENAME is a core agent definition. Update it in the repo and run updateme.sh."
      exit 2
    fi
  done
  # Custom agents are allowed through
  exit 0
fi

# ── Skills: never modify at runtime ─────────────────────────────────────────
if [[ "$FILE" == *"${ACTIVE_PD}/skills/"* ]]; then
  echo "BLOCKED: Skill files are managed by the repo. Update them in the repo and run updateme.sh."
  exit 2
fi

# ── Core references: block all except user-mutable ones ─────────────────────
if [[ "$FILE" == *"${ACTIVE_PD}/references/"* ]]; then
  USER_MUTABLE="agents-registry.md agents.md"
  for allowed in $USER_MUTABLE; do
    [[ "$BASENAME" == "$allowed" ]] && exit 0
  done
  echo "BLOCKED: $BASENAME is a core reference file. Update it in the repo and run updateme.sh."
  exit 2
fi

# Everything else is allowed
exit 0
