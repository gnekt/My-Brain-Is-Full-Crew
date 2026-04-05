#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Updater
# =============================================================================
# After pulling new changes from the repo, run this to update the agents
# in your vault:
#
#   cd /path/to/your-vault/My-Brain-Is-Full-Crew
#   git pull
#   bash scripts/updateme.sh
#
# =============================================================================

set -euo pipefail

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

# ── Find paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CURRENT_DIR="$(pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/opencode-config.sh"

if [[ "$CURRENT_DIR" == "$REPO_DIR" || "$CURRENT_DIR" == "$REPO_DIR/"* ]]; then
  VAULT_DIR="$(cd "$REPO_DIR/.." && pwd)"
else
  VAULT_DIR="$CURRENT_DIR"
fi

PLATFORMS_DIR="$REPO_DIR/platforms"

[[ -d "$REPO_DIR/agents" ]] || die "Can't find agents/ — are you running this from the repo?"
[[ -d "$REPO_DIR/references" ]] || die "Can't find references/ in $REPO_DIR"
[[ -d "$PLATFORMS_DIR" ]] || die "Can't find platforms/ in $REPO_DIR"
[[ -f "$REPO_DIR/scripts/build.sh" ]] || die "Can't find scripts/build.sh in $REPO_DIR"

SUPPORTED_PLATFORMS=(claude opencode gemini codex)
INSTALLED_PLATFORMS=()
INSTALLED_PLATFORM_NAMES=()

AGENT_COUNT=0
REF_COUNT=0
SKILL_COUNT=0
HOOK_COUNT=0
CONFIG_COUNT=0
DISPATCHER_COUNT=0
DEPRECATED_COUNT=0

load_platform_env() {
  local platform="$1"
  local env_file="$PLATFORMS_DIR/${platform}.env"

  [[ -f "$env_file" ]] || die "Platform env file not found: $env_file"

  PLATFORM_DIR=""
  PLATFORM_NAME=""
  DISPATCHER_FILE=""

  # shellcheck disable=SC1090
  source "$env_file"
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

platform_is_installed() {
  local platform="$1"
  local install_root=""
  local dispatcher_path=""

  load_platform_env "$platform"
  install_root="$VAULT_DIR/$PLATFORM_DIR"
  dispatcher_path="$VAULT_DIR/$DISPATCHER_FILE"

  [[ -f "$install_root/agents/.core-manifest" ]] && return 0
  [[ -f "$install_root/references/.core-manifest" ]] && return 0
  [[ -f "$install_root/skills/.core-manifest" ]] && return 0
  [[ -f "$install_root/.installer-models.env" ]] && return 0

  [[ -d "$install_root/agents" ]] || return 1
  [[ -d "$install_root/references" ]] || return 1
  [[ -f "$install_root/references/agents.md" ]] || return 1

  case "$platform" in
    claude)
      [[ -f "$dispatcher_path" ]] || return 1
      [[ -f "$install_root/settings.json" || -d "$install_root/hooks" || -f "$VAULT_DIR/.mcp.json" ]] || return 1
      return 0
      ;;
    opencode)
      [[ -f "$dispatcher_path" ]] || return 1
      [[ -f "$install_root/opencode.json" ]] || return 1
      return 0
      ;;
    gemini)
      [[ -f "$dispatcher_path" ]] || return 1
      [[ -f "$install_root/settings.json" ]] || return 1
      return 0
      ;;
    codex)
      [[ -f "$dispatcher_path" ]] || return 1
      [[ -f "$install_root/config.toml" ]] || return 1
      return 0
      ;;
  esac

  return 1
}

detect_installed_platforms() {
  local platform=""

  for platform in "${SUPPORTED_PLATFORMS[@]}"; do
    if platform_is_installed "$platform"; then
      INSTALLED_PLATFORMS+=("$platform")
      INSTALLED_PLATFORM_NAMES+=("$PLATFORM_NAME")
    fi
  done
}

join_by_comma() {
  local joined=""
  local item=""

  for item in "$@"; do
    if [[ -z "$joined" ]]; then
      joined="$item"
    else
      joined="$joined, $item"
    fi
  done

  printf '%s' "$joined"
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
  local platform="$1"
  local install_root="$2"
  local dispatcher_target="$3"
  local mode="$4"
  local manifest_file=""
  local entry=""
  local skill_dir=""

  [[ "$platform" == "codex" ]] || return 0

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

replace_file_if_changed() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" ]] && diff -q "$src" "$dst" >/dev/null 2>&1; then
    rm -f "$src"
    return 1
  fi

  mv "$src" "$dst"
  return 0
}

sync_file() {
  local src="$1"
  local dst="$2"
  local update_label="$3"
  local create_label="$4"
  local mode="${5:-}"
  local existed=0

  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" ]]; then
    existed=1
    if diff -q "$src" "$dst" >/dev/null 2>&1; then
      return 1
    fi
  fi

  cp "$src" "$dst"

  if [[ -n "$mode" ]]; then
    chmod "$mode" "$dst"
  fi

  if [[ $existed -eq 1 ]]; then
    info "$update_label"
  else
    info "$create_label"
  fi

  return 0
}

deprecate_removed_core_files() {
  local source_dir="$1"
  local managed_dir="$2"
  local manifest_file="$3"
  local deprecated_dir="$4"
  local label="$5"
  local old_name=""
  local vault_file=""
  local old_stem=""
  local old_ext=""
  local deprecated_name=""

  [[ -f "$manifest_file" ]] || return 0

  while IFS= read -r old_name || [[ -n "$old_name" ]]; do
    if ! is_safe_manifest_entry "$old_name"; then
      [[ -n "$old_name" ]] && warn "Skipping invalid managed $label manifest entry: $old_name"
      continue
    fi
    [[ "$old_name" == *"-DEPRECATED"* ]] && continue
    [[ -f "$source_dir/$old_name" ]] && continue

    vault_file="$managed_dir/$old_name"
    [[ -f "$vault_file" ]] || continue

    old_stem="${old_name%.*}"
    old_ext="${old_name##*.}"
    deprecated_name="${old_stem}-DEPRECATED.${old_ext}"

    mkdir -p "$deprecated_dir"
    [[ -f "$deprecated_dir/$deprecated_name" ]] && continue

    mv "$vault_file" "$deprecated_dir/$deprecated_name"
    prepend_deprecation_header "$deprecated_dir/$deprecated_name"
    warn "Deprecated $label: $old_name -> deprecated/$deprecated_name"
    DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
  done < "$manifest_file"
}

write_manifest_from_source() {
  local source_dir="$1"
  local manifest_file="$2"
  local tmp_manifest=""
  local source_file=""

  tmp_manifest="$(mktemp)"
  : > "$tmp_manifest"

  for source_file in "$source_dir"/*; do
    [[ -f "$source_file" ]] || continue
    basename "$source_file" >> "$tmp_manifest"
  done

  replace_file_if_changed "$tmp_manifest" "$manifest_file" || true
}

build_core_agent_names() {
  local source_agents_dir="$1"
  local core_names=" "
  local agent_file=""
  local agent_name=""

  for agent_file in "$source_agents_dir"/*; do
    [[ -f "$agent_file" ]] || continue
    agent_name="$(basename "$agent_file")"
    agent_name="${agent_name%.*}"
    core_names+="${agent_name} "
  done

  printf '%s' "$core_names"
}

sync_agents() {
  local source_agents_dir="$1"
  local install_root="$2"
  local agents_dir="$install_root/agents"
  local manifest_file="$agents_dir/.core-manifest"
  local deprecated_dir="$install_root/deprecated"
  local agent_file=""
  local name=""

  mkdir -p "$agents_dir"

  deprecate_removed_core_files "$source_agents_dir" "$agents_dir" "$manifest_file" "$deprecated_dir" "agent"

  for agent_file in "$source_agents_dir"/*; do
    [[ -f "$agent_file" ]] || continue
    name="$(basename "$agent_file")"
    if sync_file "$agent_file" "$agents_dir/$name" "Updated $PLATFORM_NAME agent: $name" "Added $PLATFORM_NAME agent: $name"; then
      AGENT_COUNT=$((AGENT_COUNT + 1))
    fi
  done

  write_manifest_from_source "$source_agents_dir" "$manifest_file"
}

sync_references() {
  local source_references_dir="$1"
  local source_agents_dir="$2"
  local install_root="$3"
  local references_dir="$install_root/references"
  local manifest_file="$references_dir/.core-manifest"
  local deprecated_dir="$install_root/deprecated"
  local user_mutable_refs="agents-registry.md agents.md"
  local core_names=""
  local ref=""
  local name=""
  local vault_copy=""
  local custom_section=""
  local custom_line=""
  local custom_table_rows=""
  local row=""
  local agent_name=""
  local last_table_line=""
  local repo_custom_line=""

  mkdir -p "$references_dir"
  core_names="$(build_core_agent_names "$source_agents_dir")"

  deprecate_removed_core_files "$source_references_dir" "$references_dir" "$manifest_file" "$deprecated_dir" "reference"

  for ref in "$source_references_dir"/*.md; do
    [[ -f "$ref" ]] || continue

    name="$(basename "$ref")"
    vault_copy="$references_dir/$name"

    if [[ " $user_mutable_refs " == *" $name "* ]] && [[ -f "$vault_copy" ]]; then
      custom_section=""
      custom_line=""
      custom_table_rows=""

      if grep -q '^## Custom Agents' "$vault_copy"; then
        custom_line="$(grep -n '^## Custom Agents' "$vault_copy" | head -n 1 | cut -d: -f1)"
        custom_section="$(tail -n +"$custom_line" "$vault_copy")"
      fi

      if [[ "$name" == "agents-registry.md" ]]; then
        while IFS= read -r row; do
          agent_name="$(printf '%s\n' "$row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
          if [[ -n "$agent_name" && " $core_names " != *" $agent_name "* ]]; then
            custom_table_rows+="${row}"$'\n'
          fi
        done < <(grep '^|' "$vault_copy" | grep -v '^|[[:space:]]*Name[[:space:]]*|' | grep -v '^|[-[:space:]]*|')
      fi

      if [[ ! -f "$vault_copy" ]] || ! diff -q "$ref" "$vault_copy" >/dev/null 2>&1; then
        cp "$ref" "$vault_copy"

        if [[ -n "$custom_table_rows" ]]; then
          last_table_line="$(grep -n '^|' "$vault_copy" | tail -n 1 | cut -d: -f1)"
          if [[ -n "$last_table_line" ]]; then
            {
              head -n "$last_table_line" "$vault_copy"
              printf '%s' "$custom_table_rows"
              tail -n +"$((last_table_line + 1))" "$vault_copy"
            } > "$vault_copy.tmp"
            mv "$vault_copy.tmp" "$vault_copy"
          fi
        fi

        if [[ -n "$custom_section" ]]; then
          repo_custom_line="$(grep -n '^## Custom Agents' "$vault_copy" | head -n 1 | cut -d: -f1)"
          if [[ -n "$repo_custom_line" ]]; then
            head -n "$((repo_custom_line - 1))" "$vault_copy" > "$vault_copy.tmp"
            printf '%s\n' "$custom_section" >> "$vault_copy.tmp"
            mv "$vault_copy.tmp" "$vault_copy"
          fi
        fi

        info "Updated $PLATFORM_NAME reference: $name (preserved custom content)"
        REF_COUNT=$((REF_COUNT + 1))
      fi

      continue
    fi

    if sync_file "$ref" "$vault_copy" "Updated $PLATFORM_NAME reference: $name" "Added $PLATFORM_NAME reference: $name"; then
      REF_COUNT=$((REF_COUNT + 1))
    fi
  done

  write_manifest_from_source "$source_references_dir" "$manifest_file"
}

sync_skills() {
  local source_skills_dir="$1"
  local install_root="$2"
  local skills_dir="$install_root/skills"
  local manifest_file="$skills_dir/.core-manifest"
  local deprecated_dir="$install_root/deprecated/skills"
  local skill_dir=""
  local skill_name=""
  local src=""
  local dst=""

  [[ -d "$source_skills_dir" ]] || return 0

  mkdir -p "$skills_dir"

  if [[ -f "$manifest_file" ]]; then
    while IFS= read -r skill_name || [[ -n "$skill_name" ]]; do
      local source_skill_dir="$source_skills_dir/$skill_name"
      local vault_skill_dir="$skills_dir/$skill_name"
      local deprecated_name="${skill_name}-DEPRECATED"

      if ! is_safe_manifest_entry "$skill_name"; then
        [[ -n "$skill_name" ]] && warn "Skipping invalid managed skill manifest entry: $skill_name"
        continue
      fi
      [[ -d "$source_skill_dir" && -f "$source_skill_dir/SKILL.md" ]] && continue
      [[ -d "$vault_skill_dir" ]] || continue

      mkdir -p "$deprecated_dir"
      [[ -e "$deprecated_dir/$deprecated_name" ]] && continue

      mv "$vault_skill_dir" "$deprecated_dir/$deprecated_name"
      if [[ -f "$deprecated_dir/$deprecated_name/SKILL.md" ]]; then
        prepend_deprecation_header "$deprecated_dir/$deprecated_name/SKILL.md"
      fi
      warn "Deprecated skill: $skill_name -> deprecated/skills/$deprecated_name"
      DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
    done < "$manifest_file"
  fi

  : > "$manifest_file"

  for skill_dir in "$source_skills_dir"/*/; do
    [[ -d "$skill_dir" ]] || continue
    [[ -f "$skill_dir/SKILL.md" ]] || continue

    skill_name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    dst="$install_root/skills/$skill_name/SKILL.md"
    echo "$skill_name" >> "$manifest_file"

    if sync_file "$src" "$dst" "Updated $PLATFORM_NAME skill: $skill_name" "Added $PLATFORM_NAME skill: $skill_name"; then
      SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
  done
}

sync_dispatcher() {
  local source_root="$1"
  local dispatcher_src="$source_root/$DISPATCHER_FILE"
  local dispatcher_dst="$VAULT_DIR/$DISPATCHER_FILE"

  [[ -f "$dispatcher_src" ]] || return 0

  if sync_file "$dispatcher_src" "$dispatcher_dst" "Updated $DISPATCHER_FILE for $PLATFORM_NAME" "Added $DISPATCHER_FILE for $PLATFORM_NAME"; then
    DISPATCHER_COUNT=$((DISPATCHER_COUNT + 1))
  fi
}

sync_claude_configs() {
  local source_root="$1"
  local install_root="$2"
  local hook=""
  local hook_name=""
  local mcp_src="$source_root/.mcp.json"
  local mcp_dst="$VAULT_DIR/.mcp.json"

  if [[ -d "$source_root/hooks" ]]; then
    mkdir -p "$install_root/hooks"
    for hook in "$source_root/hooks"/*.sh; do
      [[ -f "$hook" ]] || continue
      hook_name="$(basename "$hook")"
      if sync_file "$hook" "$install_root/hooks/$hook_name" "Updated $PLATFORM_NAME hook: $hook_name" "Added $PLATFORM_NAME hook: $hook_name" "+x"; then
        HOOK_COUNT=$((HOOK_COUNT + 1))
      fi
    done
  fi

  if [[ -f "$source_root/settings.json" ]]; then
    if sync_file "$source_root/settings.json" "$install_root/settings.json" "Updated $PLATFORM_NAME settings.json" "Added $PLATFORM_NAME settings.json"; then
      CONFIG_COUNT=$((CONFIG_COUNT + 1))
    fi
  fi

  if [[ -f "$mcp_src" && -f "$mcp_dst" ]]; then
    if sync_file "$mcp_src" "$mcp_dst" "Updated .mcp.json" "Added .mcp.json"; then
      CONFIG_COUNT=$((CONFIG_COUNT + 1))
    fi
  fi
}

merge_opencode_config() {
  local source_config="$1"
  local target_config="$2"
  local managed_plugin_spec="./.crew/crew-hooks.js"
  local merged_config_file=""
  local existed=0

  [[ -f "$source_config" ]] || die "OpenCode build output is missing opencode.json: $source_config"

  [[ -f "$target_config" ]] && existed=1
  merged_config_file="$(mktemp "/tmp/crew-opencode-update.XXXXXX")"

  if ! opencode_merge_config "$source_config" "$target_config" "$managed_plugin_spec" "$merged_config_file"; then
    rm -f "$merged_config_file"
    die "${OPENCODE_JSON_ERROR:-Failed to merge OpenCode config}"
  fi

  if replace_file_if_changed "$merged_config_file" "$target_config"; then
    if [[ $existed -eq 1 ]]; then
      info "Updated $PLATFORM_NAME opencode.json (preserved existing non-plugin config)"
    else
      info "Added $PLATFORM_NAME opencode.json"
    fi
    return 0
  fi

  return 1
}

sync_platform_configs() {
  local platform="$1"
  local source_root="$2"
  local install_root="$3"

  case "$platform" in
    claude)
      sync_claude_configs "$source_root" "$install_root"
      ;;
    opencode)
      if [[ -f "$source_root/.crew/crew-hooks.js" ]]; then
        if sync_file "$source_root/.crew/crew-hooks.js" "$install_root/.crew/crew-hooks.js" "Updated $PLATFORM_NAME hook artifact: crew-hooks.js" "Added $PLATFORM_NAME hook artifact: crew-hooks.js"; then
          HOOK_COUNT=$((HOOK_COUNT + 1))
        fi
      else
        die "OpenCode build output is missing .crew/crew-hooks.js"
      fi

      if [[ -d "$source_root/hooks" ]]; then
        mkdir -p "$install_root/hooks"
        for hook in "$source_root/hooks"/*.sh; do
          [[ -f "$hook" ]] || continue
          hook_name="$(basename "$hook")"
          if sync_file "$hook" "$install_root/hooks/$hook_name" "Updated $PLATFORM_NAME hook: $hook_name" "Added $PLATFORM_NAME hook: $hook_name" "+x"; then
            HOOK_COUNT=$((HOOK_COUNT + 1))
          fi
        done
      fi

      if merge_opencode_config "$source_root/opencode.json" "$install_root/opencode.json"; then
        CONFIG_COUNT=$((CONFIG_COUNT + 1))
      fi
      ;;
    gemini)
      if [[ -d "$source_root/hooks" ]]; then
        mkdir -p "$install_root/hooks"
        for hook in "$source_root/hooks"/*.sh; do
          [[ -f "$hook" ]] || continue
          hook_name="$(basename "$hook")"
          if sync_file "$hook" "$install_root/hooks/$hook_name" "Updated $PLATFORM_NAME hook: $hook_name" "Added $PLATFORM_NAME hook: $hook_name" "+x"; then
            HOOK_COUNT=$((HOOK_COUNT + 1))
          fi
        done
      fi

      if [[ -f "$source_root/settings.json" ]]; then
        if sync_file "$source_root/settings.json" "$install_root/settings.json" "Updated $PLATFORM_NAME settings.json" "Added $PLATFORM_NAME settings.json"; then
          CONFIG_COUNT=$((CONFIG_COUNT + 1))
        fi
      fi
      ;;
    codex)
      if [[ -d "$source_root/hooks" ]]; then
        mkdir -p "$install_root/hooks"
        for hook in "$source_root/hooks"/*.sh; do
          [[ -f "$hook" ]] || continue
          hook_name="$(basename "$hook")"
          if sync_file "$hook" "$install_root/hooks/$hook_name" "Updated $PLATFORM_NAME hook: $hook_name" "Added $PLATFORM_NAME hook: $hook_name" "+x"; then
            HOOK_COUNT=$((HOOK_COUNT + 1))
          fi
        done
      fi

      if [[ -f "$source_root/config.toml" ]]; then
        if sync_file "$source_root/config.toml" "$install_root/config.toml" "Updated $PLATFORM_NAME config.toml" "Added $PLATFORM_NAME config.toml"; then
          CONFIG_COUNT=$((CONFIG_COUNT + 1))
        fi
      fi

      if [[ -f "$source_root/hooks.json" ]]; then
        if sync_file "$source_root/hooks.json" "$install_root/hooks.json" "Updated $PLATFORM_NAME hooks.json" "Added $PLATFORM_NAME hooks.json"; then
          CONFIG_COUNT=$((CONFIG_COUNT + 1))
        fi
      fi
      ;;
  esac
}

prepare_platform_source() {
  local platform="$1"
  local install_root=""
  local persisted_models_file=""

  load_platform_env "$platform"
  install_root="$VAULT_DIR/$PLATFORM_DIR"
  persisted_models_file="$install_root/.installer-models.env"

  INSTALL_ROOT="$install_root"

  if [[ "$platform" == "claude" && ! -f "$persisted_models_file" ]]; then
    info "Using legacy Claude updater flow from repo files"
    SOURCE_ROOT="$REPO_DIR"
    SOURCE_AGENTS_DIR="$REPO_DIR/agents"
    SOURCE_REFERENCES_DIR="$REPO_DIR/references"
    SOURCE_SKILLS_DIR="$REPO_DIR/skills"
    return 0
  fi

  if [[ -f "$persisted_models_file" ]]; then
    validate_overrides_file "$persisted_models_file"
    info "Rebuilding $PLATFORM_NAME with saved model preferences"
    "$REPO_DIR/scripts/build.sh" "$platform" --overrides "$persisted_models_file"
  else
    info "Rebuilding $PLATFORM_NAME with platform defaults"
    "$REPO_DIR/scripts/build.sh" "$platform"
  fi

  SOURCE_ROOT="$REPO_DIR/build/$platform"
  SOURCE_AGENTS_DIR="$SOURCE_ROOT/agents"
  SOURCE_REFERENCES_DIR="$SOURCE_ROOT/references"
  SOURCE_SKILLS_DIR="$SOURCE_ROOT/skills"

  [[ -d "$SOURCE_AGENTS_DIR" ]] || die "Build output missing agents/ for $platform"
  [[ -d "$SOURCE_REFERENCES_DIR" ]] || die "Build output missing references/ for $platform"
  [[ -f "$SOURCE_ROOT/$DISPATCHER_FILE" ]] || die "Build output missing $DISPATCHER_FILE for $platform"
}

detect_installed_platforms

if [[ ${#INSTALLED_PLATFORMS[@]} -eq 0 ]]; then
  die "No managed platform installs found in $VAULT_DIR — expected project markers for .claude, .opencode, .gemini, or .codex"
fi

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  My Brain Is Full - Crew :: Update       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "   Detected installs: ${BOLD}$(join_by_comma "${INSTALLED_PLATFORM_NAMES[@]}")${NC}"
echo ""

# ── Confirm overwrite ───────────────────────────────────────────────────────
echo -e "${BOLD}This will overwrite managed agent files, references, skills, dispatchers, and installed platform configs.${NC}"
echo -e "   ${DIM}Custom agent files in installed platform directories will not be deleted or overwritten.${NC}"
echo -e "   ${DIM}Custom agent entries in registry/directory references will be preserved during update.${NC}"
echo -e "   ${DIM}Your vault notes are never touched.${NC}"
echo ""
echo -e "   ${BOLD}c)${NC} Continue"
echo -e "   ${BOLD}q)${NC} Quit"
if ! read -r -p "   > " UPDATE_ANSWER 2>/dev/null; then UPDATE_ANSWER=""; fi
if [[ ! "$UPDATE_ANSWER" =~ ^[Cc]$ ]]; then
  echo ""
  info "Update cancelled."
  echo ""
  exit 0
fi
echo ""

mkdir -p "$VAULT_DIR/Meta/states"

for platform in "${INSTALLED_PLATFORMS[@]}"; do
  prepare_platform_source "$platform"

  echo ""
  info "Updating $PLATFORM_NAME in $PLATFORM_DIR/"

  apply_codex_protected_permissions "$platform" "$INSTALL_ROOT" "$VAULT_DIR/$DISPATCHER_FILE" unlock
  sync_agents "$SOURCE_AGENTS_DIR" "$INSTALL_ROOT"
  sync_references "$SOURCE_REFERENCES_DIR" "$SOURCE_AGENTS_DIR" "$INSTALL_ROOT"
  sync_skills "$SOURCE_SKILLS_DIR" "$INSTALL_ROOT"
  sync_dispatcher "$SOURCE_ROOT"
  sync_platform_configs "$platform" "$SOURCE_ROOT" "$INSTALL_ROOT"
  apply_codex_protected_permissions "$platform" "$INSTALL_ROOT" "$VAULT_DIR/$DISPATCHER_FILE" harden
done

# ── Remove stale orchestra scripts ────────────────────────────────────────
ORCH_MANIFEST="$VAULT_DIR/Meta/scripts/.core-manifest"
REMOVED_SCRIPTS=0
if [[ -d "$REPO_DIR/orchestra" && -f "$ORCH_MANIFEST" ]]; then
  while IFS= read -r old_script; do
    [[ -z "$old_script" ]] && continue
    [[ -f "$REPO_DIR/orchestra/$old_script" ]] && continue
    vault_script="$VAULT_DIR/Meta/scripts/$old_script"
    [[ -f "$vault_script" ]] || continue
    rm "$vault_script"
    warn "Removed stale script: $old_script"
    REMOVED_SCRIPTS=$((REMOVED_SCRIPTS + 1))
  done < "$ORCH_MANIFEST"
fi

# ── Update orchestra scripts ──────────────────────────────────────────────
ORCH_COUNT=0
if [[ -d "$REPO_DIR/orchestra" ]]; then
  mkdir -p "$VAULT_DIR/Meta/scripts"
  : > "$VAULT_DIR/Meta/scripts/.core-manifest"
  for script in "$REPO_DIR/orchestra/"*; do
    [[ -f "$script" ]] || continue
    bname="$(basename "$script")"
    [[ "$bname" == "README.md" ]] && continue
    echo "$bname" >> "$VAULT_DIR/Meta/scripts/.core-manifest"
    dst="$VAULT_DIR/Meta/scripts/$bname"
    if [[ ! -f "$dst" ]] || ! diff -q "$script" "$dst" >/dev/null 2>&1; then
      cp "$script" "$dst"
      chmod +x "$dst"
      info "Updated script: $bname"
      ORCH_COUNT=$((ORCH_COUNT + 1))
    fi
  done
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
if [[ $AGENT_COUNT -eq 0 && $REF_COUNT -eq 0 && $SKILL_COUNT -eq 0 && $HOOK_COUNT -eq 0 && $CONFIG_COUNT -eq 0 && $DISPATCHER_COUNT -eq 0 && $ORCH_COUNT -eq 0 && $DEPRECATED_COUNT -eq 0 && $REMOVED_SCRIPTS -eq 0 ]]; then
  success "Everything is already up to date for $(join_by_comma "${INSTALLED_PLATFORM_NAMES[@]}")!"
else
  success "Updated $AGENT_COUNT agent(s), $SKILL_COUNT skill(s), $REF_COUNT reference(s), $HOOK_COUNT hook(s), $CONFIG_COUNT config file(s), $DISPATCHER_COUNT dispatcher file(s), and $ORCH_COUNT script(s)"
  if [[ $DEPRECATED_COUNT -gt 0 ]]; then
    warn "Deprecated $DEPRECATED_COUNT removed core file(s)"
  fi
  if [[ $REMOVED_SCRIPTS -gt 0 ]]; then
    warn "Removed $REMOVED_SCRIPTS stale script(s) from Meta/scripts/"
  fi
fi
echo ""
echo -e "   ${DIM}Restart your installed platform(s) to pick up the changes.${NC}"
echo ""
