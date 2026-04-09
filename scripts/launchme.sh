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
if ! read -r -p "   > " CONFIRM 2>/dev/null; then CONFIRM=""; fi

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo ""
  echo -e "${BOLD}Enter the full path to your Obsidian vault:${NC}"
  if ! read -r -p "   > " VAULT_DIR 2>/dev/null; then die "Cannot read input — are you running in a non-interactive shell?"; fi
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
  if ! read -r -p "   > " OVERWRITE_ANSWER 2>/dev/null; then OVERWRITE_ANSWER=""; fi
  if [[ ! "$OVERWRITE_ANSWER" =~ ^[Cc]$ ]]; then
    echo ""
    info "Installation cancelled."
    echo ""
    exit 0
  fi
fi

# ── Deprecate stale core agents on reinstall ─────────────────────────────
echo ""
mkdir -p "$VAULT_DIR/.claude/agents"
OLD_MANIFEST="$VAULT_DIR/.claude/agents/.core-manifest"
if [[ $EXISTING -eq 1 && -f "$OLD_MANIFEST" ]]; then
  while IFS= read -r old_name; do
    [[ -z "$old_name" ]] && continue
    [[ -f "$REPO_DIR/agents/$old_name" ]] && continue
    vault_file="$VAULT_DIR/.claude/agents/$old_name"
    [[ -f "$vault_file" ]] || continue
    deprecated_name="${old_name%.md}-DEPRECATED.md"
    mkdir -p "$VAULT_DIR/.claude/deprecated"
    [[ -f "$VAULT_DIR/.claude/deprecated/$deprecated_name" ]] && continue
    mv "$vault_file" "$VAULT_DIR/.claude/deprecated/$deprecated_name"
    { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.claude/deprecated/$deprecated_name"; } > "$VAULT_DIR/.claude/deprecated/$deprecated_name.tmp"
    mv "$VAULT_DIR/.claude/deprecated/$deprecated_name.tmp" "$VAULT_DIR/.claude/deprecated/$deprecated_name"
    warn "Deprecated stale agent: $old_name -> deprecated/$deprecated_name"
  done < "$OLD_MANIFEST"
fi

# ── Copy agents ─────────────────────────────────────────────────────────────
info "Creating .claude/agents/ in vault..."

AGENT_COUNT=0
: > "$VAULT_DIR/.claude/agents/.core-manifest"
for agent in "$REPO_DIR/agents/"*.md; do
  cp "$agent" "$VAULT_DIR/.claude/agents/"
  basename "$agent" >> "$VAULT_DIR/.claude/agents/.core-manifest"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done
success "Copied $AGENT_COUNT agents"

# ── Create Meta/states/ for agent post-its ──────────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"
info "Created Meta/states/ (agent post-it directory)"

# ── Copy references ─────────────────────────────────────────────────────────
info "Creating .claude/references/ in vault..."
mkdir -p "$VAULT_DIR/.claude/references"
# User-mutable references (modified by Architect when creating custom agents)
USER_MUTABLE_REFS="agents-registry.md agents.md"

: > "$VAULT_DIR/.claude/references/.core-manifest"
for ref in "$REPO_DIR/references/"*.md; do
  ref_name="$(basename "$ref")"
  # On reinstall, preserve user-mutable reference files
  if [[ $EXISTING -eq 1 && -f "$VAULT_DIR/.claude/references/$ref_name" ]]; then
    if [[ " $USER_MUTABLE_REFS " == *" $ref_name "* ]]; then
      warn "Preserving existing $ref_name (run updateme.sh to merge upstream changes)"
      echo "$ref_name" >> "$VAULT_DIR/.claude/references/.core-manifest"
      continue
    fi
  fi
  cp "$ref" "$VAULT_DIR/.claude/references/"
  echo "$ref_name" >> "$VAULT_DIR/.claude/references/.core-manifest"
done
success "Copied references"

# ── Copy skills ──────────────────────────────────────────────────────────────
SKILL_COUNT=0
if [[ -d "$REPO_DIR/skills" ]]; then
  for skill_dir in "$REPO_DIR/skills/"*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$VAULT_DIR/.claude/skills/$skill_name"
    cp "$skill_dir"SKILL.md "$VAULT_DIR/.claude/skills/$skill_name/"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  done
  success "Copied $SKILL_COUNT skills"
fi

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

# ── Copy hooks ───────────────────────────────────────────────────────────────
HOOK_COUNT=0
if [[ -d "$REPO_DIR/hooks" ]]; then
  mkdir -p "$VAULT_DIR/.claude/hooks"
  for hook in "$REPO_DIR/hooks/"*.sh; do
    [[ -f "$hook" ]] || continue
    cp "$hook" "$VAULT_DIR/.claude/hooks/"
    chmod +x "$VAULT_DIR/.claude/hooks/$(basename "$hook")"
    HOOK_COUNT=$((HOOK_COUNT + 1))
  done
  success "Copied $HOOK_COUNT hooks"
fi

# ── Copy settings.json ───────────────────────────────────────────────────────
if [[ -f "$REPO_DIR/settings.json" ]]; then
  if [[ -f "$VAULT_DIR/.claude/settings.json" ]]; then
    warn ".claude/settings.json already exists — skipping (won't overwrite)"
  else
    mkdir -p "$VAULT_DIR/.claude"
    cp "$REPO_DIR/settings.json" "$VAULT_DIR/.claude/settings.json"
    success "Copied settings.json (hooks configuration)"
  fi
fi

# ── MCP servers (Gmail + Calendar) ──────────────────────────────────────────
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
echo -e "   │   ├── hooks/           ${DIM}← ${HOOK_COUNT:-0} hooks${NC}"
echo -e "   │   ├── settings.json    ${DIM}← hooks configuration${NC}"
echo -e "   │   └── references/      ${DIM}← shared docs${NC}"
echo -e "   ├── Meta/"
echo -e "   │   └── scripts/         ${DIM}← ${ORCH_COUNT:-0} orchestra scripts${NC}"
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
