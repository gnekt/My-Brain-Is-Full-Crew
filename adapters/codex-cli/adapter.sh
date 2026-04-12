#!/usr/bin/env bash
# =============================================================================
# adapters/codex-cli/adapter.sh — Codex CLI framework adapter
# =============================================================================
# Sourced by scripts/build.sh AFTER adapters/lib.sh.
# Translates source files into a dist/codex-cli/ tree that mirrors what
# Codex CLI expects in the user's vault.
#
# Codex CLI specifics:
#   - Dispatcher file: AGENTS.md (same as OpenCode)
#   - Platform config dir: .codex/
#   - MCP config: .codex/config.toml (TOML format with [mcp_servers.*] tables)
#   - Skills dir: .agents/skills/<name>/SKILL.md
# =============================================================================

CC_PLATFORM="codex-cli"
CC_FW_DIR="codex"
CC_DISPATCHER="AGENTS.md"

# rewrite_codex_paths <file>
# Applies Codex-specific targeted path rewrites in-place.
# This is narrower than the shared rewrite_platform_paths helper because Codex
# uses mixed destination roots depending on the source path.
rewrite_codex_paths() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  perl -i -pe '
    s|\.platform/agents/|.codex/agents/|g;
    s|\.platform/references/|.codex/references/|g;
    s|\.platform/skills/|.agents/skills/|g;
    s|\.platform/|.codex/|g;
    s|DISPATCHER\.md|AGENTS.md|g;
  ' "$file"
}

# rewrite_tool_compat <file>
# Rewrites unsupported or platform-specific tool references in a file to
# Codex-compatible neutral language.  Applied AFTER rewrite_platform_paths so
# path references are already resolved.
#
# Rewrites applied (T-01-06):
#   - `AskUserQuestion` / AskUserQuestion  → "ask the user" (preserves one-at-a-time constraint phrasing elsewhere)
#   - `request_user_input` / request_user_input → "ask the user"
#   - "Skill tool"  → "invoke the skill"
#   - "Agent tool"  → "invoke the agent"
#   - "Read tool"   → "read files"
#   - "Glob tool"   → "search files"
#   - "Grep tool"   → "search files"
#   - "Bash tool"   → "shell"
rewrite_tool_compat() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # Use perl for reliable in-place multi-substitution across all platforms.
  # Each substitution is a plain string replacement (no regex heavy-lifting).
  perl -i -pe '
    s/`AskUserQuestion`/ask the user/g;
    s/\bAskUserQuestion\b/ask the user/g;
    s/`request_user_input`/ask the user/g;
    s/\brequest_user_input\b/ask the user/g;
    s/\bSkill tool\b/invoke the skill/g;
    s/\bAgent tool\b/invoke the agent/g;
    s/\bRead tool\b/read files/g;
    s/\bGlob tool\b/search files/g;
    s/\bGrep tool\b/search files/g;
    s/\bBash tool\b/shell/g;
  ' "$file"
}

# normalize_codex_routing_contract <file>
# Rewrites copied dispatcher/reference content so the generated Codex output
# describes one coherent contract: root-context orchestration, bounded child
# agents, and direct-chat confirmations under agents.max_depth = 1.
normalize_codex_routing_contract() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  rewrite_tool_compat "$file"

  perl -0pi -e '
    s/handle complex, multi-step, or conversational flows\. Invoke them via the \*\*invoke the skill\*\*\. They run in the main conversation context \(multi-turn state is preserved\)\./handle complex, multi-step, or conversational flows. In Codex, the root context follows the relevant skill instructions directly so multi-turn state stays in one chat./g;
    s/handle reactive, single-shot operations\. Invoke them via the \*\*invoke the agent\*\*\. They run as subprocesses\./handle reactive, bounded tasks. In Codex, the root context may spawn a bounded child agent when delegation is worth it, but orchestration decisions stay in the root context because `agents.max_depth = 1`./g;
    s/If a user message matches a skill trigger, the skill is invoked via the \*\*invoke the skill\*\* \(not the invoke the agent\)\. The dispatcher does NOT also invoke the source agent\./If a user message matches a skill trigger, the root context follows that skill directly in the main conversation. Do not also spawn a child agent for the same trigger./g;
    s/Skills run in the \*\*main conversation context\*\*, preserving multi-turn state\. This is different from agents, which run as subprocesses\./Skills stay in the main conversation context so multi-turn state remains in one chat. Child agents are only for bounded side tasks./g;
    s/check registry, check call chain, max depth 3/check the registry and decide in the root context whether another bounded child task is still necessary under `agents.max_depth = 1`/g;
    s/Skills count as step 1 in the call chain when they produce agent suggestions\./Skills do not consume extra child depth because the root context executes them directly./g;
    s/The dispatcher should confirm with the user first:/The root context should confirm with the user directly in chat first:/g;
    s/asks the user if they want the Architect to create a custom agent/asks the user directly in chat whether they want a custom agent/g;
    s/"Call chain so far: \[scribe, architect\]\. You are step 3 of max 3\."/"Root context history: [scribe, architect]. If another bounded child task is still useful, the root context decides whether to spawn it within `agents.max_depth = 1`."/g;
    s/\*\*Max depth: 3\*\*: no more than 3 agents per user request/\*\*Child depth: `agents.max_depth = 1`\*\*: a spawned child may finish one bounded task, then the root context decides what happens next/g;
    s/If the dispatcher would need a 4th agent, it:/If deeper recursion would be required, the root context returns the current results to the user and decides the next step in chat:/g;
    s/\bmax depth 3\b/`agents.max_depth = 1`/g;
    s/\bstep 3 of max 3\b/root-context follow-up after a bounded child task/g;
    s/\bmax depth reached\b/root-context delegation limit reached/g;
    s/No duplicates: never invoke the same agent twice in one chain/No duplicates: do not spawn the same child agent twice for the same request/g;
    s/No circular patterns: if Agent A suggests Agent B and B is already in the chain, skip/No circular patterns: if a suggested child is already in the root decision history, skip it/g;
    s/Do NOT call other agents/Do NOT spawn or imply deeper child recursion/g;
    s/only the dispatcher invokes agents/only the root context decides when to spawn a bounded child agent/g;
  ' "$file"

  perl -0pi -e '
    s/\binvoke the skill\b/follow the skill instructions directly in the root context/g;
    s/\binvoke the agent\b/spawn a bounded child agent from the root context/g;
    s/\bask the user\b/ask the user directly in chat and wait for the reply/g;
  ' "$file"
}

# _cc_prepend_codex_header <file>
# Prepends the Codex-specific routing workaround header to a file (T-01-08).
# Uses a unique marker (<!-- CODEX-ROUTING-HEADER -->) so tests can detect it
# and so repeated builds are idempotent.
_cc_prepend_codex_header() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # Idempotency: skip if header is already present
  grep -qF '<!-- CODEX-ROUTING-HEADER -->' "$file" && return 0

  local header
  header="$(cat <<'HEADER'
<!-- CODEX-ROUTING-HEADER -->
<!-- Generated by adapters/codex-cli/adapter.sh — do not edit manually -->

## Codex CLI — Routing Notes

> **Context:** Codex CLI loads this file as the root dispatcher. Due to
> multi-agent depth limits (`agents.max_depth = 1` by default), all
> orchestration decisions stay in this root context. Spawned agents emit
> a `### Suggested next agent` signal; the root context then decides whether
> to continue with another agent.

**Custom agents** live in `.codex/agents/*.toml` and are discovered automatically.
**Skills** live in `.agents/skills/` inside the project (or `$HOME/.agents/skills/`).
**Compatibility guide:** see `.codex/references/codex-cli-compat.md` for source-to-Codex mappings, approval wording, and troubleshooting.

**Tool language:** Use neutral, conceptual wording — "run shell commands",
"edit files", "spawn sub-agents", "wait for sub-agents" — rather than
hard-coded tool identifiers that may not exist across all Codex versions.

---

HEADER
)"

  # Prepend header before existing content
  local tmp; tmp="$(mktemp)"
  printf '%s\n' "$header" > "$tmp"
  cat "$file" >> "$tmp"
  mv "$tmp" "$file"
}

# adapter_translate_dispatcher <source_dispatcher_md> <dest_dir>
# Copies the source DISPATCHER.md to dest_dir/AGENTS.md (Codex CLI's vault-root
# dispatcher filename). Rewrites .platform/ and DISPATCHER.md to codex paths,
# normalizes Codex routing semantics, and prepends the Codex routing header.
adapter_translate_dispatcher() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  mkdir -p "$dst"
  cp "$src" "$dst/AGENTS.md"
  rewrite_codex_paths "$dst/AGENTS.md"
  normalize_codex_routing_contract "$dst/AGENTS.md"
  _cc_prepend_codex_header "$dst/AGENTS.md"
}

# adapter_translate_references <source_refs_dir> <dest_root>
# Copies *.md into dest_root/.codex/references/, rewriting framework paths
# and normalizing Codex routing semantics.
adapter_translate_references() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out="$dst/.codex/references"
  mkdir -p "$out"
  for f in "$src"/*.md; do
    [[ -f "$f" ]] || continue
    should_include "$f" "$CC_PLATFORM" || continue
    local out_file="$out/$(basename "$f")"
    cp "$f" "$out/"
    rewrite_codex_paths "$out_file"
    if [[ "$(basename "$f")" == "codex-cli-compat.md" ]]; then
      continue
    fi
    normalize_codex_routing_contract "$out_file"
  done
}

# adapter_translate_skills <source_skills_dir> <dest_root>
# Copies each skill directory into dest_root/.agents/skills/<name>/, preserving
# optional subdirectories and rewriting text content for Codex-native output.
_cc_rewrite_skill_markdown() {
  local skill_name="$1" file="$2"
  [[ -f "$file" ]] || return 0

  rewrite_codex_paths "$file"
  rewrite_tool_compat "$file"

  case "$skill_name" in
    onboarding)
      perl -0pi -e '
        s/You MUST use the ask the user tool for EVERY question in every phase\. This is not optional\. This is how the onboarding works:/Use direct chat for every question in every phase. Ask one direct plain-text question, wait for the user'\''s reply before continuing, and resume from the saved state file if the flow is already active. This is not optional. This is how the onboarding works:/g;
        s/1\. Ask ONE question using ask the user/1. Ask one direct plain-text question/g;
        s/2\. Read the user'\''s answer/2. Wait for the user'\''s reply before continuing/g;
        s/4\. Ask the NEXT question using ask the user/4. Ask the next direct plain-text question/g;
        s/\*\*ONE question per ask the user call\.\*\* Never bundle 2\+ questions in one message\./**One direct plain-text question at a time.** Never bundle 2+ questions in one message./g;
        s/\.codex\/agents\/\{name\}\.md/.codex\/agents\/{name}.toml/g;
        s/\.mcp\.json/.codex\/config.toml/g;
        s/\$HOME\/\.platform\/agents/\$HOME\/.codex\/agents/g;
      ' "$file"
      ;;
    create-agent)
      perl -0pi -e '
        s/You MUST use the ask the user tool for EVERY question in every phase\. This is not optional\. This is how the conversation works:/Use direct chat for every question in every phase. Ask one direct plain-text question, wait for the user'\''s reply before continuing, and resume from the saved state file if the flow is already active. This is not optional. This is how the conversation works:/g;
        s/1\. Ask ONE question using ask the user/1. Ask one direct plain-text question/g;
        s/2\. Read the user'\''s answer/2. Wait for the user'\''s reply before continuing/g;
        s/4\. Ask the NEXT question using ask the user/4. Ask the next direct plain-text question/g;
        s/\*\*ONE question per ask the user call\.\*\* Never bundle 2\+ questions\./**One direct plain-text question at a time.** Never bundle 2+ questions./g;
        s/\.codex\/agents\/\{name\}\.md/.codex\/agents\/{name}.toml/g;
      ' "$file"
      ;;
    manage-agent)
      perl -0pi -e '
        s/using `ask the user`/by asking the user directly/g;
        s/Use `ask the user` to/Ask one direct plain-text question to/g;
        s/If the user specifies a name, read `\.codex\/agents\/\{name\}\.md`/If the user specifies a name, read `\.codex\/agents\/{name}.toml`/g;
        s/Modify the agent file at `\.codex\/agents\/\{name\}\.md`/Modify the agent file at `\.codex\/agents\/{name}.toml`/g;
        s/locate `\.codex\/agents\/\{name\}\.md`/locate `\.codex\/agents\/{name}.toml`/g;
        s/Delete the agent file from `\.codex\/agents\/\{name\}\.md`/Delete the agent file from `\.codex\/agents\/{name}.toml`/g;
      ' "$file"
      if ! grep -qi 'resume from the saved state file if the flow is already active' "$file"; then
        cat <<'EOF' >> "$file"

## Codex Conversation Flow

- Ask one direct plain-text question when clarification is required.
- Wait for the user's reply before continuing.
- Resume from the saved state file if the flow is already active.
EOF
      fi
      ;;
    transcribe)
      perl -0pi -e '
        s/Use ask the user to collect:/Use direct chat to collect this intake context: ask one direct plain-text question, wait for the user'\''s reply before continuing, and resume from the saved state file if the flow is already active. Collect:/g;
      ' "$file"
      ;;
  esac
}

_cc_rewrite_skill_text_tree() {
  local skill_name="$1" root="$2"
  [[ -d "$root" ]] || return 0

  if [[ -f "$root/SKILL.md" ]]; then
    _cc_rewrite_skill_markdown "$skill_name" "$root/SKILL.md"
  fi

  if [[ -d "$root/references" ]]; then
    while IFS= read -r ref; do
      rewrite_codex_paths "$ref"
      rewrite_tool_compat "$ref"
    done < <(find "$root/references" -type f -name '*.md')
  fi

  if [[ -d "$root/assets" ]]; then
    while IFS= read -r asset; do
      rewrite_codex_paths "$asset"
      rewrite_tool_compat "$asset"
    done < <(find "$root/assets" -type f -name '*.md')
  fi

  if [[ -f "$root/agents/openai.yaml" ]]; then
    rewrite_codex_paths "$root/agents/openai.yaml"
    rewrite_tool_compat "$root/agents/openai.yaml"
  fi
}

adapter_translate_skills() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  for skill_dir in "$src"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    should_include "${skill_dir}SKILL.md" "$CC_PLATFORM" || continue
    local name; name="$(basename "$skill_dir")"
    local out="$dst/.agents/skills/$name"
    mkdir -p "$out"

    cp "${skill_dir}SKILL.md" "$out/SKILL.md"
    [[ -d "${skill_dir}scripts" ]] && mkdir -p "$out/scripts" && cp -R "${skill_dir}scripts/." "$out/scripts/"
    [[ -d "${skill_dir}references" ]] && mkdir -p "$out/references" && cp -R "${skill_dir}references/." "$out/references/"
    [[ -d "${skill_dir}assets" ]] && mkdir -p "$out/assets" && cp -R "${skill_dir}assets/." "$out/assets/"
    if [[ -f "${skill_dir}agents/openai.yaml" ]]; then
      mkdir -p "$out/agents"
      cp "${skill_dir}agents/openai.yaml" "$out/agents/openai.yaml"
    fi

    _cc_rewrite_skill_text_tree "$name" "$out"
  done
}

# _cc_toml_quote_key <name>
# Emits the TOML table key for [mcp_servers.<name>].
# Codex CLI requires MCP server names to match ^[a-zA-Z0-9_-]+$, so any
# character outside that set is replaced with a hyphen before writing.
_cc_toml_quote_key() {
  local name="$1"
  # Sanitize: replace any character not in [a-zA-Z0-9_-] with a hyphen
  local safe_name="${name//[^a-zA-Z0-9_-]/-}"
  printf '[mcp_servers.%s]' "$safe_name"
}

# _cc_toml_escape_string <value>
# Escapes a value for use in a TOML double-quoted string.
# Escapes backslashes and double-quotes; other characters pass through.
_cc_toml_escape_string() {
  local val="$1"
  # Escape backslash first, then double-quote
  val="${val//\\/\\\\}"
  val="${val//\"/\\\"}"
  printf '%s' "$val"
}

# adapter_translate_config <source_mcp_dir> <dest_root>
# Reads mcp/servers.yaml and writes dest_root/.codex/config.toml.
#
# Config structure:
#   - Safe baseline Codex settings at the top
#   - [mcp_servers.<name>] tables for each server
#     - HTTP servers: url = "..."  (plus env inline table)
#     - Local servers: command = ["...", "..."]  (plus env inline table)
#
# Security (T-01-01): TOML table names with spaces/special chars are quoted.
# Security (T-01-02): Safe approval_policy and sandbox_mode are always emitted.
adapter_translate_config() {
  local src="$1" dst="$2"
  local yaml="$src/servers.yaml"
  [[ -f "$yaml" ]] || return 0

  local out_dir="$dst/.codex"
  mkdir -p "$out_dir"
  local out="$out_dir/config.toml"

  {
    # ── Safe baseline Codex settings (T-01-02) ──────────────────────────────
    echo '# Generated by adapters/codex-cli/adapter.sh — do not edit manually'
    echo 'approval_policy = "on-request"'
    echo 'sandbox_mode = "workspace-write"'
    echo 'sandbox_workspace_write.network_access = false'
    echo ''
    echo '# Inherit uses the top-level defaults; named profiles override them explicitly.'
    echo '[profiles.quality]'
    echo 'model = "gpt-5.4"'
    echo 'model_reasoning_effort = "high"'
    echo ''
    echo '[profiles.balanced]'
    echo 'model = "gpt-5.4-mini"'
    echo 'model_reasoning_effort = "medium"'
    echo ''
    echo '[profiles.budget]'
    echo 'model = "gpt-5.3-codex-spark"'
    echo 'model_reasoning_effort = "medium"'
    echo ''
    echo '[agents]'
    echo 'max_depth = 1'
    echo ''

    # ── Parse servers.yaml line-by-line and emit TOML tables ────────────────
    local current_name="" current_type="" current_url="" current_cmd="" current_env=""
    local in_servers=0

    _cc_flush_server() {
      [[ -z "$current_name" ]] && return 0

      local key; key="$(_cc_toml_quote_key "$current_name")"
      echo "$key"

      if [[ "$current_type" == "local" || ( -z "$current_type" && -n "$current_cmd" ) ]]; then
        # Local server: command = ["arg1", "arg2", ...]
        # current_cmd is the raw YAML array content e.g. npx, -y, "@anthropic-ai/gmail-mcp"
        local cmd_toml
        cmd_toml="$(_cc_build_command_array "$current_cmd")"
        echo "command = $cmd_toml"
      else
        # HTTP server: url = "..."
        local url_escaped; url_escaped="$(_cc_toml_escape_string "$current_url")"
        echo "url = \"$url_escaped\""
      fi

      # env is only valid for command-based (local) servers; omit for HTTP servers
      if [[ "$current_type" == "local" || ( -z "$current_type" && -n "$current_cmd" ) ]]; then
        if [[ -n "$current_env" ]]; then
          echo "env = $(_cc_build_env_table "$current_env")"
        fi
      fi
      echo ''
    }

    _cc_build_command_array() {
      # Convert a comma-separated YAML sequence payload (without brackets) into
      # a TOML array of quoted strings: ["npx", "-y", "@anthropic-ai/gmail-mcp"]
      local raw="$1"
      local items=()
      IFS=',' read -ra parts <<< "$raw"
      for part in "${parts[@]}"; do
        # Trim leading/trailing whitespace and surrounding quotes
        part="${part#"${part%%[![:space:]]*}"}"
        part="${part%"${part##*[![:space:]]}"}"
        part="${part#\"}" ; part="${part%\"}"
        part="${part#\'}" ; part="${part%\'}"
        items+=("$part")
      done
      # Build TOML array
      local result='['
      local first=1
      for item in "${items[@]}"; do
        [[ -z "$item" ]] && continue
        local escaped; escaped="$(_cc_toml_escape_string "$item")"
        [[ $first -eq 1 ]] && first=0 || result+=', '
        result+="\"$escaped\""
      done
      result+=']'
      echo "$result"
    }

    _cc_build_env_table() {
      local raw="$1"
      local result='{'
      local first=1

      IFS=',' read -ra pairs <<< "$raw"
      for pair in "${pairs[@]}"; do
        pair="${pair#"${pair%%[![:space:]]*}"}"
        pair="${pair%"${pair##*[![:space:]]}"}"
        [[ -z "$pair" ]] && continue

        local key="${pair%%:*}"
        local value="${pair#*:}"

        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        key="${key#\"}" ; key="${key%\"}"
        value="${value#\"}" ; value="${value%\"}"

        local escaped_key escaped_value
        escaped_key="$(_cc_toml_escape_string "$key")"
        escaped_value="$(_cc_toml_escape_string "$value")"

        [[ $first -eq 1 ]] && first=0 || result+=', '
        result+="\"$escaped_key\" = \"$escaped_value\""
      done

      result+='}'
      echo "$result"
    }

    while IFS= read -r line; do
      line="${line%$'\r'}"
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line//[[:space:]]/}" ]] && continue

      if [[ "$line" =~ ^[[:space:]]*servers:[[:space:]]*$ ]]; then
        in_servers=1
      elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]name:[[:space:]]*(.+)$ ]]; then
        [[ $in_servers -eq 1 ]] && _cc_flush_server
        current_name="$(printf '%s' "${BASH_REMATCH[1]}" | tr -d '"')"
        current_type=""
        current_url=""
        current_cmd=""
        current_env=""
      elif [[ "$line" =~ ^[[:space:]]{4}type:[[:space:]]*(.+)$ ]]; then
        current_type="$(printf '%s' "${BASH_REMATCH[1]}" | tr -d '"')"
      elif [[ "$line" =~ ^[[:space:]]{4}url:[[:space:]]*(.+)$ ]]; then
        current_url="$(printf '%s' "${BASH_REMATCH[1]}" | tr -d '"')"
      elif [[ "$line" =~ ^[[:space:]]{4}command:[[:space:]]*\[(.*)\][[:space:]]*$ ]]; then
        # Extract the array payload between [ and ]
        current_cmd="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]{4}env:[[:space:]]*\{(.*)\}[[:space:]]*$ ]]; then
        current_env="${BASH_REMATCH[1]}"
      fi
    done < "$yaml"
    _cc_flush_server

  } > "$out"
}

# _cc_extract_description <agent_file>
# Extracts the description value from YAML frontmatter, handling both:
#   - Scalar: description: Some text
#   - Folded block (description: >): captures all indented continuation lines,
#     joins them with spaces, and trims the result.
# Emits the description as a single-line string (no leading/trailing whitespace).
_cc_extract_description() {
  local file="$1"
  awk '
    /^---$/ { fm++; next }
    fm == 1 && /^description:[[:space:]]*>/ {
      # Folded-block style: value starts on next indented lines
      in_desc=1
      next
    }
    fm == 1 && /^description:/ {
      # Scalar style: description: value on same line
      sub(/^description:[[:space:]]*/, "")
      desc=$0
      in_desc=0
      next
    }
    fm == 1 && in_desc && /^[[:space:]]/ {
      # Continuation line (indented)
      sub(/^[[:space:]]+/, "")
      if (desc == "") desc=$0
      else desc=desc " " $0
      next
    }
    fm == 1 && in_desc && !/^[[:space:]]/ {
      # End of folded block
      in_desc=0
    }
    fm >= 2 { exit }
    END {
      # Trim trailing whitespace/period added by folded-block joining
      gsub(/[[:space:]]+$/, "", desc)
      print desc
    }
  ' "$file"
}

# _cc_toml_escape_dquote_string <value>
# Escapes a string for embedding in a TOML double-quoted basic string.
# Handles backslash and double-quote characters.
_cc_toml_escape_dquote_string() {
  local val="$1"
  val="${val//\\/\\\\}"
  val="${val//\"/\\\"}"
  printf '%s' "$val"
}

# _cc_model_to_codex <model>
# Maps the source model tier into a Codex model id.
_cc_model_to_codex() {
  local model="$1"
  case "$model" in
    */*|gpt-*) echo "$model" ;;
    low)       echo "gpt-5.3-codex-spark" ;;
    mid)       echo "gpt-5.4-mini" ;;
    high)      echo "gpt-5.4" ;;
    *)         echo "$model" ;;
  esac
}

# _cc_model_reasoning_effort <model>
# Maps the source model tier into a Codex reasoning effort.
_cc_model_reasoning_effort() {
  local model="$1"
  case "$model" in
    high) echo "high" ;;
    *)    echo "medium" ;;
  esac
}

# _cc_capabilities_to_sandbox <space-separated capabilities>
# Preserves the source intent by only granting workspace writes to agents that
# explicitly declare write/edit/bash capabilities.
_cc_capabilities_to_sandbox() {
  local caps="$1"
  for cap in $caps; do
    case "$cap" in
      write|edit|bash)
        echo "workspace-write"
        return 0
        ;;
    esac
  done
  echo "read-only"
}

# adapter_translate_agent_toml <agent_file> <dest_root>
# Translates a single agent .md file to a Codex CLI custom agent TOML file at:
#   <dest_root>/.codex/agents/<basename-without-md>.toml
#
# The TOML file contains:
#   name = "<name>"
#   description = "<single-line description>"
#   developer_instructions = '''
#   <body with platform paths rewritten>
#   '''
#
# Security (T-01-04): Uses TOML multiline literal strings (''') to avoid
# backslash-escape pitfalls. Falls back to multiline basic strings (""") if
# the body contains the ''' delimiter sequence, escaping as needed.
adapter_translate_agent_toml() {
  local agent_file="$1" dst_root="$2"
  [[ -f "$agent_file" ]] || return 0

  local name; name="$(parse_frontmatter "$agent_file" name)"
  [[ -z "$name" ]] && name="$(basename "$agent_file" .md)"

  local description; description="$(_cc_extract_description "$agent_file")"
  local desc_escaped; desc_escaped="$(_cc_toml_escape_dquote_string "$description")"
  local model_raw; model_raw="$(parse_frontmatter "$agent_file" model)"
  local model; model="$(_cc_model_to_codex "$model_raw")"
  local model_reasoning_effort; model_reasoning_effort="$(_cc_model_reasoning_effort "$model_raw")"
  local capabilities; capabilities="$(parse_capabilities "$agent_file")"
  local sandbox_mode; sandbox_mode="$(_cc_capabilities_to_sandbox "$capabilities")"

  # Get the agent body, apply Codex path rewrites, and then neutralize tool naming.
  local body; body="$(agent_body "$agent_file")"
  local _body_tmp; _body_tmp="$(mktemp)"
  printf '%s\n' "$body" > "$_body_tmp"
  rewrite_codex_paths "$_body_tmp"
  rewrite_tool_compat "$_body_tmp"
  body="$(cat "$_body_tmp")"
  rm -f "$_body_tmp"

  local out_dir="$dst_root/.codex/agents"
  mkdir -p "$out_dir"
  local out_file="$out_dir/${name}.toml"

  # Choose multiline literal (''') vs basic (""") based on body content (T-01-04)
  if [[ "$body" == *"'''"* ]]; then
    # Fallback: use multiline basic string, escape backslashes and double-quotes
    local escaped_body; escaped_body="${body//\\/\\\\}"
    escaped_body="${escaped_body//\"/\\\"}"
    {
      printf 'name = "%s"\n' "$(_cc_toml_escape_dquote_string "$name")"
      printf 'description = "%s"\n' "$desc_escaped"
      printf 'model = "%s"\n' "$(_cc_toml_escape_dquote_string "$model")"
      printf 'model_reasoning_effort = "%s"\n' "$model_reasoning_effort"
      printf 'sandbox_mode = "%s"\n' "$sandbox_mode"
      printf 'developer_instructions = """\n'
      printf '%s\n' "$escaped_body"
      printf '"""\n'
    } > "$out_file"
  else
    # Preferred: multiline literal string — no escaping needed
    {
      printf 'name = "%s"\n' "$(_cc_toml_escape_dquote_string "$name")"
      printf 'description = "%s"\n' "$desc_escaped"
      printf 'model = "%s"\n' "$(_cc_toml_escape_dquote_string "$model")"
      printf 'model_reasoning_effort = "%s"\n' "$model_reasoning_effort"
      printf 'sandbox_mode = "%s"\n' "$sandbox_mode"
      printf "developer_instructions = '''\n"
      printf '%s\n' "$body"
      printf "'''\n"
    } > "$out_file"
  fi
}

# adapter_translate_agents_toml <source_agents_dir> <dest_root>
# Iterates over all *.md agent files and calls adapter_translate_agent_toml for each.
adapter_translate_agents_toml() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  while IFS= read -r agent; do
    [[ -f "$agent" ]] || continue
    should_include "$agent" "$CC_PLATFORM" || continue
    adapter_translate_agent_toml "$agent" "$dst"
  done < <(enumerate_agents "$src")
}

# adapter_build <source_dir> <dest_dir>
# The single entry point invoked by scripts/build.sh.
# Writes into $DIST_DIR/codex-cli/ (dest_dir is already platform-scoped).
adapter_build() {
  local src="$1" dst="$2"
  local OUT_DIR="$dst"

  # Delete and recreate the platform output directory (scoped; T-01-03 accepted)
  rm -rf "$OUT_DIR"
  mkdir -p "$OUT_DIR"

  adapter_translate_dispatcher   "$src/DISPATCHER.md" "$OUT_DIR"
  adapter_translate_references   "$src/references"    "$OUT_DIR"
  adapter_translate_skills       "$src/skills"        "$OUT_DIR"
  adapter_translate_config       "$src/mcp"           "$OUT_DIR"
  adapter_translate_agents_toml  "$src/agents"        "$OUT_DIR"
}
