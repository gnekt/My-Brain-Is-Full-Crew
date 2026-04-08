#!/usr/bin/env bash
# =============================================================================
# adapters/claude-code/adapter.sh — Claude Code framework adapter
# =============================================================================
# Sourced by scripts/build.sh AFTER adapters/lib.sh.
# Translates source files into a dist/claude-code/ tree that mirrors what
# Claude Code expects in the user's vault.
# =============================================================================

FRAMEWORK="claude-code"

# Capability → CC tools mapping. Each capability expands into one or more
# Claude Code tool names. The expansion is order-preserving.
cc_capability_to_tools() {
  local cap="$1"
  case "$cap" in
    read)      echo "Read" ;;
    write)     echo "Write" ;;
    edit)      echo "Edit" ;;
    bash)      echo "Bash" ;;
    webfetch)  echo "WebFetch" ;;
    websearch) echo "WebSearch" ;;
    notebook)  echo "NotebookEdit" ;;
    task)      echo "Task" ;;
    todo)      echo "TodoWrite" ;;
    *)         echo "" ;;
  esac
}

# Event vocabulary → CC native event mapping.
cc_event_to_native() {
  local event="$1"
  case "$event" in
    before-tool-use)  echo "PreToolUse" ;;
    after-tool-use)   echo "PostToolUse" ;;
    on-notification)  echo "Notification" ;;
    on-session-start) echo "SessionStart" ;;
    on-prompt-submit) echo "UserPromptSubmit" ;;
    *)                echo "" ;;
  esac
}

# adapter_finalize <source_root> <dest_root>
# Writes any framework-specific top-level files (plugin manifest, etc.).
adapter_finalize() {
  local src="$1" dst="$2"
  if [[ -f "$src/.claude-plugin/plugin.json" ]]; then
    mkdir -p "$dst/.claude-plugin"
    cp "$src/.claude-plugin/plugin.json" "$dst/.claude-plugin/plugin.json"
  fi
}

# adapter_translate_mcp <source_mcp_dir> <dest_root>
# Reads mcp/servers.yaml and writes dst/.mcp.json with mcpServers key.
adapter_translate_mcp() {
  local src="$1" dst="$2"
  local yaml="$src/servers.yaml"
  [[ -f "$yaml" ]] || return 0

  local out="$dst/.mcp.json"
  mkdir -p "$dst"

  # Parse the YAML into a JSON object {server_name: {command, args, env}}
  local json='{}'
  local current_name="" current_cmd="" current_url="" current_type=""

  while IFS= read -r line; do
    case "$line" in
      *"- name:"*)
        # Flush previous server
        if [[ -n "$current_name" ]]; then
          if [[ -n "$current_cmd" ]]; then
            local first_arg="${current_cmd%% *}"
            local rest="${current_cmd#* }"
            local args_json='[]'
            if [[ "$rest" != "$current_cmd" ]]; then
              args_json="$(echo "$rest" | jq -R 'split(" ")')"
            fi
            json="$(echo "$json" | jq --arg n "$current_name" --arg c "$first_arg" --argjson a "$args_json" '.[$n] = {command: $c, args: $a, env: {}}')"
          elif [[ -n "$current_url" ]]; then
            json="$(echo "$json" | jq --arg n "$current_name" --arg u "$current_url" --arg t "$current_type" '.[$n] = {type: $t, url: $u}')"
          fi
        fi
        current_name="$(echo "$line" | sed 's/.*- name:[[:space:]]*//' | tr -d '"')"
        current_cmd=""
        current_url=""
        current_type="http"
        ;;
      *"command:"*"["*)
        current_cmd="$(echo "$line" | sed 's/.*command:[[:space:]]*\[//' | sed 's/\][[:space:]]*$//' | tr -d '"' | sed 's/,[[:space:]]*/\ /g')"
        ;;
      *"url:"*)
        current_url="$(echo "$line" | sed 's/.*url:[[:space:]]*//' | tr -d '"')"
        ;;
      *"type:"*)
        current_type="$(echo "$line" | sed 's/.*type:[[:space:]]*//' | tr -d '"')"
        ;;
    esac
  done < "$yaml"

  # Flush the last server
  if [[ -n "$current_name" ]]; then
    if [[ -n "$current_cmd" ]]; then
      local first_arg="${current_cmd%% *}"
      local rest="${current_cmd#* }"
      local args_json='[]'
      if [[ "$rest" != "$current_cmd" ]]; then
        args_json="$(echo "$rest" | jq -R 'split(" ")')"
      fi
      json="$(echo "$json" | jq --arg n "$current_name" --arg c "$first_arg" --argjson a "$args_json" '.[$n] = {command: $c, args: $a, env: {}}')"
    elif [[ -n "$current_url" ]]; then
      json="$(echo "$json" | jq --arg n "$current_name" --arg u "$current_url" --arg t "$current_type" '.[$n] = {type: $t, url: $u}')"
    fi
  fi

  echo "$json" | jq '{mcpServers: .}' > "$out"
}

# Helper: convert match-tool tokens to CC matcher syntax (e.g., "edit write" → "Edit|Write")
cc_match_tool_to_matcher() {
  local tokens="$1"
  local matcher=""
  for t in $tokens; do
    local cap_t
    cap_t="$(echo "$t" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
    if [[ -z "$matcher" ]]; then
      matcher="$cap_t"
    else
      matcher="$matcher|$cap_t"
    fi
  done
  echo "$matcher"
}

# adapter_translate_hooks <source_hooks_dir> <dest_root>
adapter_translate_hooks() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out_dir="$dst/.claude/hooks"
  mkdir -p "$out_dir"

  local template; template="$(dirname "${BASH_SOURCE[0]}")/templates/cc-hook-wrapper.sh.tmpl"

  # Accumulate hook entries here, by event type
  local pre_entries="" post_entries="" notif_entries="" sess_entries="" prompt_entries=""

  while IFS= read -r yaml; do
    [[ -z "$yaml" ]] && continue
    should_include "$yaml" "$FRAMEWORK" || continue
    local meta; meta="$(parse_hook_yaml "$yaml")"
    local name; name="$(echo "$meta" | grep '^name=' | head -1 | cut -d= -f2- || true)"
    local script; script="$(echo "$meta" | grep '^script=' | head -1 | cut -d= -f2- || true)"
    local event; event="$(echo "$meta" | grep '^event=' | head -1 | cut -d= -f2- || true)"
    local match_tool; match_tool="$(echo "$meta" | grep '^match-tool=' | head -1 | cut -d= -f2- || true)"

    # Copy the bash script
    cp "$src/$script" "$out_dir/$script"
    chmod +x "$out_dir/$script"

    # Generate the wrapper
    local wrapper_file="$out_dir/${name}-wrapper.sh"
    local cc_event; cc_event="$(cc_event_to_native "$event")"
    sed -e "s/__HOOK_NAME__/$name/g" -e "s/__EVENT_NAME__/$event/g" "$template" > "$wrapper_file"
    chmod +x "$wrapper_file"

    # Build the settings.json entry for this hook
    local matcher=""
    [[ -n "$match_tool" ]] && matcher="$(cc_match_tool_to_matcher "$match_tool")"
    local entry; entry="$(jq -cn \
      --arg cmd ".claude/hooks/${name}-wrapper.sh" \
      --arg matcher "$matcher" \
      '{matcher: $matcher, hooks: [{type: "command", command: ("bash " + $cmd)}]}')"

    case "$cc_event" in
      PreToolUse)        pre_entries="$pre_entries$entry"$'\n' ;;
      PostToolUse)       post_entries="$post_entries$entry"$'\n' ;;
      Notification)      notif_entries="$notif_entries$entry"$'\n' ;;
      SessionStart)      sess_entries="$sess_entries$entry"$'\n' ;;
      UserPromptSubmit)  prompt_entries="$prompt_entries$entry"$'\n' ;;
    esac
  done < <(enumerate_hooks "$src")

  # Compose the final settings.json
  local settings; settings='{"hooks":{}}'
  for ev_pair in "PreToolUse:$pre_entries" "PostToolUse:$post_entries" "Notification:$notif_entries" "SessionStart:$sess_entries" "UserPromptSubmit:$prompt_entries"; do
    local ev_name="${ev_pair%%:*}"
    local ev_data="${ev_pair#*:}"
    [[ -z "$ev_data" ]] && continue
    local arr; arr="$(echo "$ev_data" | jq -cs '.')"
    settings="$(echo "$settings" | jq --arg ev "$ev_name" --argjson arr "$arr" '.hooks[$ev] = $arr')"
  done

  mkdir -p "$dst/.claude"
  echo "$settings" | jq '.' > "$dst/.claude/settings.json"
}

# adapter_translate_agents <source_agents_dir> <dest_root>
# For each *.md in source_agents_dir, translate the capabilities frontmatter
# into a CC tools: allowlist and write to dest_root/.claude/agents/<name>.md.
adapter_translate_agents() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out_dir="$dst/.claude/agents"
  mkdir -p "$out_dir"

  while IFS= read -r agent; do
    [[ -z "$agent" ]] && continue
    should_include "$agent" "$FRAMEWORK" || continue
    local name; name="$(parse_frontmatter "$agent" name)"
    local model; model="$(parse_frontmatter "$agent" model)"
    local caps; caps="$(parse_capabilities "$agent")"

    # Build tools allowlist by expanding each capability.
    # read → Read (only); Glob and Grep are appended at the end if read is present.
    local tools="" has_read=0
    for cap in $caps; do
      [[ "$cap" == "read" ]] && has_read=1
      local expansion; expansion="$(cc_capability_to_tools "$cap")"
      [[ -n "$expansion" ]] || continue
      for tool in $expansion; do
        if [[ -z "$tools" ]]; then
          tools="$tool"
        else
          tools="$tools, $tool"
        fi
      done
    done
    # Append Glob and Grep after all other tools when read capability is present
    if [[ $has_read -eq 1 ]]; then
      tools="$tools, Glob, Grep"
    fi

    local out_file="$out_dir/$(basename "$agent")"
    {
      echo "---"
      echo "name: $name"
      # Copy description block (may be folded YAML with continuation lines)
      awk '/^---$/{n++; next} n==1 && /^description:/{print; in_desc=1; next} n==1 && in_desc && /^[[:space:]]/{print; next} n==1 && in_desc && !/^[[:space:]]/{in_desc=0} n>=2{exit}' "$agent"
      echo "tools: $tools"
      echo "model: $model"
      echo "---"
      agent_body "$agent"
    } > "$out_file"
  done < <(enumerate_agents "$src")
}

# adapter_translate_skills <source_skills_dir> <dest_root>
# Copies each skill directory's SKILL.md into dest_root/.claude/skills/<name>/.
adapter_translate_skills() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  for skill_dir in "$src"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    should_include "${skill_dir}SKILL.md" "$FRAMEWORK" || continue
    local name; name="$(basename "$skill_dir")"
    local out="$dst/.claude/skills/$name"
    mkdir -p "$out"
    cp "${skill_dir}SKILL.md" "$out/SKILL.md"
  done
}

# adapter_translate_references <source_refs_dir> <dest_root>
# Verbatim copy of *.md into dest_root/.claude/references/.
adapter_translate_references() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out="$dst/.claude/references"
  mkdir -p "$out"
  for f in "$src"/*.md; do
    [[ -f "$f" ]] || continue
    should_include "$f" "$FRAMEWORK" || continue
    cp "$f" "$out/"
  done
}

# adapter_translate_dispatcher <source_dispatcher_md> <dest_dir>
# Copies the source DISPATCHER.md to dest_dir/CLAUDE.md (no content change).
adapter_translate_dispatcher() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  mkdir -p "$dst"
  cp "$src" "$dst/CLAUDE.md"
}

# adapter_build <source_dir> <dest_dir>
# The single entry point invoked by scripts/build.sh.
adapter_build() {
  local src="$1" dst="$2"
  rm -rf "$dst"
  mkdir -p "$dst"
  adapter_translate_dispatcher "$src/DISPATCHER.md" "$dst"
  adapter_translate_references "$src/references" "$dst"
  adapter_translate_skills     "$src/skills"     "$dst"
  adapter_translate_agents     "$src/agents"     "$dst"
  adapter_translate_hooks      "$src/hooks"      "$dst"
  adapter_translate_mcp        "$src/mcp"        "$dst"
  adapter_finalize             "$src"            "$dst"
}
