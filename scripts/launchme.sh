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
# =============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_paths "${BASH_SOURCE[0]}"

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner "Setup        "
echo -e "   Repo:   ${BOLD}${REPO_DIR}${NC}"
echo -e "   Vault:  ${BOLD}${VAULT_DIR}${NC}"
echo ""

# ── Confirm vault location ────────────────────────────────────────────────────
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

# ── Check for existing installation ──────────────────────────────────────────
EXISTING=0
[[ -d "$VAULT_DIR/.claude" ]] && EXISTING=1
[[ -f "$VAULT_DIR/CLAUDE.md" ]] && EXISTING=1

if [[ $EXISTING -eq 1 ]]; then
  warn "An existing installation was detected:"
  [[ -d "$VAULT_DIR/.claude" ]] && warn "  .claude/ directory exists"
  [[ -f "$VAULT_DIR/CLAUDE.md" ]] && warn "  CLAUDE.md exists"
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

# ── Migrate legacy manifests (if any) ────────────────────────────────────────
manifest_migrate

# ── Deprecate agents/refs removed from repo (reinstall only) ─────────────────
DEP_COUNT=0
if [[ $EXISTING -eq 1 ]]; then
  DEP_COUNT=$(deprecate_removed "agents"     "$REPO_DIR/agents"     "$VAULT_DIR/.claude/agents")
  DEP_COUNT=$((DEP_COUNT + $(deprecate_removed "references" "$REPO_DIR/references" "$VAULT_DIR/.claude/references")))
fi

# ── Ensure vault support dirs ─────────────────────────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"

# ── Install components ────────────────────────────────────────────────────────
info "Installing agents..."
AGENT_COUNT=$(install_agents "$REPO_DIR/agents" "$VAULT_DIR/.claude/agents")
success "Agents: $AGENT_COUNT installed/updated"

info "Installing references..."
REF_COUNT=$(install_refs "$REPO_DIR/references" "$VAULT_DIR/.claude/references")
success "References: $REF_COUNT installed/updated"

info "Installing skills..."
SKILL_COUNT=$(install_skills "$REPO_DIR/skills" "$VAULT_DIR/.claude/skills")
success "Skills: $SKILL_COUNT installed/updated"

info "Installing hooks..."
HOOK_COUNT=$(install_hooks "$REPO_DIR/hooks" "$VAULT_DIR/.claude/hooks")
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

# ── Copy CLAUDE.md ───────────────────────────────────────────────────────────
if [[ -f "$REPO_DIR/CLAUDE.md" ]]; then
  cp "$REPO_DIR/CLAUDE.md" "$VAULT_DIR/CLAUDE.md"
  success "Copied CLAUDE.md"
fi


install_settings "$REPO_DIR/settings.json" "$VAULT_DIR/.claude"
install_claude_md "$REPO_DIR/CLAUDE.md" "$VAULT_DIR"

# ── MCP servers (Gmail + Calendar) ───────────────────────────────────────────
echo ""
echo -e "${BOLD}Do you use Gmail, Hey.com, or Google Calendar?${NC}"
echo -e "   ${DIM}The Postman agent can read your inbox and calendar.${NC}"
echo -e "   ${DIM}Gmail uses MCP connectors (read-only). For full access, set up GWS CLI later.${NC}"
echo -e "   ${DIM}Hey.com uses the Hey CLI (install from https://github.com/basecamp/hey-cli).${NC}"
echo -e "   ${DIM}You can always add this later.${NC}"
echo ""
echo -e "   ${BOLD}y)${NC} Yes, set up Gmail + Calendar (MCP connectors)"
echo -e "   ${BOLD}n)${NC} No, skip for now"
if ! read -r -p "   > " MCP_ANSWER 2>/dev/null; then MCP_ANSWER=""; fi

if [[ "$MCP_ANSWER" =~ ^[Yy]$ ]]; then
  if [[ -f "$VAULT_DIR/.mcp.json" ]]; then
    warn ".mcp.json already exists — skipping (won't overwrite)"
  else
    cp "$REPO_DIR/.mcp.json" "$VAULT_DIR/.mcp.json"
    success "Created .mcp.json (Gmail + Google Calendar)"
  fi
else
  info "Skipped MCP setup"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
echo ""
echo -e "   ${VAULT_DIR}/"
echo -e "   ├── .claude/"
echo -e "   │   ├── agents/          ${DIM}← agents${NC}"
echo -e "   │   ├── skills/          ${DIM}← skills${NC}"
echo -e "   │   ├── hooks/           ${DIM}← hooks${NC}"
echo -e "   │   ├── settings.json    ${DIM}← hooks configuration${NC}"
echo -e "   │   └── references/      ${DIM}← shared docs${NC}"
echo -e "   ├── Meta/"
echo -e "   │   └── scripts/         ${DIM}← ${ORCH_COUNT:-0} orchestra scripts${NC}"
echo -e "   ├── CLAUDE.md            ${DIM}← project instructions${NC}"
if [[ "$MCP_ANSWER" =~ ^[Yy]$ ]]; then
  echo -e "   └── .mcp.json            ${DIM}← Gmail + Calendar${NC}"
fi
if [[ $DEP_COUNT -gt 0 ]]; then
  echo ""
  warn "$DEP_COUNT file(s) were deprecated (moved to .claude/deprecated/)"
fi
echo ""
echo -e "   ${BOLD}Next steps:${NC}"
echo -e "   1. Open Claude Code in your vault folder"
echo -e "   2. Say: ${BOLD}\"Initialize my vault\"${NC}"
echo -e "   3. The Architect will guide you through setup"
echo ""
echo -e "   ${DIM}To update after a git pull: bash scripts/updateme.sh${NC}"
echo ""
