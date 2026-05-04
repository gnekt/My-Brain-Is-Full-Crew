#!/usr/bin/env bash
# =============================================================================
# adapters/gemini-cli/adapter.sh — Gemini CLI framework adapter
# =============================================================================
# Sourced by scripts/build.sh AFTER adapters/lib.sh.
# Translates source files into a dist/gemini-cli/ tree that mirrors what
# Gemini CLI expects in the user's project.
# =============================================================================

GEMINI_PLATFORM="gemini-cli"
GEMINI_FW_DIR="gemini"
GEMINI_DISPATCHER="GEMINI.md"

# Capability → Gemini CLI tool names. Returns space-separated tool names.
gemini_capability_to_tools() {
  local cap="$1"
  case "$cap" in
    read)      echo "read_file list_directory grep_search" ;;
    write)     echo "write_file" ;;
    edit)      echo "replace" ;;
    bash)      echo "run_shell_command" ;;
    webfetch)  echo "web_fetch" ;;
    websearch) echo "web_search" ;;
    notebook)  echo "" ;;
    task)      echo "activate_skill" ;;
    todo)      echo "" ;;
    *)         echo "" ;;
  esac
}

# Event vocabulary → Gemini CLI native event name.
gemini_event_to_native() {
  local event="$1"
  case "$event" in
    before-tool-use)  echo "BeforeTool" ;;
    after-tool-use)   echo "AfterTool" ;;
    on-notification)  echo "Notification" ;;
    on-session-start) echo "SessionStart" ;;
    on-prompt-submit) echo "BeforeAgent" ;;
    *)                echo "" ;;
  esac
}

# Neutral model tier → Gemini model name.
gemini_model_to_native() {
  local model="$1"
  case "$model" in
    */*)   echo "$model" ;;
    low)   echo "gemini-2.5-flash" ;;
    mid)   echo "gemini-2.5-flash" ;;
    high)  echo "gemini-2.5-pro" ;;
    *)     echo "$model" ;;
  esac
}

# Match-tool token → Gemini tool name for hook matchers.
gemini_match_tool_to_native() {
  local token="$1"
  case "$token" in
    read)   echo "read_file" ;;
    write)  echo "write_file" ;;
    edit)   echo "replace" ;;
    bash)   echo "run_shell_command" ;;
    *)      echo "$token" ;;
  esac
}

# adapter_translate_dispatcher <source_dispatcher_md> <dest_dir>
# Copies the source DISPATCHER.md to dest_dir/GEMINI.md (no content change).
adapter_translate_dispatcher() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  mkdir -p "$dst"
  cp "$src" "$dst/$GEMINI_DISPATCHER"
  rewrite_platform_paths "$dst/$GEMINI_DISPATCHER" "$GEMINI_FW_DIR" "$GEMINI_DISPATCHER"
}

# adapter_translate_references <source_refs_dir> <dest_root>
adapter_translate_references() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out="$dst/.$GEMINI_FW_DIR/references"
  mkdir -p "$out"
  for f in "$src"/*.md; do
    [[ -f "$f" ]] || continue
    should_include "$f" "$GEMINI_PLATFORM" || continue
    cp "$f" "$out/"
    rewrite_platform_paths "$out/$(basename "$f")" "$GEMINI_FW_DIR" "$GEMINI_DISPATCHER"
  done
}

# adapter_translate_skills <source_skills_dir> <dest_root>
adapter_translate_skills() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  for skill_dir in "$src"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    should_include "${skill_dir}SKILL.md" "$GEMINI_PLATFORM" || continue
    local name; name="$(basename "$skill_dir")"
    local out="$dst/.$GEMINI_FW_DIR/skills/$name"
    mkdir -p "$out"
    cp "${skill_dir}SKILL.md" "$out/SKILL.md"
    rewrite_platform_paths "$out/SKILL.md" "$GEMINI_FW_DIR" "$GEMINI_DISPATCHER"
  done
}

# adapter_translate_agents <source_agents_dir> <dest_root>
adapter_translate_agents() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out_dir="$dst/.$GEMINI_FW_DIR/agents"
  mkdir -p "$out_dir"

  while IFS= read -r agent; do
    [[ -f "$agent" ]] || continue
    should_include "$agent" "$GEMINI_PLATFORM" || continue

    local name; name="$(parse_frontmatter "$agent" name)"
    local model_raw; model_raw="$(parse_frontmatter "$agent" model)"
    local caps; caps="$(parse_capabilities "$agent")"

    local model_out; model_out="$(gemini_model_to_native "$model_raw")"

    # Build deduplicated tools list
    local tools_seen="" tools_yaml=""
    for cap in $caps; do
      local expansion; expansion="$(gemini_capability_to_tools "$cap")"
      for tool in $expansion; do
        [[ -z "$tool" ]] && continue
        case " $tools_seen " in
          *" $tool "*) ;;
          *)
            tools_seen="$tools_seen $tool"
            tools_yaml="${tools_yaml}  - ${tool}
"
            ;;
        esac
      done
    done

    local out_file="$out_dir/$(basename "$agent")"
    {
      echo "---"
      echo "name: $name"
      # Copy description block (may be folded YAML)
      awk '{ sub(/\r$/, "") } /^---$/{n++; next} n==1 && /^description:/{print; in_desc=1; next} n==1 && in_desc && /^[[:space:]]/{print; next} n==1 && in_desc && !/^[[:space:]]/{in_desc=0} n>=2{exit}' "$agent"
      echo "tools:"
      printf '%s' "$tools_yaml"
      echo "model: $model_out"
      echo "---"
      agent_body "$agent"
    } > "$out_file"
    rewrite_platform_paths "$out_file" "$GEMINI_FW_DIR" "$GEMINI_DISPATCHER"
  done < <(enumerate_agents "$src")
}

# adapter_translate_hooks <source_hooks_dir> <dest_root>
adapter_translate_hooks() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0

  local hooks_out="$dst/.$GEMINI_FW_DIR/hooks"
  mkdir -p "$hooks_out"

  local tpl_dir; tpl_dir="$(dirname "${BASH_SOURCE[0]}")/templates"
  local hooks_json='{}'
  local have_any=0

  while IFS= read -r yaml; do
    [[ -f "$yaml" ]] || continue
    should_include "$yaml" "$GEMINI_PLATFORM" || continue

    local meta; meta="$(parse_hook_yaml "$yaml")"
    local hook_name; hook_name="$(echo "$meta" | grep '^name=' | head -1 | cut -d= -f2-)"
    local script; script="$(echo "$meta" | grep '^script=' | head -1 | cut -d= -f2-)"
    local event; event="$(echo "$meta" | grep '^event=' | head -1 | cut -d= -f2-)"
    local match_tool; match_tool="$(echo "$meta" | grep '^match-tool=' | head -1 | cut -d= -f2- || true)"

    [[ -f "$src/$script" ]] || continue

    # Copy the hook script
    cp "$src/$script" "$hooks_out/$script"
    chmod +x "$hooks_out/$script"
    rewrite_platform_paths "$hooks_out/$script" "$GEMINI_FW_DIR" "$GEMINI_DISPATCHER"

    # Generate wrapper script from template
    local wrapper_name="${hook_name}-wrapper.sh"
    sed -e "s/__HOOK_NAME__/$hook_name/g" -e "s/__EVENT_NAME__/$event/g" \
      "$tpl_dir/gemini-hook-wrapper.sh.tmpl" > "$hooks_out/$wrapper_name"
    chmod +x "$hooks_out/$wrapper_name"

    # Build matcher: map each match-tool token to Gemini tool name
    local gemini_event; gemini_event="$(gemini_event_to_native "$event")"
    local matcher=""
    if [[ -n "$match_tool" ]]; then
      for t in $match_tool; do
        local native; native="$(gemini_match_tool_to_native "$t")"
        if [[ -z "$matcher" ]]; then
          matcher="$native"
        else
          matcher="$matcher|$native"
        fi
      done
    fi

    # Add to hooks JSON
    local hook_cmd="bash .$GEMINI_FW_DIR/hooks/$wrapper_name"
    if [[ -n "$matcher" ]]; then
      hooks_json="$(echo "$hooks_json" | jq \
        --arg ev "$gemini_event" \
        --arg matcher "$matcher" \
        --arg cmd "$hook_cmd" \
        '.hooks[$ev] += [{ matcher: $matcher, hooks: [{ type: "command", command: $cmd, timeout: 5000 }] }]')"
    else
      hooks_json="$(echo "$hooks_json" | jq \
        --arg ev "$gemini_event" \
        --arg cmd "$hook_cmd" \
        '.hooks[$ev] += [{ hooks: [{ type: "command", command: $cmd, timeout: 5000 }] }]')"
    fi
    have_any=1
  done < <(enumerate_hooks "$src")

  if [[ $have_any -eq 0 ]]; then
    rmdir "$hooks_out" 2>/dev/null || true
    return 0
  fi

  echo "$hooks_json" | jq '.' > "$dst/.$GEMINI_FW_DIR/_hooks.json"
}

# adapter_translate_mcp <source_mcp_dir> <dest_root>
adapter_translate_mcp() {
  local src="$1" dst="$2"
  local yaml="$src/servers.yaml"
  [[ -f "$yaml" ]] || return 0

  mkdir -p "$dst/.$GEMINI_FW_DIR"

  local json='{}'
  local current_name="" current_cmd="" current_url="" current_type=""

  _gemini_flush_mcp() {
    [[ -z "$current_name" ]] && return 0
    if [[ "$current_type" == "local" || -n "$current_cmd" ]]; then
      local cmd_first; cmd_first="$(echo "$current_cmd" | awk '{print $1}')"
      local cmd_rest; cmd_rest="$(echo "$current_cmd" | awk '{$1=""; print}' | sed 's/^ *//')"
      local args_json; args_json="$(echo "$cmd_rest" | jq -R 'split(" ") | map(select(length > 0))')"
      json="$(echo "$json" | jq --arg n "$current_name" --arg c "$cmd_first" --argjson a "$args_json" \
        '.mcpServers[$n] = {command: $c, args: $a}')"
    else
      json="$(echo "$json" | jq --arg n "$current_name" --arg u "$current_url" \
        '.mcpServers[$n] = {url: $u}')"
    fi
  }

  while IFS= read -r line; do
    case "$line" in
      *"- name:"*)
        _gemini_flush_mcp
        current_name="$(echo "$line" | sed 's/.*- name:[[:space:]]*//' | tr -d '"')"
        current_cmd="" ; current_url="" ; current_type=""
        ;;
      *"type:"*)
        current_type="$(echo "$line" | sed 's/.*type:[[:space:]]*//' | tr -d '"')"
        ;;
      *"command:"*"["*)
        current_cmd="$(echo "$line" | sed 's/.*command:[[:space:]]*\[//' | sed 's/\][[:space:]]*$//' | tr -d '"' | sed 's/,[[:space:]]*/  /g')"
        ;;
      *"url:"*)
        current_url="$(echo "$line" | sed 's/.*url:[[:space:]]*//' | tr -d '"')"
        ;;
    esac
  done < "$yaml"
  _gemini_flush_mcp

  echo "$json" | jq '.' > "$dst/.$GEMINI_FW_DIR/_mcp.json"
  unset -f _gemini_flush_mcp
}

# adapter_finalize <source_root> <dest_root>
adapter_finalize() {
  local src="$1" dst="$2"
  local gemini_dir="$dst/.$GEMINI_FW_DIR"
  local hooks_tmp="$gemini_dir/_hooks.json"
  local mcp_tmp="$gemini_dir/_mcp.json"
  local settings="$gemini_dir/settings.json"

  local result='{}'

  if [[ -f "$hooks_tmp" ]]; then
    result="$(echo "$result" | jq --slurpfile h "$hooks_tmp" '. + $h[0]')"
    rm "$hooks_tmp"
  fi

  if [[ -f "$mcp_tmp" ]]; then
    result="$(echo "$result" | jq --slurpfile m "$mcp_tmp" '. + $m[0]')"
    rm "$mcp_tmp"
  fi

  if [[ "$result" != "{}" ]]; then
    echo "$result" | jq '.' > "$settings"
  fi
}

# adapter_build <source_dir> <dest_dir>
# The single entry point invoked by scripts/build.sh.
adapter_build() {
  local src="$1" dst="$2"
  rm -rf "$dst"
  mkdir -p "$dst"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  adapter_translate_references "$src/references"  "$dst"
  adapter_translate_skills     "$src/skills"      "$dst"
  adapter_translate_agents     "$src/agents"      "$dst"
  adapter_translate_hooks      "$src/hooks"       "$dst"
  adapter_translate_mcp        "$src/mcp"         "$dst"
  adapter_finalize             "$src"             "$dst"
}
