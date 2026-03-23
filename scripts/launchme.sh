#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Installer
# =============================================================================
# Run this from inside the cloned repo, which should be inside your vault:
#
#   cd /path/to/your-vault/My-Brain-Is-Full-Crew
#   bash scripts/launchme.sh
#
# It copies agents and references into your vault's .claude/ directory.
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

# ── Find paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_DIR="$(cd "$REPO_DIR/.." && pwd)"

# Sanity checks
[[ -d "$REPO_DIR/agents" ]] || die "Can't find agents/ in $REPO_DIR — are you running this from the repo?"
[[ -d "$REPO_DIR/references" ]] || die "Can't find references/ in $REPO_DIR"

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  My Brain Is Full - Crew :: Setup        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "   Repo:   ${BOLD}${REPO_DIR}${NC}"
echo -e "   Vault:  ${BOLD}${VAULT_DIR}${NC}"
echo ""

# ── Confirm vault location ─────────────────────────────────────────────────
echo -e "${BOLD}Is this your Obsidian vault folder?${NC}"
echo -e "   ${DIM}${VAULT_DIR}${NC}"
echo ""
echo -e "   ${BOLD}y)${NC} Yes, install here"
echo -e "   ${BOLD}n)${NC} No, let me type the correct path"
read -r -p "   > " CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo ""
  echo -e "${BOLD}Enter the full path to your Obsidian vault:${NC}"
  read -r -p "   > " VAULT_DIR
  VAULT_DIR="${VAULT_DIR/#\~/$HOME}"
  [[ -d "$VAULT_DIR" ]] || die "Directory not found: $VAULT_DIR"
fi

# ── Check for existing installation ───────────────────────────────────────
echo ""
EXISTING=0
if [[ -d "$VAULT_DIR/.claude" ]]; then EXISTING=1; fi
if [[ -f "$VAULT_DIR/CLAUDE.md" ]]; then EXISTING=1; fi

if [[ $EXISTING -eq 1 ]]; then
  warn "An existing installation was detected:"
  [[ -d "$VAULT_DIR/.claude" ]] && warn "  .claude/ directory exists"
  [[ -f "$VAULT_DIR/CLAUDE.md" ]] && warn "  CLAUDE.md exists"
  echo ""
  echo -e "   ${BOLD}The installer needs to overwrite these files.${NC}"
  echo -e "   ${DIM}Custom agents in .claude/agents/ will NOT be deleted.${NC}"
  echo -e "   ${DIM}Your vault notes are never touched.${NC}"
  echo ""
  echo -e "   ${BOLD}c)${NC} Continue (overwrite core files, keep custom agents)"
  echo -e "   ${BOLD}q)${NC} Quit"
  read -r -p "   > " OVERWRITE_ANSWER
  if [[ ! "$OVERWRITE_ANSWER" =~ ^[Cc]$ ]]; then
    echo ""
    info "Installation cancelled."
    echo ""
    exit 0
  fi
fi

# ── Copy agents ─────────────────────────────────────────────────────────────
echo ""
info "Creating .claude/agents/ in vault..."
mkdir -p "$VAULT_DIR/.claude/agents"

AGENT_COUNT=0
for agent in "$REPO_DIR/agents/"*.md; do
  cp "$agent" "$VAULT_DIR/.claude/agents/"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done
success "Copied $AGENT_COUNT agents"

# ── Copy references ─────────────────────────────────────────────────────────
info "Creating .claude/references/ in vault..."
mkdir -p "$VAULT_DIR/.claude/references"
cp "$REPO_DIR/references/"*.md "$VAULT_DIR/.claude/references/"
success "Copied references"

# ── Generate and copy skills ──────────────────────────────────────────────────
SKILL_COUNT=0
if command -v python3 >/dev/null 2>&1 && [[ -f "$REPO_DIR/scripts/generate-skills.py" ]]; then
  info "Generating skills from agents..."
  python3 "$REPO_DIR/scripts/generate-skills.py" >/dev/null 2>&1
fi

if [[ -d "$REPO_DIR/skills" ]]; then
  info "Creating .claude/skills/ in vault..."
  for skill_dir in "$REPO_DIR/skills/"*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$VAULT_DIR/.claude/skills/$skill_name"
    cp "$skill_dir"* "$VAULT_DIR/.claude/skills/$skill_name/" 2>/dev/null || true
    SKILL_COUNT=$((SKILL_COUNT + 1))
  done
  success "Copied $SKILL_COUNT skills"
fi

# ── Copy CLAUDE.md ───────────────────────────────────────────────────────────
if [[ -f "$REPO_DIR/CLAUDE.md" ]]; then
  cp "$REPO_DIR/CLAUDE.md" "$VAULT_DIR/CLAUDE.md"
  success "Copied CLAUDE.md"
fi

# ── MCP servers (Gmail + Calendar) ──────────────────────────────────────────
echo ""
echo -e "${BOLD}Do you use Gmail or Google Calendar?${NC}"
echo -e "   ${DIM}The Postman agent can read your inbox and calendar.${NC}"
echo -e "   ${DIM}You can always add this later.${NC}"
echo ""
echo -e "   ${BOLD}y)${NC} Yes, set up Gmail + Calendar"
echo -e "   ${BOLD}n)${NC} No, skip for now"
read -r -p "   > " MCP_ANSWER

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

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
echo ""
echo -e "   Your vault is ready. Here's what was installed:"
echo ""
echo -e "   ${VAULT_DIR}/"
echo -e "   ├── .claude/"
echo -e "   │   ├── agents/          ${DIM}← ${AGENT_COUNT} crew agents${NC}"
echo -e "   │   ├── skills/          ${DIM}← ${SKILL_COUNT:-0} crew skills (Desktop/Cowork)${NC}"
echo -e "   │   └── references/      ${DIM}← shared docs${NC}"
echo -e "   ├── CLAUDE.md            ${DIM}← project instructions${NC}"
if [[ "$MCP_ANSWER" =~ ^[Yy]$ ]]; then
echo -e "   └── .mcp.json            ${DIM}← Gmail + Calendar${NC}"
fi
echo ""
echo -e "   ${BOLD}Next steps:${NC}"
echo -e "   1. Open Claude Code in your vault folder"
echo -e "   2. Say: ${BOLD}\"Initialize my vault\"${NC}"
echo -e "   3. The Architect will guide you through setup"
echo ""
echo -e "   ${DIM}To update after a git pull: bash scripts/updateme.sh${NC}"
echo ""
