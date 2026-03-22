#!/usr/bin/env bash
# =============================================================================
# Hook: Protect System Files (PreToolUse on Write/Edit)
# =============================================================================
# Prevents agents from accidentally overwriting core crew files at runtime.
# Custom agents in .claude/agents/ are allowed (the Architect creates them).
# User-mutable references (agents-registry.md, agents.md) are also allowed.
#
# Exit codes:
#   0 = allow the operation
#   2 = block the operation (hard reject)
# =============================================================================

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // ""' 2>/dev/null)

# If we can't extract a file path, allow the operation
[[ -z "$FILE" ]] && exit 0

BASENAME=$(basename "$FILE")

# ── CLAUDE.md: never modify at runtime ──────────────────────────────────────
if [[ "$BASENAME" == "CLAUDE.md" && "$FILE" != *".claude/"* ]]; then
  echo "BLOCKED: CLAUDE.md is a system file. Update it in the repo and run updateme.sh."
  exit 2
fi

# ── Core agent definitions: never modify at runtime ─────────────────────────
CORE_AGENTS="architect.md scribe.md sorter.md seeker.md connector.md librarian.md transcriber.md postman.md"
if [[ "$FILE" == *".claude/agents/"* ]]; then
  for core in $CORE_AGENTS; do
    if [[ "$BASENAME" == "$core" ]]; then
      echo "BLOCKED: $BASENAME is a core agent definition. Update it in the repo and run updateme.sh."
      exit 2
    fi
  done
  # Custom agents are allowed through
  exit 0
fi

# ── Skills: never modify at runtime ─────────────────────────────────────────
if [[ "$FILE" == *".claude/skills/"* ]]; then
  echo "BLOCKED: Skill files are managed by the repo. Update them in the repo and run updateme.sh."
  exit 2
fi

# ── Core references: block all except user-mutable ones ─────────────────────
if [[ "$FILE" == *".claude/references/"* ]]; then
  USER_MUTABLE="agents-registry.md agents.md"
  for allowed in $USER_MUTABLE; do
    [[ "$BASENAME" == "$allowed" ]] && exit 0
  done
  echo "BLOCKED: $BASENAME is a core reference file. Update it in the repo and run updateme.sh."
  exit 2
fi

# Everything else is allowed
exit 0
