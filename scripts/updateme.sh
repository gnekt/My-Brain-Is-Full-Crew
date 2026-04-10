#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Updater
# =============================================================================
# After pulling new changes from the repo, run this to update the crew:
#
#   cd /path/to/your-vault/My-Brain-Is-Full-Crew
#   git pull
#   bash scripts/updateme.sh
#
# Options:
#   --platform <name>    Platform to build for (default: claude-code)
#   --target <path>      Override the vault destination path
# =============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_paths "${BASH_SOURCE[0]}"

# ── Parse args ─────────────────────────────────────────────────────────────
PLATFORM="claude-code"
TARGET_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --target)    TARGET_OVERRIDE="$2"; shift 2 ;;
    *) die "Unknown argument: $1" ;;
  esac
done
[[ -n "$TARGET_OVERRIDE" ]] && VAULT_DIR="$TARGET_OVERRIDE"

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner "Update       "

# ── Check vault has been set up ───────────────────────────────────────────────
case "$PLATFORM" in
  claude-code) _SETUP_CHECK="$VAULT_DIR/.claude/agents" ;;
  opencode)    _SETUP_CHECK="$VAULT_DIR/.opencode/agents" ;;
  gemini-cli)  _SETUP_CHECK="$VAULT_DIR/.gemini/agents" ;;
  *)           _SETUP_CHECK="$VAULT_DIR/.claude/agents" ;;
esac
[[ -d "$_SETUP_CHECK" ]] \
  || die "No agents/ found in $VAULT_DIR for platform '$PLATFORM' — run launchme.sh first"

# ── Confirm ───────────────────────────────────────────────────────────────────
case "$PLATFORM" in
  opencode)    _DISP_NAME="AGENTS.md"; _FW_DIR_NAME="opencode" ;;
  gemini-cli)  _DISP_NAME="GEMINI.md"; _FW_DIR_NAME="gemini" ;;
  *)           _DISP_NAME="CLAUDE.md"; _FW_DIR_NAME="claude" ;;
esac
echo -e "${BOLD}This will update core agents, skills, references, hooks, and ${_DISP_NAME}.${NC}"
echo -e "   ${DIM}Custom agents in .${_FW_DIR_NAME}/agents/ are never overwritten or deleted.${NC}"
echo -e "   ${DIM}Custom content between MBIFC markers in references is preserved.${NC}"
echo -e "   ${DIM}Your vault notes are never touched.${NC}"
echo ""
echo -e "   ${BOLD}c)${NC} Continue"
echo -e "   ${BOLD}q)${NC} Quit"
if ! read -r -p "   > " ANSWER 2>/dev/null; then ANSWER=""; fi
if [[ ! "$ANSWER" =~ ^[Cc]$ ]]; then
  echo ""; info "Update cancelled."; echo ""; exit 0
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

# ── Deprecate agents/refs removed from repo ──────────────────────────────────
DEP_COUNT=$(deprecate_removed "agents"     "$DIST_COMPONENTS_DIR/agents"     "$VAULT_COMPONENTS_DIR/agents")
DEP_COUNT=$((DEP_COUNT + $(deprecate_removed "references" "$DIST_COMPONENTS_DIR/references" "$VAULT_COMPONENTS_DIR/references")))

# ── Ensure vault support dirs ─────────────────────────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"

# ── Update components (per-file logging enabled) ─────────────────────────────
VERBOSE_COPY=1

AGENT_COUNT=$(install_agents "$DIST_COMPONENTS_DIR/agents" "$VAULT_COMPONENTS_DIR/agents")
REF_COUNT=$(install_refs     "$DIST_COMPONENTS_DIR/references" "$VAULT_COMPONENTS_DIR/references")
SKILL_COUNT=$(install_skills "$DIST_COMPONENTS_DIR/skills" "$VAULT_COMPONENTS_DIR/skills")
HOOK_COUNT=$(install_hooks   "$DIST_COMPONENTS_DIR/hooks"  "$VAULT_COMPONENTS_DIR/hooks")

PLUGIN_COUNT=0
if [[ $HAS_PLUGINS -eq 1 && -d "$DIST_COMPONENTS_DIR/plugins" ]]; then
  info "Installing plugins..."
  PLUGIN_COUNT=$(install_plugins "$DIST_COMPONENTS_DIR/plugins" "$VAULT_COMPONENTS_DIR/plugins")
  success "Plugins: $PLUGIN_COUNT installed/updated"
fi

SETTINGS_CHANGED=0
if [[ -f "$DIST_COMPONENTS_DIR/settings.json" ]]; then
  install_settings "$DIST_COMPONENTS_DIR/settings.json" "$VAULT_COMPONENTS_DIR"
  SETTINGS_CHANGED=$_LAST_CHANGED
fi

install_dispatcher "$DISPATCHER_SRC" "$DISPATCHER_DST"
CLAUDE_MD_CHANGED=$_LAST_CHANGED

# ── MCP / opencode.json ───────────────────────────────────────────────────────
if [[ -f "$MCP_SRC" ]]; then
  if [[ "$PLATFORM" == "opencode" && -f "$MCP_DST" ]]; then
    oc_config_merge "$MCP_SRC" "$MCP_DST" "$MCP_DST"
    info "Merged opencode.json (user config preserved)"
  else
    copy_if_changed "$MCP_SRC" "$MCP_DST"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
TOTAL=$((AGENT_COUNT + REF_COUNT + SKILL_COUNT + HOOK_COUNT + PLUGIN_COUNT + SETTINGS_CHANGED + CLAUDE_MD_CHANGED))
if [[ $TOTAL -eq 0 && $DEP_COUNT -eq 0 ]]; then
  success "Everything is already up to date!"
else
  success "Updated $AGENT_COUNT agent(s), $SKILL_COUNT skill(s), $REF_COUNT reference(s), $HOOK_COUNT hook(s)${PLUGIN_COUNT:+, $PLUGIN_COUNT plugin(s)}"
  [[ $SETTINGS_CHANGED -eq 1 ]] && info "settings.json updated (backup saved as settings.json.bak)"
  [[ $CLAUDE_MD_CHANGED -eq 1 ]] && info "Dispatcher file updated"
  [[ $DEP_COUNT -gt 0 ]] && warn "$DEP_COUNT file(s) deprecated (moved to deprecated/)"
fi
echo ""
echo -e "   ${DIM}Restart $PLATFORM to pick up the changes.${NC}"
echo ""
