#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Installer
# =============================================================================
# Run this from inside the cloned repo, which should be inside your vault:
#
#   cd /path/to/your-vault/My-Brain-Is-Full-Crew
#   bash scripts/launchme.sh
#
# It copies agents, skills, references, hooks, and settings into the vault's
# .claude/ directory.
#
# Options:
#   --platform <name>    Platform to build for (interactive selection if omitted)
#   --target <path>      Override the vault destination path
# =============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_paths "${BASH_SOURCE[0]}"

# ── Parse args ─────────────────────────────────────────────────────────────
PLATFORM=""
TARGET_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --target)    TARGET_OVERRIDE="$2"; shift 2 ;;
    *) die "Unknown argument: $1 (use --platform <name> or --target <path>)" ;;
  esac
done
[[ -n "$TARGET_OVERRIDE" ]] && VAULT_DIR="$TARGET_OVERRIDE"

# ── Platform selection (interactive if not specified) ──────────────────────
if [[ -z "$PLATFORM" ]]; then
  # Discover available platforms from adapters/ directories
  AVAILABLE=()
  for d in "$REPO_DIR/adapters/"*/; do
    [[ -f "${d}adapter.sh" ]] || continue
    AVAILABLE+=("$(basename "$d")")
  done
  if [[ ${#AVAILABLE[@]} -eq 0 ]]; then
    die "No adapters found in adapters/"
  fi
  echo ""
  echo -e "   ${BOLD}Select your agent platform:${NC}"
  echo ""
  for i in "${!AVAILABLE[@]}"; do
    echo -e "   ${BOLD}$((i+1)))${NC} ${AVAILABLE[$i]}"
  done
  echo ""
  if ! read -r -p "   > " PLATFORM_CHOICE 2>/dev/null; then PLATFORM_CHOICE=""; fi
  # Accept either number or name
  if [[ "$PLATFORM_CHOICE" =~ ^[0-9]+$ ]] && (( PLATFORM_CHOICE >= 1 && PLATFORM_CHOICE <= ${#AVAILABLE[@]} )); then
    PLATFORM="${AVAILABLE[$((PLATFORM_CHOICE-1))]}"
  else
    # Try matching by name
    for p in "${AVAILABLE[@]}"; do
      if [[ "$p" == "$PLATFORM_CHOICE" ]]; then
        PLATFORM="$p"
        break
      fi
    done
  fi
  [[ -n "$PLATFORM" ]] || die "Invalid selection: $PLATFORM_CHOICE"
  echo ""
  info "Selected platform: $PLATFORM"
fi

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner "Setup        "
echo -e "   Repo:   ${BOLD}${REPO_DIR}${NC}"
echo -e "   Vault:  ${BOLD}${VAULT_DIR}${NC}"
echo ""

# ── Confirm vault location ────────────────────────────────────────────────────
if [[ -z "$TARGET_OVERRIDE" ]]; then
  echo -e "${BOLD}Is this your Obsidian vault folder?${NC}"
  echo -e "   ${DIM}${VAULT_DIR}${NC}"
  echo ""
  echo -e "   ${BOLD}y)${NC} Yes, install here"
  echo -e "   ${BOLD}n)${NC} No, let me type the correct path"
  if ! read -r -p "   > " CONFIRM 2>/dev/null; then CONFIRM=""; fi

  if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${BOLD}Enter the full path to your Obsidian vault:${NC}"
    if ! read -r -p "   > " VAULT_DIR 2>/dev/null; then
      die "Cannot read input — are you running in a non-interactive shell?"
    fi
    VAULT_DIR="${VAULT_DIR/#\~/$HOME}"
    [[ -d "$VAULT_DIR" ]] || die "Directory not found: $VAULT_DIR"
  fi
fi

# ── Check for existing installation ──────────────────────────────────────────
EXISTING=0
[[ -d "$VAULT_DIR/.claude" ]]    && EXISTING=1
[[ -d "$VAULT_DIR/.opencode" ]]  && EXISTING=1
[[ -d "$VAULT_DIR/.gemini" ]]    && EXISTING=1
[[ -f "$VAULT_DIR/CLAUDE.md" ]]  && EXISTING=1
[[ -f "$VAULT_DIR/AGENTS.md" ]]  && EXISTING=1
[[ -f "$VAULT_DIR/GEMINI.md" ]]  && EXISTING=1

if [[ $EXISTING -eq 1 ]]; then
  warn "An existing installation was detected:"
  [[ -d "$VAULT_DIR/.claude" ]]   && warn "  .claude/ directory exists"
  [[ -d "$VAULT_DIR/.opencode" ]] && warn "  .opencode/ directory exists"
  [[ -d "$VAULT_DIR/.gemini" ]]   && warn "  .gemini/ directory exists"
  [[ -f "$VAULT_DIR/CLAUDE.md" ]] && warn "  CLAUDE.md exists"
  [[ -f "$VAULT_DIR/AGENTS.md" ]] && warn "  AGENTS.md exists"
  [[ -f "$VAULT_DIR/GEMINI.md" ]] && warn "  GEMINI.md exists"
  echo ""
  echo -e "   ${BOLD}The installer will overwrite core files. Custom agents are never deleted.${NC}"
  echo -e "   ${DIM}Your vault notes are never touched.${NC}"
  echo ""
  echo -e "   ${BOLD}c)${NC} Continue"
  echo -e "   ${BOLD}q)${NC} Quit"
  if ! read -r -p "   > " ANSWER 2>/dev/null; then ANSWER=""; fi
  if [[ ! "$ANSWER" =~ ^[Cc]$ ]]; then
    echo ""; info "Installation cancelled."; echo ""; exit 0
  fi
fi

echo ""

# ── Build the platform dist ───────────────────────────────────────────────
info "Building $PLATFORM adapter..."
bash "$SCRIPT_DIR/build.sh" --platform "$PLATFORM"
DIST_DIR="$REPO_DIR/dist/$PLATFORM"
[[ -d "$DIST_DIR" ]] || die "Build did not produce $DIST_DIR"

# ── Platform-specific install layout ────────────────────────────────────────
case "$PLATFORM" in
  claude-code)
    DIST_COMPONENTS_DIR="$DIST_DIR/.claude"
    VAULT_COMPONENTS_DIR="$VAULT_DIR/.claude"
    DISPATCHER_SRC="$DIST_DIR/CLAUDE.md"
    DISPATCHER_DST="$VAULT_DIR/CLAUDE.md"
    MCP_SRC="$DIST_DIR/.mcp.json"
    MCP_DST="$VAULT_DIR/.mcp.json"
    HAS_PLUGINS=0
    ;;
  opencode)
    DIST_COMPONENTS_DIR="$DIST_DIR/.opencode"
    VAULT_COMPONENTS_DIR="$VAULT_DIR/.opencode"
    DISPATCHER_SRC="$DIST_DIR/AGENTS.md"
    DISPATCHER_DST="$VAULT_DIR/AGENTS.md"
    MCP_SRC="$DIST_DIR/opencode.json"
    MCP_DST="$VAULT_DIR/opencode.json"
    HAS_PLUGINS=1
    ;;
  gemini-cli)
    DIST_COMPONENTS_DIR="$DIST_DIR/.gemini"
    VAULT_COMPONENTS_DIR="$VAULT_DIR/.gemini"
    DISPATCHER_SRC="$DIST_DIR/GEMINI.md"
    DISPATCHER_DST="$VAULT_DIR/GEMINI.md"
    MCP_SRC=""
    MCP_DST=""
    HAS_PLUGINS=0
    ;;
  *)
    die "Unknown platform: $PLATFORM (install layout not defined)"
    ;;
esac
PLATFORM_VAULT_DIR="$VAULT_COMPONENTS_DIR"

# Load opencode-specific helpers when building for opencode
if [[ "$PLATFORM" == "opencode" ]]; then
  # shellcheck source=adapters/opencode/config-merge.sh
  source "$REPO_DIR/adapters/opencode/config-merge.sh"
fi

# ── Migrate legacy manifests (if any) ────────────────────────────────────────
manifest_migrate

# ── Deprecate agents/refs removed from repo (reinstall only) ─────────────────
DEP_COUNT=0
if [[ $EXISTING -eq 1 ]]; then
  DEP_COUNT=$(deprecate_removed "agents"     "$DIST_COMPONENTS_DIR/agents"     "$VAULT_COMPONENTS_DIR/agents")
  DEP_COUNT=$((DEP_COUNT + $(deprecate_removed "references" "$DIST_COMPONENTS_DIR/references" "$VAULT_COMPONENTS_DIR/references")))
fi

# ── Ensure vault support dirs ─────────────────────────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"

# ── Install components ────────────────────────────────────────────────────────
info "Installing agents..."
AGENT_COUNT=$(install_agents "$DIST_COMPONENTS_DIR/agents" "$VAULT_COMPONENTS_DIR/agents")
success "Agents: $AGENT_COUNT installed/updated"

info "Installing references..."
REF_COUNT=$(install_refs "$DIST_COMPONENTS_DIR/references" "$VAULT_COMPONENTS_DIR/references")
success "References: $REF_COUNT installed/updated"

info "Installing skills..."
SKILL_COUNT=$(install_skills "$DIST_COMPONENTS_DIR/skills" "$VAULT_COMPONENTS_DIR/skills")
success "Skills: $SKILL_COUNT installed/updated"

info "Installing hooks..."
HOOK_COUNT=$(install_hooks "$DIST_COMPONENTS_DIR/hooks" "$VAULT_COMPONENTS_DIR/hooks")
success "Hooks: $HOOK_COUNT installed/updated"

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

PLUGIN_COUNT=0
if [[ $HAS_PLUGINS -eq 1 && -d "$DIST_COMPONENTS_DIR/plugins" ]]; then
  info "Installing plugins..."
  PLUGIN_COUNT=$(install_plugins "$DIST_COMPONENTS_DIR/plugins" "$VAULT_COMPONENTS_DIR/plugins")
  success "Plugins: $PLUGIN_COUNT installed/updated"
fi

# settings.json only exists for claude-code (hook config lives in the JS plugin on opencode)
if [[ -f "$DIST_COMPONENTS_DIR/settings.json" ]]; then
  install_settings "$DIST_COMPONENTS_DIR/settings.json" "$VAULT_COMPONENTS_DIR"
fi

install_dispatcher "$DISPATCHER_SRC" "$DISPATCHER_DST"

# ── MCP / opencode.json ───────────────────────────────────────────────────────
if [[ -f "$MCP_SRC" ]]; then
  if [[ "$PLATFORM" == "opencode" && -f "$MCP_DST" ]]; then
    oc_config_merge "$MCP_SRC" "$MCP_DST" "$MCP_DST"
    info "Merged opencode.json (user config preserved)"
  else
    copy_if_changed "$MCP_SRC" "$MCP_DST"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
echo ""
echo -e "   ${VAULT_DIR}/"
FW_DIR_NAME="$(basename "$VAULT_COMPONENTS_DIR")"
DISPATCHER_NAME="$(basename "$DISPATCHER_DST")"
echo -e "   ├── .${FW_DIR_NAME}/"
echo -e "   │   ├── agents/          ${DIM}← agents${NC}"
echo -e "   │   ├── skills/          ${DIM}← skills${NC}"
echo -e "   │   ├── hooks/           ${DIM}← hooks${NC}"
if [[ $HAS_PLUGINS -eq 1 ]]; then
  echo -e "   │   ├── plugins/         ${DIM}← hook plugins${NC}"
else
  echo -e "   │   ├── settings.json    ${DIM}← hooks configuration${NC}"
fi
echo -e "   │   └── references/      ${DIM}← shared docs${NC}"
echo -e "   ├── Meta/"
echo -e "   │   └── scripts/         ${DIM}← ${ORCH_COUNT:-0} orchestra scripts${NC}"
echo -e "   └── ${DISPATCHER_NAME}            ${DIM}← project instructions${NC}"
if [[ "$MCP_ANSWER" =~ ^[Yy]$ ]]; then
  echo -e "   └── .mcp.json            ${DIM}← Gmail + Calendar${NC}"
fi

if [[ $DEP_COUNT -gt 0 ]]; then
  echo ""
  warn "$DEP_COUNT file(s) were deprecated (moved to .${FW_DIR_NAME}/deprecated/)"
fi
echo ""
echo -e "   ${BOLD}Next steps:${NC}"
case "$PLATFORM" in
  claude-code) echo -e "   1. Open Claude Code in your vault folder" ;;
  opencode)    echo -e "   1. Open OpenCode in your vault folder" ;;
  gemini-cli)  echo -e "   1. Open Gemini CLI in your vault folder" ;;
  *)           echo -e "   1. Open your agent platform in your vault folder" ;;
esac
echo -e "   2. Say: ${BOLD}\"Initialize my vault\"${NC}"
echo -e "   3. The Architect will guide you through setup"
echo ""
echo -e "   ${DIM}To update after a git pull: bash scripts/updateme.sh${NC}"
echo ""
