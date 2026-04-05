#!/usr/bin/env bash
# Usage: ./scripts/build.sh <claude|opencode|gemini|codex|all>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$REPO_DIR/templates"
PLATFORMS_DIR="$REPO_DIR/platforms"
BUILD_DIR="$REPO_DIR/build"

# ── Colors (matches launchme.sh/validate.sh convention) ──────────────────────

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
  RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; CYAN=''; YELLOW=''; RED=''; BOLD=''; NC=''
fi

info()    { echo -e "   ${CYAN}>${NC} $*"; }
success() { echo -e "   ${GREEN}✓${NC} $*"; }
warn()    { echo -e "   ${YELLOW}!${NC} $*"; }
die()     { echo -e "\n   ${RED}Error: $*${NC}\n" >&2; exit 1; }

# ── Prerequisites ────────────────────────────────────────────────────────────

if ! command -v yq &>/dev/null; then
  die "yq is required but not found. Install: brew install yq (macOS) or snap install yq (Linux)"
fi

# ── Arguments ────────────────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <claude|opencode|gemini|codex|all>"
  exit 1
fi

TARGET="$1"

# ── Expand {{VAR}} in a template, protecting fenced code blocks ──────────────

expand_file() {
  local src="$1"
  local dst="$2"
  local sed_file="$3"

  # awk tags lines: F (inside ``` fence) or E (outside). Only E lines get sed.
  awk '
    BEGIN { in_fence = 0 }
    /^```/ { in_fence = !in_fence; print "F:" $0; next }
    { if (in_fence) print "F:" $0; else print "E:" $0 }
  ' "$src" | while IFS= read -r tagged_line; do
    local prefix="${tagged_line%%:*}"
    local content="${tagged_line#?:}"
    if [[ "$prefix" == "E" ]]; then
      printf '%s\n' "$content" | sed -f "$sed_file"
    else
      printf '%s\n' "$content"
    fi
  done > "$dst"
}

# ── Build sed script from env KEY=VALUE pairs ────────────────────────────────

build_sed_script() {
  local env_file="$1"
  local sed_file="$2"

  : > "$sed_file"

  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    local key="${line%%=*}"
    local value="${line#*=}"
    value="${value#\"}"
    value="${value%\"}"

    local escaped_value
    escaped_value=$(printf '%s' "$value" | sed 's/[&\\/]/\\&/g')

    printf 's/{{%s}}/%s/g\n' "$key" "$escaped_value" >> "$sed_file"
  done < "$env_file"
}

# ── Gemini: convert comma-separated tools: to YAML list ──────────────────────

convert_tools_to_yaml_list() {
  local file="$1"

  local first_line
  first_line=$(head -n 1 "$file")
  [[ "$first_line" != "---" ]] && return 0

  local frontmatter
  frontmatter=$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit; next} n==1{print}' "$file")

  if ! printf '%s\n' "$frontmatter" | grep -q '^tools:'; then
    return 0
  fi

  local tools_value
  tools_value=$(printf '%s\n' "$frontmatter" | yq eval '.tools' -)

  if [[ "$tools_value" == -* ]] || [[ "$tools_value" == "["* ]]; then
    return 0
  fi

  local new_frontmatter
  new_frontmatter=$(printf '%s\n' "$frontmatter" | yq eval '.tools = (.tools | split(", "))' -)

  local body
  body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$file")

  {
    printf '%s\n' "---"
    printf '%s\n' "$new_frontmatter"
    printf '%s\n' "---"
    printf '%s\n' "$body"
  } > "$file"
}

build_platform() {
  local platform="$1"

  local env_file="$PLATFORMS_DIR/${platform}.env"
  if [[ ! -f "$env_file" ]]; then
    die "Platform env file not found: $env_file"
  fi

  local platform_build="$BUILD_DIR/$platform"

  echo ""
  echo -e "${BOLD}Building: ${platform}${NC}"
  echo ""

  if [[ -d "$platform_build" ]]; then
    rm -rf "$platform_build"
    info "Cleaned previous build"
  fi

  mkdir -p "$platform_build/agents"
  mkdir -p "$platform_build/references"

  # shellcheck source=/dev/null
  source "$env_file"

  local sed_file
  sed_file=$(mktemp)
  build_sed_script "$env_file" "$sed_file"

  # ── Agents ──────────────────────────────────────────────────────────────

  info "Processing agents..."
  local agent_count=0
  for tmpl in "$TEMPLATES_DIR/agents/"*.md.tmpl; do
    [[ -f "$tmpl" ]] || continue
    local basename
    basename="$(basename "$tmpl" .md.tmpl)"
    local dst="$platform_build/agents/${basename}.md"
    expand_file "$tmpl" "$dst" "$sed_file"
    agent_count=$((agent_count + 1))
  done
  success "$agent_count agents"

  info "Processing skills..."
  local skill_count=0
  for skill_dir in "$TEMPLATES_DIR/skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    local skill_tmpl="$skill_dir/SKILL.md.tmpl"
    [[ -f "$skill_tmpl" ]] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$platform_build/skills/$skill_name"
    local dst="$platform_build/skills/$skill_name/SKILL.md"
    expand_file "$skill_tmpl" "$dst" "$sed_file"
    skill_count=$((skill_count + 1))
  done
  success "$skill_count skills"

  info "Processing references..."
  local ref_count=0
  for tmpl in "$TEMPLATES_DIR/references/"*.md.tmpl; do
    [[ -f "$tmpl" ]] || continue
    local basename
    basename="$(basename "$tmpl" .md.tmpl)"
    local dst="$platform_build/references/${basename}.md"
    expand_file "$tmpl" "$dst" "$sed_file"
    ref_count=$((ref_count + 1))
  done
  success "$ref_count references"

  info "Processing dispatcher..."
  local dispatcher_tmpl="$TEMPLATES_DIR/dispatchers/${DISPATCHER_FILE}.tmpl"
  if [[ ! -f "$dispatcher_tmpl" ]]; then
    die "Dispatcher template not found: $dispatcher_tmpl"
  fi
  local dst="$platform_build/$DISPATCHER_FILE"
  expand_file "$dispatcher_tmpl" "$dst" "$sed_file"
  success "Created $DISPATCHER_FILE"

  if [[ "$platform" == "gemini" ]]; then
    info "Converting tools to YAML lists..."
    for agent_file in "$platform_build/agents/"*.md; do
      [[ -f "$agent_file" ]] || continue
      convert_tools_to_yaml_list "$agent_file"
    done
    success "Tools converted"
  fi

  rm -f "$sed_file"

  info "Validating..."
  if "$REPO_DIR/scripts/validate.sh" "$platform_build"; then
    success "Validation passed"
  else
    die "Validation failed for $platform"
  fi

  echo ""
  echo -e "   ${GREEN}${BOLD}Build complete: ${platform}${NC}"
  echo ""
}

case "$TARGET" in
  claude|opencode|gemini)
    build_platform "$TARGET"
    ;;
  codex)
    warn "Codex build is not yet implemented (coming in T9)."
    exit 0
    ;;
  all)
    build_platform "claude"
    build_platform "opencode"
    build_platform "gemini"
    echo ""
    echo -e "${GREEN}${BOLD}   All platforms built successfully.${NC}"
    echo ""
    ;;
  *)
    die "Unknown platform: $TARGET. Use: claude, opencode, gemini, codex, or all"
    ;;
esac
