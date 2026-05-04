#!/usr/bin/env bash
# =============================================================================
# adapters/opencode/adapter.sh — Opencode framework adapter
# =============================================================================
# Sourced by scripts/build.sh AFTER adapters/lib.sh.
# Translates source files into a dist/opencode/ tree that mirrors what
# opencode expects in the user's vault.
# =============================================================================

# shellcheck source=adapters/opencode/config-merge.sh
source "$(dirname "${BASH_SOURCE[0]}")/config-merge.sh"

OC_PLATFORM="opencode"
OC_FW_DIR="opencode"
OC_DISPATCHER="AGENTS.md"

# Capability → opencode permission key. Returns the permission key to set to
# "allow" for each capability, or empty string for capabilities that have no
# opencode equivalent (they are dropped).
#
# Reference (spec §"Capability vocabulary"):
#   read       → implicit, no permission needed
#   write      → edit: allow
#   edit       → edit: allow
#   bash       → bash: allow
#   webfetch   → webfetch: allow
#   websearch  → drop (no equivalent)
#   notebook   → drop
#   task       → drop (subagent invocation, not a permission)
#   todo       → drop
oc_capability_to_permission() {
  local cap="$1"
  case "$cap" in
    read)      echo "" ;;           # implicit
    write)     echo "edit" ;;
    edit)      echo "edit" ;;
    bash)      echo "bash" ;;
    webfetch)  echo "webfetch" ;;
    websearch) echo "" ;;           # drop
    notebook)  echo "" ;;           # drop
    task)      echo "" ;;           # drop
    todo)      echo "" ;;           # drop
    *)         echo "" ;;
  esac
}

# Event vocabulary → opencode native event name.
oc_event_to_native() {
  local event="$1"
  case "$event" in
    before-tool-use)  echo "tool.execute.before" ;;
    after-tool-use)   echo "tool.execute.after" ;;
    on-notification)  echo "session.idle" ;;
    on-session-start) echo "session.created" ;;
    on-prompt-submit) echo "tui.prompt.append" ;;
    *)                echo "" ;;
  esac
}

# Neutral model tier → opencode provider/model id. Conservative mapping:
# if the source model is already provider-prefixed (contains "/"), pass through
# unchanged. Otherwise look up in the table and fall back to the raw value.
oc_model_to_provider() {
  local model="$1"
  case "$model" in
    */*)   echo "$model" ;;                               # already qualified
    low)   echo "anthropic/claude-haiku-4-5" ;;
    mid)   echo "anthropic/claude-sonnet-4-5" ;;
    high)  echo "anthropic/claude-opus-4-5" ;;
    *)     echo "$model" ;;                               # unknown — passthrough
  esac
}

# adapter_translate_dispatcher <source_dispatcher_md> <dest_dir>
# Copies the source DISPATCHER.md to dest_dir/AGENTS.md (opencode's vault-root
# dispatcher filename). Rewrites .platform/ and DISPATCHER.md to opencode paths.
adapter_translate_dispatcher() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  mkdir -p "$dst"
  cp "$src" "$dst/AGENTS.md"
  rewrite_platform_paths "$dst/AGENTS.md" "$OC_FW_DIR" "$OC_DISPATCHER"
}

# adapter_translate_references <source_refs_dir> <dest_root>
# Copies *.md into dest_root/.opencode/references/, rewriting framework paths.
adapter_translate_references() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out="$dst/.opencode/references"
  mkdir -p "$out"
  for f in "$src"/*.md; do
    [[ -f "$f" ]] || continue
    should_include "$f" "$OC_PLATFORM" || continue
    cp "$f" "$out/"
    rewrite_platform_paths "$out/$(basename "$f")" "$OC_FW_DIR" "$OC_DISPATCHER"
  done
}

# adapter_translate_skills <source_skills_dir> <dest_root>
# Copies each skill directory's SKILL.md into dest_root/.opencode/skills/<name>/,
# rewriting framework paths in the body.
adapter_translate_skills() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  for skill_dir in "$src"/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    should_include "${skill_dir}SKILL.md" "$OC_PLATFORM" || continue
    local name; name="$(basename "$skill_dir")"
    local out="$dst/.opencode/skills/$name"
    mkdir -p "$out"
    cp "${skill_dir}SKILL.md" "$out/SKILL.md"
    rewrite_platform_paths "$out/SKILL.md" "$OC_FW_DIR" "$OC_DISPATCHER"
  done
}

# adapter_translate_agents <source_agents_dir> <dest_root>
# For each *.md in source_agents_dir, translate the capabilities frontmatter
# into an opencode permission block, map the model, and write to
# dest_root/.opencode/agents/<name>.md.
adapter_translate_agents() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  local out_dir="$dst/.opencode/agents"
  mkdir -p "$out_dir"

  while IFS= read -r agent; do
    [[ -f "$agent" ]] || continue
    should_include "$agent" "$OC_PLATFORM" || continue

    local model_raw; model_raw="$(parse_frontmatter "$agent" model)"
    local mode_raw; mode_raw="$(parse_frontmatter "$agent" mode)"
    local caps; caps="$(parse_capabilities "$agent")"

    local model_out; model_out="$(oc_model_to_provider "$model_raw")"
    local mode_out="${mode_raw:-subagent}"

    # Build a unique permission list
    local perms=""
    for cap in $caps; do
      local p; p="$(oc_capability_to_permission "$cap")"
      [[ -z "$p" ]] && continue
      # Dedupe: skip if already in $perms (space-delimited)
      case " $perms " in
        *" $p "*) ;;
        *) perms="$perms $p" ;;
      esac
    done
    perms="${perms# }"

    local out_file="$out_dir/$(basename "$agent")"
    {
      echo "---"
      # Copy description block verbatim (may be folded YAML with continuation lines)
      awk '{ sub(/\r$/, "") } /^---$/{n++; next} n==1 && /^description:/{print; in_desc=1; next} n==1 && in_desc && /^[[:space:]]/{print; next} n==1 && in_desc && !/^[[:space:]]/{in_desc=0} n>=2{exit}' "$agent"
      echo "mode: $mode_out"
      echo "model: $model_out"
      if [[ -z "$perms" ]]; then
        echo "permission: {}"
      else
        echo "permission:"
        for p in $perms; do
          echo "  $p: allow"
        done
      fi
      echo "---"
      echo ""
      agent_body "$agent"
    } > "$out_file"
    rewrite_platform_paths "$out_file" "$OC_FW_DIR" "$OC_DISPATCHER"
  done < <(enumerate_agents "$src")
}

# _oc_hook_registry_json <source_hooks_dir>
# Emits a JSON array literal representing the hook registry, suitable for
# substituting into the plugin template. Each entry: {name, script, triggers: [{event, matchTool}]}.
# Script paths are stored as "../hooks/<basename>" so the plugin (at .opencode/plugins/)
# can reach .opencode/hooks/ at runtime via __dirname + path join.
_oc_hook_registry_json() {
  local src="$1"
  local entries='[]'
  while IFS= read -r yaml; do
    [[ -f "$yaml" ]] || continue
    should_include "$yaml" "$OC_PLATFORM" || continue
    local meta; meta="$(parse_hook_yaml "$yaml")"
    local name; name="$(echo "$meta" | grep '^name=' | head -1 | cut -d= -f2-)"
    local script; script="$(echo "$meta" | grep '^script=' | head -1 | cut -d= -f2-)"
    local event; event="$(echo "$meta" | grep '^event=' | head -1 | cut -d= -f2-)"
    local match_tool; match_tool="$(echo "$meta" | grep '^match-tool=' | head -1 | cut -d= -f2- || true)"
    local oc_event; oc_event="$(oc_event_to_native "$event")"

    # Build the matchTool JSON array (empty array if no filter)
    local match_json='[]'
    if [[ -n "$match_tool" ]]; then
      match_json="$(echo "$match_tool" | jq -R 'split(" ") | map(select(length > 0))')"
    fi

    # Use ../hooks/<script> so the plugin at .opencode/plugins/ can resolve
    # its sibling .opencode/hooks/ directory at runtime.
    local script_rel="../hooks/$script"

    entries="$(echo "$entries" | jq \
      --arg name "$name" \
      --arg script "$script_rel" \
      --arg event "$oc_event" \
      --argjson match "$match_json" \
      '. += [{name: $name, script: $script, triggers: [{event: $event, matchTool: $match}]}]')"
  done < <(enumerate_hooks "$src")
  echo "$entries"
}

# adapter_translate_hooks <source_hooks_dir> <dest_root>
# Copies each hook's .sh script to dst/.opencode/hooks/ and generates a single
# dst/.opencode/plugins/mbifc-hooks.js plugin containing the vendored bash
# executor plus a hook registry synthesised from the source .hook.yaml files.
adapter_translate_hooks() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0

  local hooks_out="$dst/.opencode/hooks"
  local plugins_out="$dst/.opencode/plugins"
  mkdir -p "$hooks_out" "$plugins_out"

  # Copy every referenced .sh script
  local have_any=0
  while IFS= read -r yaml; do
    [[ -f "$yaml" ]] || continue
    should_include "$yaml" "$OC_PLATFORM" || continue
    local meta; meta="$(parse_hook_yaml "$yaml")"
    local script; script="$(echo "$meta" | grep '^script=' | head -1 | cut -d= -f2-)"
    [[ -f "$src/$script" ]] || continue
    cp "$src/$script" "$hooks_out/$script"
    chmod +x "$hooks_out/$script"
    rewrite_platform_paths "$hooks_out/$script" "$OC_FW_DIR" "$OC_DISPATCHER"
    have_any=1
  done < <(enumerate_hooks "$src")

  # If there were no hooks, skip plugin generation and clean up the empty dirs
  if [[ $have_any -eq 0 ]]; then
    rmdir "$hooks_out" "$plugins_out" 2>/dev/null || true
    return 0
  fi

  # Load templates
  local tpl_dir; tpl_dir="$(dirname "${BASH_SOURCE[0]}")/templates"

  # Build the registry JSON
  local registry; registry="$(_oc_hook_registry_json "$src")"

  # Pretty-print registry (2-space indent)
  local registry_pretty; registry_pretty="$(echo "$registry" | jq '.')"

  # Substitute placeholders by reading the template line-by-line.
  # We avoid sed/awk gsub because the replacement strings (JS code, JSON)
  # contain backslashes and ampersands that break regex replacement.
  local out="$plugins_out/mbifc-hooks.js"
  local executor_file="$tpl_dir/bash-executor.js"
  local stub_file="$tpl_dir/plugin-stub.js.tmpl"
  while IFS= read -r line; do
    case "$line" in
      *__BASH_EXECUTOR__*)
        cat "$executor_file"
        ;;
      *__HOOK_REGISTRY__*)
        # Replace the placeholder within the line (preserves "const HOOKS = " prefix)
        local prefix="${line%%__HOOK_REGISTRY__*}"
        local suffix="${line##*__HOOK_REGISTRY__}"
        printf '%s' "$prefix"
        printf '%s' "$registry_pretty"
        printf '%s\n' "$suffix"
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done < "$stub_file" > "$out"
}

# adapter_translate_mcp <source_mcp_dir> <dest_root>
# Reads mcp/servers.yaml and writes dst/opencode.json with a top-level "mcp" key.
# Local servers → {type: "local", command: "<joined>", environment: {}}
# HTTP servers  → {type: "remote", url: "..."}
adapter_translate_mcp() {
  local src="$1" dst="$2"
  local yaml="$src/servers.yaml"
  [[ -f "$yaml" ]] || return 0

  mkdir -p "$dst"
  local out="$dst/opencode.json"

  local json='{}'
  local current_name="" current_cmd="" current_url="" current_type=""

  _oc_flush_current() {
    [[ -z "$current_name" ]] && return 0
    if [[ "$current_type" == "local" || -n "$current_cmd" ]]; then
      local cmd_str="${current_cmd// / }"
      json="$(echo "$json" | jq --arg n "$current_name" --arg c "$cmd_str" \
        '.[$n] = {type: "local", command: $c, environment: {}}')"
    else
      json="$(echo "$json" | jq --arg n "$current_name" --arg u "$current_url" \
        '.[$n] = {type: "remote", url: $u}')"
    fi
  }

  while IFS= read -r line; do
    case "$line" in
      *"- name:"*)
        _oc_flush_current
        current_name="$(echo "$line" | sed 's/.*- name:[[:space:]]*//' | tr -d '"')"
        current_cmd=""
        current_url=""
        current_type=""
        ;;
      *"type:"*)
        current_type="$(echo "$line" | sed 's/.*type:[[:space:]]*//' | tr -d '"')"
        # Opencode uses "remote" for HTTP; normalise the source "http" → "remote"
        [[ "$current_type" == "http" ]] && current_type="remote"
        ;;
      *"command:"*"["*)
        current_cmd="$(echo "$line" | sed 's/.*command:[[:space:]]*\[//' | sed 's/\][[:space:]]*$//' | tr -d '"' | sed 's/,[[:space:]]*/  /g')"
        ;;
      *"url:"*)
        current_url="$(echo "$line" | sed 's/.*url:[[:space:]]*//' | tr -d '"')"
        ;;
    esac
  done < "$yaml"
  _oc_flush_current

  echo "$json" | jq '{mcp: .}' > "$out"
}

# adapter_finalize <source_root> <dest_root>
# Opencode has no per-framework manifest file; placeholder for future additions.
adapter_finalize() {
  local src="$1" dst="$2"
  return 0
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
