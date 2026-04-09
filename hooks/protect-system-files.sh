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
  local normalized_command="$command"

  normalized_command="${normalized_command//\\\"/\"}"
  normalized_command="${normalized_command//\\\'/\'}"

  printf '%s' "$command" | grep -Eq '(^|[^<])>>?|[[:space:]]tee([[:space:]]|$)|sed[[:space:]]+-i([[:space:]]|$)|perl[[:space:]]+-pi([[:space:]]|$)|(^|[[:space:];|&])(mv|rm|touch|truncate|install|dd|cp|chmod|chown|chgrp)[[:space:]]' && return 0
  printf '%s' "$normalized_command" | grep -Eq 'write_text\(|writeFileSync\(|writeFile\(|appendFileSync\(|appendFile\(|open\([^)]*,[[:space:]]*["'"'"'](w|a)' && return 0

  return 1
}

append_command_target() {
  local target="$1"

  [[ -n "$target" ]] || return 0
  printf '%s\n' "$target"
}

check_protected_path() {
  local target="$1"
  local target_basename
  local df
  local core

  [[ -n "$target" ]] || return 0
  target_basename=$(basename "$target")

  for df in CLAUDE.md GEMINI.md AGENTS.md; do
    if [[ "$target_basename" == "$df" && "$target" != *"${ACTIVE_PD}/"* ]]; then
      block_command "$df is a system file. Update it in the repo and run updateme.sh."
    fi
  done

  for core in architect.md scribe.md sorter.md seeker.md connector.md librarian.md transcriber.md postman.md architect.toml scribe.toml sorter.toml seeker.toml connector.toml librarian.toml transcriber.toml postman.toml; do
    if [[ "$target" == *"${ACTIVE_PD}/agents/${core}"* ]]; then
      block_command "$core is a core agent definition. Update it in the repo and run updateme.sh."
    fi
  done

  if [[ "$target" == *"${ACTIVE_PD}/hooks/"* ]]; then
    block_command "Hook files are managed by the repo. Update them in the repo and run updateme.sh."
  fi

  if [[ "$target" == *"${ACTIVE_PD}/skills/"* ]]; then
    block_command "Skill files are managed by the repo. Update them in the repo and run updateme.sh."
  fi

  if [[ "$ACTIVE_PD" == ".opencode" && "$target" == *"${ACTIVE_PD}/.crew/"* ]]; then
    block_command "OpenCode managed plugin files are managed by the repo. Update them in the repo and run updateme.sh."
  fi

  if [[ "$target" == *"${ACTIVE_PD}/references/"* ]]; then
    if [[ "$target" == *"${ACTIVE_PD}/references/agents-registry.md"* || "$target" == *"${ACTIVE_PD}/references/agents.md"* ]]; then
      return 0
    fi
    block_command "Core reference files are managed by the repo. Update them in the repo and run updateme.sh."
  fi
}

process_command_segment_targets() {
  local -a segment=("$@")
  local command_name="${segment[0]:-}"
  local token
  local i
  local saw_inplace=0
  local skipped_subject=0

  [[ -n "$command_name" ]] || return 0

  case "$command_name" in
    tee)
      for token in "${segment[@]:1}"; do
        [[ "$token" == -* ]] && continue
        append_command_target "$token"
      done
      ;;
    mv|cp|install)
      for ((i=${#segment[@]} - 1; i >= 1; i--)); do
        token="${segment[i]}"
        [[ -n "$token" && "$token" != -* ]] || continue
        append_command_target "$token"
        break
      done
      ;;
    rm|touch|truncate)
      for token in "${segment[@]:1}"; do
        [[ "$token" == -* ]] && continue
        append_command_target "$token"
      done
      ;;
    chmod|chown|chgrp)
      for token in "${segment[@]:1}"; do
        [[ "$token" == -* ]] && continue
        if [[ "$skipped_subject" -eq 0 ]]; then
          skipped_subject=1
          continue
        fi
        append_command_target "$token"
      done
      ;;
    dd)
      for token in "${segment[@]:1}"; do
        case "$token" in
          of=*)
            append_command_target "${token#of=}"
            ;;
        esac
      done
      ;;
    sed)
      for token in "${segment[@]:1}"; do
        [[ "$token" == "-i" || "$token" == -i* ]] && saw_inplace=1
      done
      if [[ "$saw_inplace" -eq 1 ]]; then
        for ((i=${#segment[@]} - 1; i >= 1; i--)); do
          token="${segment[i]}"
          [[ -n "$token" && "$token" != -* ]] || continue
          append_command_target "$token"
          break
        done
      fi
      ;;
    perl)
      for token in "${segment[@]:1}"; do
        [[ "$token" == "-pi" || "$token" == -pi* || "$token" == "-i" || "$token" == -i* ]] && saw_inplace=1
      done
      if [[ "$saw_inplace" -eq 1 ]]; then
        for ((i=${#segment[@]} - 1; i >= 1; i--)); do
          token="${segment[i]}"
          [[ -n "$token" && "$token" != -* ]] || continue
          append_command_target "$token"
          break
        done
      fi
      ;;
  esac
}

extract_command_write_targets() {
  local command="$1"
  local normalized_command
  local remaining
  local path_write_regex='Path\((["'"'"'])([^"'"'"']+)\1\)[.]write_text\('
  local fs_write_regex='(writeFileSync|writeFile|appendFileSync|appendFile)\([[:space:]]*(["'"'"'])([^"'"'"']+)\2'
  local open_write_regex='open\([[:space:]]*(["'"'"'])([^"'"'"']+)\1[^)]*,[[:space:]]*(["'"'"'])(w|a)\3'
  local token_stream
  local raw_token
  local stripped_token
  local expect_redirection_target=0
  local -a segment=()

  [[ -n "$command" ]] || return 0

  normalized_command="$command"
  normalized_command="${normalized_command//\\\"/\"}"
  normalized_command="${normalized_command//\\\'/\'}"

  remaining="$normalized_command"
  while [[ "$remaining" =~ $path_write_regex ]]; do
    append_command_target "${BASH_REMATCH[2]}"
    remaining="${remaining#*"${BASH_REMATCH[0]}"}"
  done

  remaining="$normalized_command"
  while [[ "$remaining" =~ $fs_write_regex ]]; do
    append_command_target "${BASH_REMATCH[3]}"
    remaining="${remaining#*"${BASH_REMATCH[0]}"}"
  done

  remaining="$normalized_command"
  while [[ "$remaining" =~ $open_write_regex ]]; do
    append_command_target "${BASH_REMATCH[2]}"
    remaining="${remaining#*"${BASH_REMATCH[0]}"}"
  done

  token_stream=$(printf '%s\n' "$command" | xargs -n1 printf '%s\n' 2>/dev/null) || return 0

  while IFS= read -r raw_token; do
    [[ -n "$raw_token" ]] || continue

    if [[ "$expect_redirection_target" -eq 1 ]]; then
      append_command_target "${raw_token%[;|&]}"
      expect_redirection_target=0
      continue
    fi

    case "$raw_token" in
      '>'|'>>'|'1>'|'1>>')
        expect_redirection_target=1
        continue
        ;;
      '1>>'*)
        append_command_target "${raw_token#1>>}"
        continue
        ;;
      '1>'*)
        append_command_target "${raw_token#1>}"
        continue
        ;;
      '>>'*)
        append_command_target "${raw_token#>>}"
        continue
        ;;
      '>'*)
        append_command_target "${raw_token#>}"
        continue
        ;;
      '|'|'||'|'&&'|'&'|';')
        process_command_segment_targets "${segment[@]}"
        segment=()
        continue
        ;;
    esac

    stripped_token="$raw_token"
    if [[ "$stripped_token" == *';' || "$stripped_token" == *'|' || "$stripped_token" == *'&' ]]; then
      stripped_token="${stripped_token%[;|&]}"
      [[ -n "$stripped_token" ]] && segment+=("$stripped_token")
      process_command_segment_targets "${segment[@]}"
      segment=()
      continue
    fi

    segment+=("$stripped_token")
  done <<< "$token_stream"

  process_command_segment_targets "${segment[@]}"
}

check_command_target() {
  local target="$1"

  [[ -n "$target" ]] || return 0
  check_protected_path "$target"
}

block_command() {
  echo "BLOCKED: $1"
  exit 2
}

check_command_mode() {
  local command="$1"
  local target

  [[ -z "$command" ]] && return 0
  command_has_write_intent "$command" || return 0

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    check_command_target "$target"
  done < <(extract_command_write_targets "$command" | sort -u)

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

check_protected_path "$FILE"

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
