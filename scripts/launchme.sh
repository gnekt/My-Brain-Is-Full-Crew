#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Installer
# =============================================================================
# Run this from inside the cloned repo, which should be inside your vault:
#
#   cd /path/to/your-vault/My-Brain-Is-Full-Crew
#   bash scripts/launchme.sh
#
# =============================================================================

set -eo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
  RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
  GREEN=''; CYAN=''; YELLOW=''; RED=''; BOLD=''; DIM=''; NC=''
fi

info()    { echo -e "   ${CYAN}>${NC} $*"; }
success() { echo -e "   ${GREEN}✓${NC} $*"; }
warn()    { echo -e "   ${YELLOW}!${NC} $*"; }
die()     { echo -e "\n   ${RED}Error: $*${NC}\n" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: bash scripts/launchme.sh [options]

Options:
  --platform <claude|opencode|gemini|codex>  Install from build/<platform>/
  --vault <path>                             Install into a specific vault
  --yes                                      Accept defaults in non-interactive mode
  --model-fast <id>                          Override MODEL_FAST for platform installs
  --model-powerful <id>                      Override MODEL_POWERFUL for platform installs
  --model-light <id>                         Override MODEL_LIGHT for platform installs
  --overrides <file>                         Source model overrides from a file
  -h, --help                                 Show this help

Without --platform, interactive mode prompts for a platform. In --yes mode, it defaults to Claude Code.
EOF
}

validate_overrides_file() {
  local override_file="$1"
  local line_num=0

  [[ -f "$override_file" ]] || die "Overrides file not found: $override_file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))

    if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?(MODEL_FAST|MODEL_POWERFUL|MODEL_LIGHT)=\"?[A-Za-z0-9._:/@+-]+\"?[[:space:]]*$ ]]; then
      continue
    fi

    die "Invalid override in $override_file:$line_num. Only MODEL_FAST, MODEL_POWERFUL, and MODEL_LIGHT assignments are allowed."
  done < "$override_file"
}

load_model_values_from_file() {
  local override_file="$1"

  validate_overrides_file "$override_file"

  # shellcheck source=/dev/null
  source "$override_file"
}

write_model_overrides_file() {
  local target_file="$1"
  local platform_name="$2"
  local model_fast="$3"
  local model_powerful="$4"
  local model_light="$5"

  cat > "$target_file" <<EOF
# Installer-managed model preferences for $platform_name
MODEL_FAST=$model_fast
MODEL_POWERFUL=$model_powerful
MODEL_LIGHT=$model_light
EOF
}

rich_prompt() {
  local result_var="$1"
  local prompt_str="$2"
  local default_val="$3"
  shift 3
  local options=("$@")
  local tty_device="/dev/tty"
  local tty_fd=""

  if [[ ! -t 1 ]] || [[ ! -r "$tty_device" ]] || [[ ! -w "$tty_device" ]]; then
    local res
    if ! read -r -p "${prompt_str}" res 2>/dev/null; then
      printf -v "$result_var" '%s' "$default_val"
      return 1
    fi
    [[ -z "$res" ]] && res="$default_val"
    printf -v "$result_var" '%s' "$res"
    return 0
  fi

  exec {tty_fd}<> "$tty_device" || {
    local res
    if ! read -r -p "${prompt_str}" res 2>/dev/null; then
      printf -v "$result_var" '%s' "$default_val"
      return 1
    fi
    [[ -z "$res" ]] && res="$default_val"
    printf -v "$result_var" '%s' "$res"
    return 0
  }

  local current_input=""
  local opt_idx=-1
  local num_opts=${#options[@]}
  local cursor_pos=0
  local default_idx=-1
  local i=0

  for i in "${!options[@]}"; do
    if [[ "${options[$i]}" == "$default_val" ]]; then
      default_idx=$i
      break
    fi
  done

  draw() {
    printf "\r\e[K%s" "$prompt_str" >&$tty_fd
    if [[ -z "$current_input" && -n "$default_val" ]]; then
      printf "\e[90m%s\e[0m" "$default_val" >&$tty_fd
      printf "\r\e[%dC" "${#prompt_str}" >&$tty_fd
    else
      printf "%s" "$current_input" >&$tty_fd
      local total_len=$((${#prompt_str} + cursor_pos))
      if [[ $total_len -gt 0 ]]; then
        printf "\r\e[%dC" "$total_len" >&$tty_fd
      else
        printf "\r" >&$tty_fd
      fi
    fi
  }

  draw

  local c=""
  local esc=""
  local esc_1=""
  local esc_2=""
  while IFS= read -r -s -n1 -u "$tty_fd" c 2>/dev/null; do
    if [[ "$c" == $'\e' ]]; then
      esc=""
      esc_1=""
      esc_2=""
      if IFS= read -r -s -n1 -t 0.05 -u "$tty_fd" esc_1 2>/dev/null; then
        esc+="$esc_1"
        if IFS= read -r -s -n1 -t 0.05 -u "$tty_fd" esc_2 2>/dev/null; then
          esc+="$esc_2"
        fi
      fi

      if [[ "$esc" == "[A" ]]; then # up
        if [[ $num_opts -gt 0 ]]; then
          if [[ $opt_idx -lt 0 && $default_idx -ge 0 ]]; then
            opt_idx=$default_idx
          fi
          opt_idx=$(( (opt_idx - 1 + num_opts) % num_opts ))
          current_input="${options[$opt_idx]}"
          cursor_pos=${#current_input}
        fi
      elif [[ "$esc" == "[B" ]]; then # down
        if [[ $num_opts -gt 0 ]]; then
          if [[ $opt_idx -lt 0 && $default_idx -ge 0 ]]; then
            opt_idx=$default_idx
          fi
          opt_idx=$(( (opt_idx + 1) % num_opts ))
          current_input="${options[$opt_idx]}"
          cursor_pos=${#current_input}
        fi
      elif [[ "$esc" == "[D" ]]; then # left
        [[ $cursor_pos -gt 0 ]] && ((cursor_pos--))
      elif [[ "$esc" == "[C" ]]; then # right
        [[ $cursor_pos -lt ${#current_input} ]] && ((cursor_pos++))
      fi
    elif [[ "$c" == $'\177' || "$c" == $'\b' ]]; then
      if [[ $cursor_pos -gt 0 ]]; then
        current_input="${current_input:0:$((cursor_pos-1))}${current_input:$cursor_pos}"
        ((cursor_pos--))
      fi
    elif [[ "$c" == "" || "$c" == $'\n' || "$c" == $'\r' ]]; then
      break
    else
      current_input="${current_input:0:$cursor_pos}${c}${current_input:$cursor_pos}"
      ((cursor_pos++))
    fi
    draw
  done

  echo "" >&$tty_fd
  exec {tty_fd}>&-
  if [[ -z "$current_input" ]]; then
    current_input="$default_val"
  fi
  printf -v "$result_var" '%s' "$current_input"
  return 0
}

prompt_with_default() {
  local result_var="$1"
  local label="$2"
  local current_value="$3"
  local platform_default="$4"
  local response=""
  local -a options

  echo -e "   ${BOLD}${label}${NC}" >&2
  echo -e "   ${DIM}Use Up/Down arrows to select, or type a custom model.${NC}" >&2

  add_option() {
    local val="$1"
    if [[ -z "$val" ]]; then return; fi

    for existing in "${options[@]}"; do
      if [[ "$existing" == "$val" ]]; then
        return
      fi
    done

    local ann_str=""
    local -a annotations=()
    local is_primary=0
    [[ "$val" == "$current_value" ]] && { annotations+=("current"); is_primary=1; }
    [[ "$val" == "$platform_default" ]] && { annotations+=("platform default"); is_primary=1; }

    if [[ ${#annotations[@]} -gt 0 ]]; then
      local joined="${annotations[0]}"
      local i
      for ((i=1; i<${#annotations[@]}; i++)); do
        joined="$joined & ${annotations[$i]}"
      done
      ann_str=" ${DIM}($joined)${NC}"
    fi

    options+=("$val")
    if [[ $is_primary -eq 1 ]]; then
      echo -e "   ${BOLD}• ${val}${NC}${ann_str}" >&2
    else
      echo -e "   ${DIM}• ${val}${NC}" >&2
    fi
  }

  add_option "$current_value"
  add_option "$platform_default"
  add_option "$DEFAULT_MODEL_FAST"
  add_option "$DEFAULT_MODEL_POWERFUL"
  add_option "$DEFAULT_MODEL_LIGHT"

  if ! rich_prompt response "   > " "$current_value" "${options[@]}"; then
    die "Cannot read input — are you running in a non-interactive shell?"
  fi

  printf -v "$result_var" '%s' "$response"
}

prompt_platform_selection() {
  local platform_answer=""

  echo -e "${BOLD}Which platform do you want to install?${NC}"
  echo -e "   ${DIM}Press Enter to install Claude Code. Use Up/Down arrows to select.${NC}"
  echo ""
  echo -e "   ${BOLD}1)${NC} Claude Code"
  echo -e "   ${BOLD}2)${NC} OpenCode"
  echo -e "   ${BOLD}3)${NC} Gemini CLI"
  echo -e "   ${BOLD}4)${NC} Codex CLI"

  if ! rich_prompt platform_answer "   > " "Claude Code" "Claude Code" "OpenCode" "Gemini CLI" "Codex CLI"; then
    die "Cannot read input — are you running in a non-interactive shell?"
  fi

  case "$platform_answer" in
    ""|1|claude|Claude|"Claude Code") PLATFORM="claude" ;;
    2|opencode|OpenCode|openCode) PLATFORM="opencode" ;;
    3|gemini|Gemini|"Gemini CLI") PLATFORM="gemini" ;;
    4|codex|Codex|"Codex CLI") PLATFORM="codex" ;;
    *) die "Unknown platform selection: $platform_answer" ;;
  esac
}

configure_platform_context() {
  if [[ "$PLATFORM" == "claude" ]]; then
    USE_PLATFORM_BUILD_FLOW=$PLATFORM_EXPLICIT
  else
    USE_PLATFORM_BUILD_FLOW=1
  fi

  if [[ $USE_PLATFORM_BUILD_FLOW -eq 1 ]]; then
    [[ -f "$REPO_DIR/scripts/build.sh" ]] || die "Can't find scripts/build.sh in $REPO_DIR"
    load_platform_env "$PLATFORM"
    DEFAULT_MODEL_FAST="$MODEL_FAST"
    DEFAULT_MODEL_POWERFUL="$MODEL_POWERFUL"
    DEFAULT_MODEL_LIGHT="$MODEL_LIGHT"
  else
    PLATFORM_DIR=".claude"
    PLATFORM_NAME="Claude Code"
    DISPATCHER_FILE="CLAUDE.md"
  fi
}

load_platform_env() {
  local platform="$1"
  local env_file="$PLATFORMS_DIR/${platform}.env"

  [[ -f "$env_file" ]] || die "Platform env file not found: $env_file"

  # shellcheck source=/dev/null
  source "$env_file"
}

prepend_deprecation_header() {
  local file_path="$1"
  local tmp_file=""

  tmp_file="$(mktemp)"
  {
    echo "########"
    echo "DEPRECATED DO NOT USE"
    echo "########"
    echo ""
    cat "$file_path"
  } > "$tmp_file"
  mv "$tmp_file" "$file_path"
}

is_safe_manifest_entry() {
  local entry="$1"

  [[ -n "$entry" ]] || return 1
  [[ "$entry" != *'/'* ]] || return 1
  [[ "$entry" != *\\* ]] || return 1
  [[ "$entry" != *'..'* ]] || return 1

  return 0
}

apply_writability() {
  local mode="$1"
  local target="$2"

  [[ -e "$target" ]] || return 0

  case "$mode" in
    unlock) chmod u+w "$target" ;;
    harden) chmod a-w "$target" ;;
    *) die "Unknown writability mode: $mode" ;;
  esac
}

apply_codex_protected_permissions() {
  local install_root="$1"
  local dispatcher_target="$2"
  local mode="$3"
  local manifest_file=""
  local entry=""
  local skill_dir=""

  [[ "$PLATFORM" == "codex" ]] || return 0

  apply_writability "$mode" "$dispatcher_target"

  manifest_file="$install_root/agents/.core-manifest"
  if [[ -f "$manifest_file" ]]; then
    while IFS= read -r entry || [[ -n "$entry" ]]; do
      is_safe_manifest_entry "$entry" || continue
      apply_writability "$mode" "$install_root/agents/$entry"
    done < "$manifest_file"
  fi

  manifest_file="$install_root/references/.core-manifest"
  if [[ -f "$manifest_file" ]]; then
    while IFS= read -r entry || [[ -n "$entry" ]]; do
      is_safe_manifest_entry "$entry" || continue
      case "$entry" in
        agents.md|agents-registry.md) continue ;;
      esac
      apply_writability "$mode" "$install_root/references/$entry"
    done < "$manifest_file"
  fi

  apply_writability "$mode" "$install_root/skills"
  manifest_file="$install_root/skills/.core-manifest"
  if [[ -f "$manifest_file" ]]; then
    while IFS= read -r entry || [[ -n "$entry" ]]; do
      is_safe_manifest_entry "$entry" || continue
      skill_dir="$install_root/skills/$entry"
      apply_writability "$mode" "$skill_dir"
      apply_writability "$mode" "$skill_dir/SKILL.md"
    done < "$manifest_file"
  fi
}

deprecate_stale_agents() {
  local existing_install="$1"
  local source_agents_dir="$2"
  local install_root="$3"
  local old_manifest="$install_root/agents/.core-manifest"

  echo ""
  mkdir -p "$install_root/agents"

  if [[ $existing_install -eq 1 && -f "$old_manifest" ]]; then
    while IFS= read -r old_name; do
      if ! is_safe_manifest_entry "$old_name"; then
        [[ -n "$old_name" ]] && warn "Skipping invalid managed agent manifest entry: $old_name"
        continue
      fi
      [[ -f "$source_agents_dir/$old_name" ]] && continue

      local vault_file="$install_root/agents/$old_name"
      [[ -f "$vault_file" ]] || continue

      local old_stem="${old_name%.*}"
      local old_ext="${old_name##*.}"
      local deprecated_name="${old_stem}-DEPRECATED.${old_ext}"

      mkdir -p "$install_root/deprecated"
      [[ -f "$install_root/deprecated/$deprecated_name" ]] && continue

      mv "$vault_file" "$install_root/deprecated/$deprecated_name"
      prepend_deprecation_header "$install_root/deprecated/$deprecated_name"
      warn "Deprecated stale agent: $old_name -> deprecated/$deprecated_name"
    done < "$old_manifest"
  fi
}

deprecate_stale_skills() {
  local existing_install="$1"
  local source_skills_dir="$2"
  local install_root="$3"
  local old_manifest="$install_root/skills/.core-manifest"

  [[ -d "$source_skills_dir" ]] || return 0

  mkdir -p "$install_root/skills"

  if [[ $existing_install -eq 1 && -f "$old_manifest" ]]; then
    while IFS= read -r old_name; do
      local source_skill_dir="$source_skills_dir/$old_name"
      local vault_skill_dir="$install_root/skills/$old_name"
      local deprecated_name="${old_name}-DEPRECATED"

      if ! is_safe_manifest_entry "$old_name"; then
        [[ -n "$old_name" ]] && warn "Skipping invalid managed skill manifest entry: $old_name"
        continue
      fi
      [[ -d "$source_skill_dir" && -f "$source_skill_dir/SKILL.md" ]] && continue
      [[ -d "$vault_skill_dir" ]] || continue

      mkdir -p "$install_root/deprecated/skills"
      [[ -e "$install_root/deprecated/skills/$deprecated_name" ]] && continue

      mv "$vault_skill_dir" "$install_root/deprecated/skills/$deprecated_name"
      if [[ -f "$install_root/deprecated/skills/$deprecated_name/SKILL.md" ]]; then
        prepend_deprecation_header "$install_root/deprecated/skills/$deprecated_name/SKILL.md"
      fi
      warn "Deprecated stale skill: $old_name -> deprecated/skills/$deprecated_name"
    done < "$old_manifest"
  fi
}

copy_agents() {
  local source_agents_dir="$1"
  local install_root="$2"

  info "Creating ${PLATFORM_DIR}/agents/ in vault..."

  AGENT_COUNT=0
  : > "$install_root/agents/.core-manifest"
  for agent in "$source_agents_dir"/*; do
    [[ -f "$agent" ]] || continue
    cp "$agent" "$install_root/agents/"
    basename "$agent" >> "$install_root/agents/.core-manifest"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  done
  success "Copied $AGENT_COUNT agents"
}

copy_references() {
  local source_references_dir="$1"
  local install_root="$2"
  local existing_install="$3"

  info "Creating ${PLATFORM_DIR}/references/ in vault..."
  mkdir -p "$install_root/references"

  USER_MUTABLE_REFS="agents-registry.md agents.md"

  : > "$install_root/references/.core-manifest"
  for ref in "$source_references_dir"/*.md; do
    [[ -f "$ref" ]] || continue

    local ref_name
    ref_name="$(basename "$ref")"

    if [[ $existing_install -eq 1 && -f "$install_root/references/$ref_name" ]]; then
      if [[ " $USER_MUTABLE_REFS " == *" $ref_name "* ]]; then
        warn "Preserving existing $ref_name (run updateme.sh to merge upstream changes)"
        echo "$ref_name" >> "$install_root/references/.core-manifest"
        continue
      fi
    fi

    cp "$ref" "$install_root/references/"
    echo "$ref_name" >> "$install_root/references/.core-manifest"
  done
  success "Copied references"
}

copy_skills() {
  local source_skills_dir="$1"
  local install_root="$2"

  SKILL_COUNT=0
  if [[ -d "$source_skills_dir" ]]; then
    mkdir -p "$install_root/skills"
    : > "$install_root/skills/.core-manifest"

    for skill_dir in "$source_skills_dir"/*/; do
      [[ -f "$skill_dir/SKILL.md" ]] || continue

      local skill_name
      skill_name="$(basename "$skill_dir")"

      mkdir -p "$install_root/skills/$skill_name"
      cp "$skill_dir/SKILL.md" "$install_root/skills/$skill_name/"
      echo "$skill_name" >> "$install_root/skills/.core-manifest"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    done
    success "Copied $SKILL_COUNT skills"
  fi
}

copy_dispatcher() {
  local source_root="$1"

  if [[ -f "$source_root/$DISPATCHER_FILE" ]]; then
    cp "$source_root/$DISPATCHER_FILE" "$VAULT_DIR/$DISPATCHER_FILE"
    success "Copied $DISPATCHER_FILE"
  fi
}

copy_legacy_claude_configs() {
  HOOK_COUNT=0

  if [[ -d "$REPO_DIR/hooks" ]]; then
    mkdir -p "$VAULT_DIR/.claude/hooks"
    for hook in "$REPO_DIR/hooks"/*.sh; do
      [[ -f "$hook" ]] || continue
      cp "$hook" "$VAULT_DIR/.claude/hooks/"
      chmod +x "$VAULT_DIR/.claude/hooks/$(basename "$hook")"
      HOOK_COUNT=$((HOOK_COUNT + 1))
    done
    success "Copied $HOOK_COUNT hooks"
  fi

  if [[ -f "$REPO_DIR/settings.json" ]]; then
    if [[ -f "$VAULT_DIR/.claude/settings.json" ]]; then
      warn ".claude/settings.json already exists — skipping (won't overwrite)"
    else
      mkdir -p "$VAULT_DIR/.claude"
      cp "$REPO_DIR/settings.json" "$VAULT_DIR/.claude/settings.json"
      success "Copied settings.json (hooks configuration)"
    fi
  fi
}

maybe_copy_mcp() {
  local source_root="$1"

  MCP_INSTALLED=0
  [[ -f "$source_root/.mcp.json" ]] || return 0

  echo ""
  echo -e "${BOLD}Do you use Gmail, Hey.com, or Google Calendar?${NC}"
  echo -e "   ${DIM}The Postman agent can read your inbox and calendar.${NC}"
  echo -e "   ${DIM}Gmail uses MCP connectors (read-only). For full access, set up GWS CLI later.${NC}"
  echo -e "   ${DIM}Hey.com uses the Hey CLI (install from https://github.com/basecamp/hey-cli).${NC}"
  echo -e "   ${DIM}You can always add this later.${NC}"
  echo ""
  echo -e "   ${DIM}Use Up/Down arrows to select.${NC}"
  echo ""
  echo -e "   ${BOLD}•${NC} Yes, set up Gmail + Calendar (MCP connectors)"
  echo -e "   ${BOLD}•${NC} No, skip for now"

  local mcp_answer="No, skip for now"
  if [[ $YES_MODE -eq 0 ]]; then
    if ! rich_prompt mcp_answer "   > " "No, skip for now" "Yes, set up Gmail + Calendar (MCP connectors)" "No, skip for now"; then
      die "Cannot read input — are you running in a non-interactive shell?"
    fi
  fi

  if [[ "$mcp_answer" == "Yes, set up Gmail + Calendar (MCP connectors)" ]]; then
    cp "$source_root/.mcp.json" "$VAULT_DIR/.mcp.json"
    success "Created .mcp.json (Gmail + Google Calendar)"
    MCP_INSTALLED=1
  else
    info "Skipped MCP setup"
  fi
}

copy_hook_scripts() {
  local source_hooks_dir="$1"
  local install_root="$2"

  HOOK_COUNT=0
  [[ -d "$source_hooks_dir" ]] || return 0

  mkdir -p "$install_root/hooks"
  for hook in "$source_hooks_dir"/*.sh; do
    [[ -f "$hook" ]] || continue
    cp "$hook" "$install_root/hooks/"
    chmod +x "$install_root/hooks/$(basename "$hook")"
    HOOK_COUNT=$((HOOK_COUNT + 1))
  done

  success "Copied $HOOK_COUNT hooks"
}

merge_opencode_config() {
  local source_config="$1"
  local target_config="$2"
  local managed_plugin_spec="./.crew/crew-hooks.js"
  local merged_config_file=""

  [[ -f "$source_config" ]] || die "OpenCode build output is missing opencode.json: $source_config"

  merged_config_file="$(mktemp "/tmp/crew-opencode-merge.XXXXXX")"

  if ! opencode_merge_config "$source_config" "$target_config" "$managed_plugin_spec" "$merged_config_file"; then
    rm -f "$merged_config_file"
    die "${OPENCODE_JSON_ERROR:-Failed to merge OpenCode config}"
  fi

  mkdir -p "$(dirname "$target_config")"
  cp "$merged_config_file" "$target_config"
  rm -f "$merged_config_file"
  success "Installed managed plugin entry in opencode.json"
}

verify_opencode_install() {
  local install_root="$1"
  local config_file="$install_root/opencode.json"
  local plugin_file="$install_root/.crew/crew-hooks.js"
  local managed_plugin_spec="./.crew/crew-hooks.js"
  local runtime_home=""
  local runtime_xdg=""
  local runtime_config_dir=""
  local runtime_config_file=""
  local runtime_plugin_file=""
  local runtime_workspace=""
  local runtime_output=""
  local runtime_output_file=""

  [[ -f "$config_file" ]] || die "Managed OpenCode config is missing: $config_file"
  [[ -f "$plugin_file" ]] || die "Managed OpenCode plugin artifact is missing: $plugin_file"

  if ! opencode_validate_static_install "$config_file" "$managed_plugin_spec"; then
    die "$OPENCODE_JSON_ERROR"
  fi

  success "Validated opencode.json managed plugin wiring"

  if ! command -v opencode >/dev/null 2>&1; then
    die "OpenCode runtime proof requires the opencode CLI, but it is not installed or not on PATH"
  fi

  runtime_home="$(mktemp -d "/tmp/crew-opencode-home.XXXXXX")"
  runtime_xdg="$(mktemp -d "/tmp/crew-opencode-xdg.XXXXXX")"
  runtime_config_dir="$(mktemp -d "/tmp/crew-opencode-config.XXXXXX")"
  runtime_workspace="$(mktemp -d "/tmp/crew-opencode-workspace.XXXXXX")"
  runtime_output_file="$(mktemp "/tmp/crew-opencode-output.XXXXXX")"
  runtime_config_file="$runtime_config_dir/opencode.json"
  runtime_plugin_file="$runtime_config_dir/.crew/crew-hooks.js"

  mkdir -p "$runtime_config_dir/.crew"
  cp "$config_file" "$runtime_config_file"
  cp "$plugin_file" "$runtime_plugin_file"

  if ! runtime_output=$(cd "$runtime_workspace" && env -u OPENCODE_CONFIG_CONTENT HOME="$runtime_home" XDG_CONFIG_HOME="$runtime_xdg" OPENCODE_CONFIG="$runtime_config_file" opencode debug config 2>&1); then
    rm -rf "$runtime_home" "$runtime_xdg" "$runtime_config_dir" "$runtime_workspace"
    rm -f "$runtime_output_file"
    die "OpenCode failed to load the installed config in an isolated environment:\n$runtime_output"
  fi

  printf '%s\n' "$runtime_output" > "$runtime_output_file"

  if ! opencode_validate_runtime_output "$runtime_config_file" "$runtime_plugin_file" "$runtime_output_file"; then
    rm -rf "$runtime_home" "$runtime_xdg" "$runtime_config_dir" "$runtime_workspace"
    rm -f "$runtime_output_file"
    die "$OPENCODE_JSON_ERROR"
  fi

  rm -rf "$runtime_home" "$runtime_xdg" "$runtime_config_dir" "$runtime_workspace"
  rm -f "$runtime_output_file"
  success "Proved OpenCode config loads the managed plugin in isolation"
}

copy_platform_configs() {
  local source_root="$1"
  local install_root="$2"

  HOOK_COUNT=0

  case "$PLATFORM" in
    claude)
      copy_hook_scripts "$source_root/hooks" "$install_root"

      if [[ -f "$source_root/settings.json" ]]; then
        cp "$source_root/settings.json" "$install_root/settings.json"
        success "Copied settings.json (hooks configuration)"
      fi

      maybe_copy_mcp "$source_root"
      ;;
    opencode)
      if [[ -f "$source_root/.crew/crew-hooks.js" ]]; then
        mkdir -p "$install_root/.crew"
        cp "$source_root/.crew/crew-hooks.js" "$install_root/.crew/crew-hooks.js"
        success "Copied managed OpenCode plugin artifact"
      else
        die "OpenCode build output is missing .crew/crew-hooks.js"
      fi

      copy_hook_scripts "$source_root/hooks" "$install_root"

      merge_opencode_config "$source_root/opencode.json" "$install_root/opencode.json"
      verify_opencode_install "$install_root"
      ;;
    gemini)
      copy_hook_scripts "$source_root/hooks" "$install_root"

      if [[ -f "$source_root/settings.json" ]]; then
        cp "$source_root/settings.json" "$install_root/settings.json"
        success "Copied settings.json (model + hooks configuration)"
      fi
      ;;
    codex)
      copy_hook_scripts "$source_root/hooks" "$install_root"

      if [[ -f "$source_root/config.toml" ]]; then
        cp "$source_root/config.toml" "$install_root/config.toml"
        success "Copied config.toml (model config + hook feature enablement)"
      fi

      if [[ -f "$source_root/hooks.json" ]]; then
        cp "$source_root/hooks.json" "$install_root/hooks.json"
        success "Copied hooks.json (Codex hook configuration)"
      fi
      ;;
  esac
}

show_install_summary() {
  echo ""
  echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
  echo ""
  echo -e "   Your vault is ready. Here's what was installed:"
  echo ""
  echo -e "   ${VAULT_DIR}/"
  echo -e "   ├── ${PLATFORM_DIR}/"
  echo -e "   │   ├── agents/          ${DIM}← ${AGENT_COUNT} crew agents${NC}"
  echo -e "   │   ├── skills/          ${DIM}← ${SKILL_COUNT:-0} crew skills${NC}"

  if [[ "$PLATFORM" == "claude" ]]; then
    echo -e "   │   ├── hooks/           ${DIM}← ${HOOK_COUNT:-0} hooks${NC}"
    echo -e "   │   ├── settings.json    ${DIM}← hooks configuration${NC}"
  elif [[ "$PLATFORM" == "opencode" ]]; then
    echo -e "   │   ├── opencode.json    ${DIM}← config + managed plugin entry${NC}"
    echo -e "   │   ├── .crew/          ${DIM}← managed OpenCode plugin${NC}"
  elif [[ "$PLATFORM" == "gemini" ]]; then
    echo -e "   │   ├── hooks/           ${DIM}← ${HOOK_COUNT:-0} hooks${NC}"
    echo -e "   │   ├── settings.json    ${DIM}← model + hooks configuration${NC}"
  elif [[ "$PLATFORM" == "codex" ]]; then
    echo -e "   │   ├── hooks/           ${DIM}← ${HOOK_COUNT:-0} hooks${NC}"
    echo -e "   │   ├── config.toml      ${DIM}← model config + hook enablement${NC}"
    echo -e "   │   ├── hooks.json       ${DIM}← hook configuration (Bash-only)${NC}"
  fi

  echo -e "   │   └── references/      ${DIM}← shared docs${NC}"
  echo -e "   ├── Meta/"
  echo -e "   │   └── scripts/         ${DIM}← ${ORCH_COUNT:-0} orchestra scripts${NC}"
  echo -e "   ├── ${DISPATCHER_FILE}            ${DIM}← project instructions${NC}"

  if [[ $MCP_INSTALLED -eq 1 ]]; then
    echo -e "   └── .mcp.json            ${DIM}← Gmail + Calendar${NC}"
  fi

  echo ""
  echo -e "   ${BOLD}Next steps:${NC}"
  echo -e "   1. Open ${PLATFORM_NAME} in your vault folder"
  echo -e "   2. Say: ${BOLD}\"Initialize my vault\"${NC}"
  echo -e "   3. The Architect will guide you through setup"
  echo ""
  echo -e "   ${DIM}To update after a git pull: bash scripts/updateme.sh${NC}"
  echo ""
}

# ── Find paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLATFORMS_DIR="$REPO_DIR/platforms"
DEFAULT_VAULT_DIR="$(cd "$REPO_DIR/.." && pwd)"
VAULT_DIR="$DEFAULT_VAULT_DIR"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/opencode-config.sh"

# ── Arguments ───────────────────────────────────────────────────────────────
PLATFORM=""
PLATFORM_EXPLICIT=0
USE_PLATFORM_BUILD_FLOW=0
YES_MODE=0
VAULT_OVERRIDE=""
MODEL_FAST_OVERRIDE=""
MODEL_POWERFUL_OVERRIDE=""
MODEL_LIGHT_OVERRIDE=""
OVERRIDES_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      [[ $# -ge 2 ]] || die "--platform requires a value"
      PLATFORM="$2"
      PLATFORM_EXPLICIT=1
      shift 2
      ;;
    --vault)
      [[ $# -ge 2 ]] || die "--vault requires a path"
      VAULT_OVERRIDE="$2"
      shift 2
      ;;
    --yes)
      YES_MODE=1
      shift
      ;;
    --model-fast)
      [[ $# -ge 2 ]] || die "--model-fast requires a value"
      MODEL_FAST_OVERRIDE="$2"
      shift 2
      ;;
    --model-powerful)
      [[ $# -ge 2 ]] || die "--model-powerful requires a value"
      MODEL_POWERFUL_OVERRIDE="$2"
      shift 2
      ;;
    --model-light)
      [[ $# -ge 2 ]] || die "--model-light requires a value"
      MODEL_LIGHT_OVERRIDE="$2"
      shift 2
      ;;
    --overrides)
      [[ $# -ge 2 ]] || die "--overrides requires a file path"
      OVERRIDES_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Unknown argument: $1"
      ;;
  esac
done

if [[ -n "$PLATFORM" ]]; then
  case "$PLATFORM" in
    claude|opencode|gemini|codex) ;;
    *) die "Unknown platform: $PLATFORM. Use claude, opencode, gemini, or codex." ;;
  esac
fi

if [[ $PLATFORM_EXPLICIT -eq 0 && ( -n "$MODEL_FAST_OVERRIDE" || -n "$MODEL_POWERFUL_OVERRIDE" || -n "$MODEL_LIGHT_OVERRIDE" || -n "$OVERRIDES_FILE" ) ]]; then
  die "Model overrides require --platform <claude|opencode|gemini|codex>."
fi

if [[ -n "$VAULT_OVERRIDE" ]]; then
  VAULT_DIR="${VAULT_OVERRIDE/#\~/$HOME}"
  [[ -d "$VAULT_DIR" ]] || die "Directory not found: $VAULT_DIR"
fi

if [[ -n "$OVERRIDES_FILE" ]]; then
  OVERRIDES_FILE="${OVERRIDES_FILE/#\~/$HOME}"
fi

# Sanity checks
[[ -d "$REPO_DIR/agents" ]] || die "Can't find agents/ in $REPO_DIR — are you running this from the repo?"
[[ -d "$REPO_DIR/references" ]] || die "Can't find references/ in $REPO_DIR"

if [[ -n "$PLATFORM" ]]; then
  configure_platform_context
fi

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  My Brain Is Full - Crew :: Setup        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "   Repo:     ${BOLD}${REPO_DIR}${NC}"
echo -e "   Vault:    ${BOLD}${VAULT_DIR}${NC}"
if [[ -n "$PLATFORM" ]]; then
  echo -e "   Platform: ${BOLD}${PLATFORM_NAME}${NC}"
fi
echo ""

if [[ $PLATFORM_EXPLICIT -eq 0 ]]; then
  if [[ $YES_MODE -eq 1 ]]; then
    PLATFORM="claude"
  else
    prompt_platform_selection
    echo ""
  fi

  configure_platform_context
fi

# ── Confirm vault location ─────────────────────────────────────────────────
if [[ -z "$VAULT_OVERRIDE" && $YES_MODE -eq 0 ]]; then
  echo -e "${BOLD}Is this your Obsidian vault folder?${NC}"
  echo -e "   ${DIM}${VAULT_DIR}${NC}"
  echo ""
  echo -e "   ${BOLD}•${NC} Yes, install here"
  echo -e "   ${BOLD}•${NC} No, let me type the correct path"

  if ! rich_prompt CONFIRM "   > " "Yes, install here" "Yes, install here" "No, let me type the correct path"; then
    die "Cannot read input — are you running in a non-interactive shell?"
  fi

  if [[ "$CONFIRM" =~ ^([Nn]|No, let me type the correct path)$ ]]; then
    echo ""
    echo -e "${BOLD}Enter the full path to your Obsidian vault:${NC}"
    if ! rich_prompt VAULT_DIR "   > " ""; then
      die "Cannot read input — are you running in a non-interactive shell?"
    fi
    VAULT_DIR="${VAULT_DIR/#\~/$HOME}"
    [[ -d "$VAULT_DIR" ]] || die "Directory not found: $VAULT_DIR"
  fi
fi

INSTALL_ROOT="$VAULT_DIR/$PLATFORM_DIR"
DISPATCHER_TARGET="$VAULT_DIR/$DISPATCHER_FILE"
PERSISTED_MODELS_FILE="$INSTALL_ROOT/.installer-models.env"
MCP_INSTALLED=0
HOOK_COUNT=0
AGENT_COUNT=0
SKILL_COUNT=0

SELECTED_MODEL_FAST=""
SELECTED_MODEL_POWERFUL=""
SELECTED_MODEL_LIGHT=""
TEMP_OVERRIDES_FILE=""

cleanup() {
  [[ -n "$TEMP_OVERRIDES_FILE" && -f "$TEMP_OVERRIDES_FILE" ]] && rm -f "$TEMP_OVERRIDES_FILE"
  stty echo 2>/dev/null || true
  return 0
}

trap cleanup EXIT

if [[ $USE_PLATFORM_BUILD_FLOW -eq 1 ]]; then
  SELECTED_MODEL_FAST="$DEFAULT_MODEL_FAST"
  SELECTED_MODEL_POWERFUL="$DEFAULT_MODEL_POWERFUL"
  SELECTED_MODEL_LIGHT="$DEFAULT_MODEL_LIGHT"

  if [[ -f "$PERSISTED_MODELS_FILE" ]]; then
    MODEL_FAST="$SELECTED_MODEL_FAST"
    MODEL_POWERFUL="$SELECTED_MODEL_POWERFUL"
    MODEL_LIGHT="$SELECTED_MODEL_LIGHT"
    load_model_values_from_file "$PERSISTED_MODELS_FILE"
    SELECTED_MODEL_FAST="$MODEL_FAST"
    SELECTED_MODEL_POWERFUL="$MODEL_POWERFUL"
    SELECTED_MODEL_LIGHT="$MODEL_LIGHT"
    info "Loaded saved model preferences from ${PLATFORM_DIR}/.installer-models.env"
  fi

  if [[ -n "$OVERRIDES_FILE" ]]; then
    MODEL_FAST="$SELECTED_MODEL_FAST"
    MODEL_POWERFUL="$SELECTED_MODEL_POWERFUL"
    MODEL_LIGHT="$SELECTED_MODEL_LIGHT"
    load_model_values_from_file "$OVERRIDES_FILE"
    SELECTED_MODEL_FAST="$MODEL_FAST"
    SELECTED_MODEL_POWERFUL="$MODEL_POWERFUL"
    SELECTED_MODEL_LIGHT="$MODEL_LIGHT"
    info "Loaded model overrides from $(basename "$OVERRIDES_FILE")"
  fi

  [[ -n "$MODEL_FAST_OVERRIDE" ]] && SELECTED_MODEL_FAST="$MODEL_FAST_OVERRIDE"
  [[ -n "$MODEL_POWERFUL_OVERRIDE" ]] && SELECTED_MODEL_POWERFUL="$MODEL_POWERFUL_OVERRIDE"
  [[ -n "$MODEL_LIGHT_OVERRIDE" ]] && SELECTED_MODEL_LIGHT="$MODEL_LIGHT_OVERRIDE"

  if [[ $YES_MODE -eq 0 ]]; then
    echo ""
    echo -e "${BOLD}Choose your preferred models for ${PLATFORM_NAME}:${NC}"
    echo -e "   ${DIM}Press Enter to accept the default value.${NC}"
    echo ""

    prompt_with_default SELECTED_MODEL_FAST "MODEL_FAST" "$SELECTED_MODEL_FAST" "$DEFAULT_MODEL_FAST"
    echo ""
    prompt_with_default SELECTED_MODEL_POWERFUL "MODEL_POWERFUL" "$SELECTED_MODEL_POWERFUL" "$DEFAULT_MODEL_POWERFUL"
    echo ""
    prompt_with_default SELECTED_MODEL_LIGHT "MODEL_LIGHT" "$SELECTED_MODEL_LIGHT" "$DEFAULT_MODEL_LIGHT"
  fi

  TEMP_OVERRIDES_FILE="$(mktemp)"
  write_model_overrides_file "$TEMP_OVERRIDES_FILE" "$PLATFORM_NAME" "$SELECTED_MODEL_FAST" "$SELECTED_MODEL_POWERFUL" "$SELECTED_MODEL_LIGHT"

  BUILD_ROOT="$REPO_DIR/build/$PLATFORM"
  BUILD_STATE_FILE="$BUILD_ROOT/.installer-models.env"
  BUILD_REQUIRED=0

  if [[ ! -d "$BUILD_ROOT" || ! -d "$BUILD_ROOT/agents" || ! -d "$BUILD_ROOT/references" || ! -f "$BUILD_ROOT/$DISPATCHER_FILE" ]]; then
    BUILD_REQUIRED=1
  elif [[ ! -f "$BUILD_STATE_FILE" ]]; then
    BUILD_REQUIRED=1
  else
    MODEL_FAST=""
    MODEL_POWERFUL=""
    MODEL_LIGHT=""
    load_model_values_from_file "$BUILD_STATE_FILE"

    if [[ "$MODEL_FAST" != "$SELECTED_MODEL_FAST" || "$MODEL_POWERFUL" != "$SELECTED_MODEL_POWERFUL" || "$MODEL_LIGHT" != "$SELECTED_MODEL_LIGHT" ]]; then
      BUILD_REQUIRED=1
    fi
  fi

  if [[ $BUILD_REQUIRED -eq 1 ]]; then
    echo ""
    info "Building ${PLATFORM_NAME} output..."
    "$REPO_DIR/scripts/build.sh" "$PLATFORM" --overrides "$TEMP_OVERRIDES_FILE"
    write_model_overrides_file "$BUILD_STATE_FILE" "$PLATFORM_NAME" "$SELECTED_MODEL_FAST" "$SELECTED_MODEL_POWERFUL" "$SELECTED_MODEL_LIGHT"
  else
    info "Using existing build/${PLATFORM}/ output"
  fi

  SOURCE_ROOT="$BUILD_ROOT"
  SOURCE_AGENTS_DIR="$SOURCE_ROOT/agents"
  SOURCE_REFERENCES_DIR="$SOURCE_ROOT/references"
  SOURCE_SKILLS_DIR="$SOURCE_ROOT/skills"
else
  SOURCE_ROOT="$REPO_DIR"
  SOURCE_AGENTS_DIR="$REPO_DIR/agents"
  SOURCE_REFERENCES_DIR="$REPO_DIR/references"
  SOURCE_SKILLS_DIR="$REPO_DIR/skills"
fi

# ── Check for existing installation ───────────────────────────────────────
echo ""
EXISTING=0
if [[ -d "$INSTALL_ROOT" ]]; then EXISTING=1; fi
if [[ -f "$DISPATCHER_TARGET" ]]; then EXISTING=1; fi

if [[ $EXISTING -eq 1 ]]; then
  warn "An existing installation was detected:"
  [[ -d "$INSTALL_ROOT" ]] && warn "  ${PLATFORM_DIR}/ directory exists"
  [[ -f "$DISPATCHER_TARGET" ]] && warn "  ${DISPATCHER_FILE} exists"
  echo ""
  echo -e "   ${BOLD}The installer needs to overwrite these files.${NC}"
  echo -e "   ${DIM}Custom agents in ${PLATFORM_DIR}/agents/ will NOT be deleted.${NC}"
  echo -e "   ${DIM}Your vault notes are never touched.${NC}"
  echo ""

  if [[ $YES_MODE -eq 0 ]]; then
    echo -e "   ${DIM}Use Up/Down arrows to select.${NC}"
    echo ""
    echo -e "   ${BOLD}•${NC} Continue (overwrite core files, keep custom agents)"
    echo -e "   ${BOLD}•${NC} Quit"

    if ! rich_prompt OVERWRITE_ANSWER "   > " "Quit" "Continue (overwrite core files, keep custom agents)" "Quit"; then
      die "Cannot read input — are you running in a non-interactive shell?"
    fi

    if [[ "$OVERWRITE_ANSWER" != "Continue (overwrite core files, keep custom agents)" ]]; then
      echo ""
      info "Installation cancelled."
      echo ""
      exit 0
    fi
  else
    info "Non-interactive mode: continuing with overwrite of managed files"
  fi
fi

# ── Deprecate stale core agents on reinstall ─────────────────────────────
deprecate_stale_agents "$EXISTING" "$SOURCE_AGENTS_DIR" "$INSTALL_ROOT"

# ── Copy agents ─────────────────────────────────────────────────────────────
copy_agents "$SOURCE_AGENTS_DIR" "$INSTALL_ROOT"

# ── Create Meta/states/ for agent post-its ──────────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"
info "Created Meta/states/ (agent post-it directory)"

# ── Copy references ─────────────────────────────────────────────────────────
copy_references "$SOURCE_REFERENCES_DIR" "$INSTALL_ROOT" "$EXISTING"

# ── Copy skills ──────────────────────────────────────────────────────────────
deprecate_stale_skills "$EXISTING" "$SOURCE_SKILLS_DIR" "$INSTALL_ROOT"
copy_skills "$SOURCE_SKILLS_DIR" "$INSTALL_ROOT"

# ── Copy dispatcher ──────────────────────────────────────────────────────────
copy_dispatcher "$SOURCE_ROOT"

# ── Deprecate stale orchestra scripts on reinstall ──────────────────────────
OLD_ORCH_MANIFEST="$VAULT_DIR/Meta/scripts/.core-manifest"
if [[ $EXISTING -eq 1 && -f "$OLD_ORCH_MANIFEST" ]]; then
  while IFS= read -r old_script; do
    [[ -z "$old_script" ]] && continue
    [[ -f "$REPO_DIR/orchestra/$old_script" ]] && continue
    vault_script="$VAULT_DIR/Meta/scripts/$old_script"
    [[ -f "$vault_script" ]] || continue
    rm "$vault_script"
    warn "Removed stale script: $old_script"
  done < "$OLD_ORCH_MANIFEST"
fi

# ── Copy orchestra scripts ──────────────────────────────────────────────────
ORCH_COUNT=0
if [[ -d "$REPO_DIR/orchestra" ]]; then
  mkdir -p "$VAULT_DIR/Meta/scripts"
  : > "$VAULT_DIR/Meta/scripts/.core-manifest"
  for script in "$REPO_DIR/orchestra/"*; do
    [[ -f "$script" ]] || continue
    bname="$(basename "$script")"
    [[ "$bname" == "README.md" ]] && continue
    cp "$script" "$VAULT_DIR/Meta/scripts/"
    chmod +x "$VAULT_DIR/Meta/scripts/$bname"
    echo "$bname" >> "$VAULT_DIR/Meta/scripts/.core-manifest"
    ORCH_COUNT=$((ORCH_COUNT + 1))
  done
  success "Copied $ORCH_COUNT orchestra scripts to Meta/scripts/"
fi

# ── Copy platform configs ────────────────────────────────────────────────────
if [[ $USE_PLATFORM_BUILD_FLOW -eq 1 ]]; then
  copy_platform_configs "$SOURCE_ROOT" "$INSTALL_ROOT"
else
  copy_legacy_claude_configs
  maybe_copy_mcp "$REPO_DIR"
fi

# ── Persist selected models for platform installs ───────────────────────────
if [[ $USE_PLATFORM_BUILD_FLOW -eq 1 ]]; then
  mkdir -p "$INSTALL_ROOT"
  write_model_overrides_file "$PERSISTED_MODELS_FILE" "$PLATFORM_NAME" "$SELECTED_MODEL_FAST" "$SELECTED_MODEL_POWERFUL" "$SELECTED_MODEL_LIGHT"
  success "Saved preferred models in ${PLATFORM_DIR}/.installer-models.env"
fi

apply_codex_protected_permissions "$INSTALL_ROOT" "$DISPATCHER_TARGET" harden
if [[ "$PLATFORM" == "codex" ]]; then
  success "Hardened protected Codex core files (best-effort)"
fi

# ── Done ────────────────────────────────────────────────────────────────────
show_install_summary
