#!/usr/bin/env bash
# =============================================================================
# Validate Build Output
# =============================================================================
# Scans a build output directory for common issues:
#   1. Unresolved template variables ({{VAR_NAME}})
#   2. Invalid YAML frontmatter in .md files
#   3. Invalid TOML in .toml files
#   4. Expected file structure (agents count, skills count)
#   5. Empty files
#
# Usage: ./scripts/validate.sh <build-output-dir>
# Exit: 0 = clean (warnings OK), 1 = errors found
# =============================================================================

set -euo pipefail

# ── Prerequisites ────────────────────────────────────────────────────────────

if ! command -v yq &>/dev/null; then
  echo "yq is required. Install: brew install yq (macOS) or snap install yq (Linux)"
  exit 1
fi

# ── Arguments ────────────────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <build-output-dir>"
  exit 1
fi

BUILD_DIR="$1"

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "[ERROR] Directory does not exist: $BUILD_DIR"
  exit 1
fi

ERROR_COUNT=0

OPENCODE_MANAGED_PLUGIN_PATTERN='^(file://)?(\./)?\.crew/.+\.(cjs|mjs|js|ts|tsx)$'

error() {
  echo "[ERROR] $1" >&2
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

json_eval() {
  local file="$1"
  local expr="$2"
  local output

  if ! output=$(yq eval -oy -p json "$expr" "$file" 2>/dev/null); then
    return 1
  fi

  printf '%s\n' "$output"
}

infer_build_platform() {
  local build_dir_name

  build_dir_name=$(basename "$BUILD_DIR")

  case "$build_dir_name" in
    *claude*)
      printf 'claude\n'
      ;;
    *gemini*)
      printf 'gemini\n'
      ;;
    *opencode*)
      printf 'opencode\n'
      ;;
    *codex*)
      printf 'codex\n'
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_settings_platform() {
  local settings_file="$1"
  local platform_name=""
  local inferred_platform=""

  if ! platform_name=$(json_eval "$settings_file" '.platform'); then
    error "${settings_file}: invalid JSON"
    return 1
  fi

  case "$platform_name" in
    "Claude Code")
      printf 'claude\n'
      return 0
      ;;
    "Gemini CLI")
      printf 'gemini\n'
      return 0
      ;;
    ""|"null")
      ;;
    *)
      error "${settings_file}: unsupported settings.json platform metadata: ${platform_name}"
      return 1
      ;;
  esac

  if inferred_platform=$(infer_build_platform); then
    printf '%s\n' "$inferred_platform"
    return 0
  fi

  error "${settings_file}: unable to determine hook platform from settings.json or build directory"
  return 1
}

validate_native_hook_directory() {
  local platform_label="$1"
  local expected_hooks="protect-system-files.sh validate-frontmatter.sh notify.sh"
  local hook_name

  if [[ -d "${BUILD_DIR}/hooks" ]]; then
    for hook_name in $expected_hooks; do
      if [[ ! -f "${BUILD_DIR}/hooks/${hook_name}" ]]; then
        error "${BUILD_DIR}/hooks/${hook_name}: expected ${platform_label} hook script is missing"
      fi
    done
  else
    error "${BUILD_DIR}/hooks/: ${platform_label} hooks directory is missing"
  fi
}

validate_native_settings_hooks() {
  local settings_file="$1"
  local platform_label="$2"
  local required_events="$3"
  local hooks_type
  local event

  if ! hooks_type=$(json_eval "$settings_file" '.hooks | type'); then
    error "${settings_file}: invalid JSON"
    return
  fi
  if [[ "$hooks_type" == "!!null" ]]; then
    error "${settings_file}: ${platform_label} settings.json is missing the hooks object"
    return
  fi
  if [[ "$hooks_type" != "!!map" ]]; then
    error "${settings_file}: ${platform_label} settings.json hooks must be an object"
    return
  fi

  for event in $required_events; do
    local event_type
    local entry_count
    local first_hook_type

    if ! event_type=$(json_eval "$settings_file" ".hooks.${event} | type"); then
      error "${settings_file}: invalid JSON"
      return
    fi
    if [[ "$event_type" == "!!null" ]]; then
      error "${settings_file}: ${platform_label} hooks missing required event: ${event}"
      continue
    fi
    if [[ "$event_type" != "!!seq" ]]; then
      error "${settings_file}: ${platform_label} hooks.${event} must be an array"
      continue
    fi

    if ! entry_count=$(json_eval "$settings_file" ".hooks.${event} | length"); then
      error "${settings_file}: invalid JSON"
      return
    fi
    if [[ "$entry_count" -lt 1 ]]; then
      error "${settings_file}: ${platform_label} hooks.${event} must have at least one entry"
      continue
    fi

    if ! first_hook_type=$(json_eval "$settings_file" ".hooks.${event}[0].hooks[0].type"); then
      error "${settings_file}: invalid JSON"
      return
    fi
    if [[ "$first_hook_type" != "command" ]]; then
      error "${settings_file}: ${platform_label} hooks.${event}[0] must use type \"command\""
    fi
  done

  validate_native_hook_directory "$platform_label"
}

is_managed_opencode_plugin_spec() {
  [[ "$1" =~ $OPENCODE_MANAGED_PLUGIN_PATTERN ]]
}

normalize_opencode_plugin_spec() {
  local plugin_spec="$1"

  plugin_spec="${plugin_spec#file://}"
  plugin_spec="${plugin_spec#./}"

  printf '%s\n' "$plugin_spec"
}

validate_opencode_hook_artifacts() {
  local config_file="${BUILD_DIR}/opencode.json"
  local managed_plugin_dir="${BUILD_DIR}/.crew"
  local plugin_type
  local plugins_type
  local managed_count=0
  local managed_plugin_spec=""
  local normalized_plugin_path=""
  local -a managed_entries=()

  if [[ ! -f "$config_file" ]]; then
    if [[ -d "$managed_plugin_dir" ]]; then
      error "${config_file}: OpenCode config is missing while managed plugin artifacts exist"
    fi
    return 0
  fi

  if ! plugin_type=$(json_eval "$config_file" '.plugin | type'); then
    error "${config_file}: invalid JSON"
    return
  fi
  if [[ "$plugin_type" != "!!null" ]] && [[ "$plugin_type" != "!!seq" ]]; then
    error "${config_file}: singular plugin key must be an array when present"
    return
  fi

  if ! plugins_type=$(json_eval "$config_file" '.plugins | type'); then
    error "${config_file}: invalid JSON"
    return
  fi
  if [[ "$plugins_type" != "!!null" ]]; then
    error "${config_file}: use singular plugin key, not plugins, for the managed OpenCode plugin"
  fi

  if [[ "$plugin_type" == "!!seq" ]]; then
    while IFS= read -r plugin_entry; do
      [[ -z "$plugin_entry" ]] && continue
      if is_managed_opencode_plugin_spec "$plugin_entry"; then
        managed_entries+=("$plugin_entry")
      fi
    done < <(json_eval "$config_file" '.plugin[]')
  fi

  managed_count=${#managed_entries[@]}

  if [[ "$managed_count" -eq 0 ]]; then
    error "${config_file}: missing managed OpenCode plugin entry in singular plugin key"
    return
  fi

  if [[ "$managed_count" -gt 1 ]]; then
    error "${config_file}: duplicate OpenCode managed plugin entries found in singular plugin key"
    return
  fi

  if [[ "$managed_count" -eq 1 ]]; then
    managed_plugin_spec="${managed_entries[0]}"
    normalized_plugin_path=$(normalize_opencode_plugin_spec "$managed_plugin_spec")

    if [[ ! -f "${BUILD_DIR}/${normalized_plugin_path}" ]]; then
      error "${config_file}: managed OpenCode plugin artifact is missing: ${normalized_plugin_path}"
      return
    fi

    if [[ ! -s "${BUILD_DIR}/${normalized_plugin_path}" ]]; then
      error "${config_file}: managed OpenCode plugin artifact is empty: ${normalized_plugin_path}"
    fi
  fi

  if [[ -d "${BUILD_DIR}/hooks" ]]; then
    local expected_hooks="protect-system-files.sh validate-frontmatter.sh notify.sh"
    for hook_name in $expected_hooks; do
      if [[ ! -f "${BUILD_DIR}/hooks/${hook_name}" ]]; then
        error "${BUILD_DIR}/hooks/${hook_name}: expected OpenCode hook script is missing"
      fi
    done
  else
    error "${BUILD_DIR}/hooks/: OpenCode hooks directory is missing"
  fi
}

validate_gemini_hook_artifacts() {
  local settings_file="$1"

  local has_models
  if ! has_models=$(json_eval "$settings_file" '.models | type'); then
    error "${settings_file}: invalid JSON"
    return
  fi
  if [[ "$has_models" == "!!null" ]]; then
    error "${settings_file}: Gemini settings.json is missing the models object"
  fi

  validate_native_settings_hooks "$settings_file" "Gemini" "BeforeTool AfterTool Notification"
}

validate_claude_hook_artifacts() {
  local settings_file="$1"

  validate_native_settings_hooks "$settings_file" "Claude" "PreToolUse PostToolUse Notification"
}

validate_settings_hook_artifacts() {
  local settings_file="${BUILD_DIR}/settings.json"
  local settings_platform

  if [[ ! -f "$settings_file" ]]; then
    return 0
  fi

  settings_platform=$(resolve_settings_platform "$settings_file") || return

  case "$settings_platform" in
    claude)
      validate_claude_hook_artifacts "$settings_file"
      ;;
    gemini)
      validate_gemini_hook_artifacts "$settings_file"
      ;;
  esac
}

validate_codex_hook_artifacts() {
  local config_file="${BUILD_DIR}/config.toml"
  local hooks_file="${BUILD_DIR}/hooks.json"

  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  local has_models
  has_models=$(yq eval -p toml '.models | type' "$config_file" 2>/dev/null)
  if [[ "$has_models" == "!!null" ]]; then
    error "${config_file}: Codex config.toml is missing the [models] table"
  fi

  local hooks_enabled
  hooks_enabled=$(yq eval -p toml '.features.codex_hooks' "$config_file" 2>/dev/null)
  if [[ "$hooks_enabled" != "true" ]]; then
    error "${config_file}: Codex config.toml is missing [features] codex_hooks = true"
  fi

  if [[ ! -f "$hooks_file" ]]; then
    error "${BUILD_DIR}/hooks.json: Codex hooks.json is missing"
    return
  fi

  local hooks_json_valid
  hooks_json_valid=$(yq eval -oy -p json '.' "$hooks_file" 2>/dev/null)
  if [[ -z "$hooks_json_valid" ]]; then
    error "${hooks_file}: Codex hooks.json is not valid JSON"
    return
  fi

  local hooks_obj_type
  if ! hooks_obj_type=$(json_eval "$hooks_file" '.hooks | type'); then
    error "${hooks_file}: invalid JSON"
    return
  fi
  if [[ "$hooks_obj_type" == "!!null" ]]; then
    error "${hooks_file}: Codex hooks.json is missing the hooks object"
    return
  fi

  local required_events="PreToolUse PostToolUse Stop"
  for event in $required_events; do
    local event_type
    if ! event_type=$(json_eval "$hooks_file" ".hooks.${event} | type"); then
      error "${hooks_file}: invalid JSON"
      return
    fi
    if [[ "$event_type" == "!!null" ]]; then
      error "${hooks_file}: Codex hooks.json missing required event: ${event}"
      continue
    fi

    local entry_count
    if ! entry_count=$(json_eval "$hooks_file" ".hooks.${event} | length"); then
      error "${hooks_file}: invalid JSON"
      return
    fi
    if [[ "$entry_count" -lt 1 ]]; then
      error "${hooks_file}: Codex hooks.${event} must have at least one entry"
      continue
    fi

    if [[ "$event" == "PreToolUse" || "$event" == "PostToolUse" ]]; then
      local matcher
      if ! matcher=$(json_eval "$hooks_file" ".hooks.${event}[0].matcher"); then
        error "${hooks_file}: invalid JSON"
        return
      fi
      if [[ "$matcher" != "Bash" ]]; then
        error "${hooks_file}: Codex hooks.${event}[0].matcher must be \"Bash\" (Codex only supports Bash tool interception)"
      fi
    fi
  done

  if [[ -d "${BUILD_DIR}/hooks" ]]; then
    local expected_hooks="protect-system-files.sh validate-frontmatter.sh notify.sh"
    for hook_name in $expected_hooks; do
      if [[ ! -f "${BUILD_DIR}/hooks/${hook_name}" ]]; then
        error "${BUILD_DIR}/hooks/${hook_name}: expected Codex hook script is missing"
      fi
    done
  else
    error "${BUILD_DIR}/hooks/: Codex hooks directory is missing"
  fi
}

# ── Check 1: Unresolved build variables ─────────────────────────────────────

is_allowed_runtime_placeholder() {
  case "$1" in
    A|B|DD|MM|N|X|Y|YY|YYYY)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_unresolved_build_placeholder() {
  local placeholder="$1"

  case "$placeholder" in
    PLATFORM_*|TOOL_*|MODEL_*|DISPATCHER_FILE)
      return 0
      ;;
  esac

  if [[ "$placeholder" =~ ^[A-Z][A-Z0-9_]*$ ]] && ! is_allowed_runtime_placeholder "$placeholder"; then
    return 0
  fi

  return 1
}

while IFS= read -r -d '' file; do
  [[ "$file" == *.tmpl ]] && continue
  [[ "$file" == *tests/fixtures/invalid-*.md ]] && continue

  while IFS=: read -r line_num line_content; do
    remaining="$line_content"
    while [[ "$remaining" =~ \{\{([^}]+)\}\} ]]; do
      var_name="${BASH_REMATCH[1]}"
      match="${BASH_REMATCH[0]}"

      if is_unresolved_build_placeholder "$var_name"; then
        error "${file}:${line_num}: unresolved variable {{${var_name}}}"
      fi

      remaining="${remaining#*"$match"}"
    done
  done < <(awk '{print NR ":" $0}' "$file")
done < <(find "$BUILD_DIR" -type f \( -name '*.md' -o -name '*.toml' \) -print0)

# ── Check 2: YAML frontmatter validity ──────────────────────────────────────
# For each .md file starting with ---, extract and validate frontmatter.
# Files without frontmatter are OK.

while IFS= read -r -d '' file; do
  first_line=$(head -n 1 "$file")
  [[ "$first_line" != "---" ]] && continue

  # Extract YAML between first and second --- delimiters
  frontmatter=$(awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print}' "$file")

  if [[ -z "$frontmatter" ]]; then
    continue
  fi

  if ! yq eval '.' - <<< "$frontmatter" &>/dev/null; then
    error "${file}: invalid YAML frontmatter"
  fi
done < <(find "$BUILD_DIR" -type f -name '*.md' -print0)

# ── Check 3: TOML validity ──────────────────────────────────────────────────

while IFS= read -r -d '' file; do
  if ! yq eval -p toml '.' "$file" &>/dev/null; then
    error "${file}: invalid TOML"
  fi
done < <(find "$BUILD_DIR" -type f -name '*.toml' -print0)

# ── Check 4: Required file structure ────────────────────────────────────────
# Warn (don't fail) if agent/skill counts are unexpected.

if [[ -d "${BUILD_DIR}/agents" ]]; then
  agent_count=$(find "${BUILD_DIR}/agents" -maxdepth 1 -type f \( -name '*.md' -o -name '*.toml' \) | wc -l)
  if [[ "$agent_count" -ne 8 ]]; then
    echo "[WARN] agents/ has ${agent_count} files (expected 8)"
  fi
fi

if [[ -d "${BUILD_DIR}/skills" ]]; then
  skill_count=$(find "${BUILD_DIR}/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [[ "$skill_count" -ne 14 ]]; then
    echo "[WARN] skills/ has ${skill_count} subdirectories (expected 14)"
  fi
fi

# ── Check 5: Empty files ────────────────────────────────────────────────────

while IFS= read -r -d '' file; do
  error "${file}: empty file (zero bytes)"
done < <(find "$BUILD_DIR" -type f \( -name '*.md' -o -name '*.toml' -o -name '*.json' -o -name '*.sh' \) -empty -print0)

validate_opencode_hook_artifacts
validate_settings_hook_artifacts
validate_codex_hook_artifacts

# ── Result ───────────────────────────────────────────────────────────────────

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  echo ""
  echo "Validation failed: ${ERROR_COUNT} error(s) found."
  exit 1
fi

echo "Validation passed."
exit 0
