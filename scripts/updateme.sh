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
# =============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_paths "${BASH_SOURCE[0]}"

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner "Update       "

# ── Check vault has been set up ───────────────────────────────────────────────
[[ -d "$VAULT_DIR/.claude/agents" ]] \
  || die "No .claude/agents/ found in $VAULT_DIR — run launchme.sh first"

# ── Confirm ───────────────────────────────────────────────────────────────────
echo -e "${BOLD}This will update core agents, skills, references, hooks, and CLAUDE.md.${NC}"
echo -e "   ${DIM}Custom agents in .claude/agents/ are never overwritten or deleted.${NC}"
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

# ── Migrate legacy manifests (if any) ────────────────────────────────────────
manifest_migrate

# ── Deprecate agents/refs removed from repo ──────────────────────────────────
DEP_COUNT=$(deprecate_removed "agents"     "$REPO_DIR/agents"     "$VAULT_DIR/.claude/agents")
DEP_COUNT=$((DEP_COUNT + $(deprecate_removed "references" "$REPO_DIR/references" "$VAULT_DIR/.claude/references")))

# ── Ensure vault support dirs ─────────────────────────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"

# ── Update components (per-file logging enabled) ─────────────────────────────
VERBOSE_COPY=1

AGENT_COUNT=$(install_agents "$REPO_DIR/agents"     "$VAULT_DIR/.claude/agents")
REF_COUNT=$(install_refs     "$REPO_DIR/references" "$VAULT_DIR/.claude/references")
SKILL_COUNT=$(install_skills "$REPO_DIR/skills"     "$VAULT_DIR/.claude/skills")
HOOK_COUNT=$(install_hooks   "$REPO_DIR/hooks"      "$VAULT_DIR/.claude/hooks")

install_settings  "$REPO_DIR/settings.json" "$VAULT_DIR/.claude"
SETTINGS_CHANGED=$_LAST_CHANGED

install_claude_md "$REPO_DIR/CLAUDE.md" "$VAULT_DIR"
CLAUDE_MD_CHANGED=$_LAST_CHANGED

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
TOTAL=$((AGENT_COUNT + REF_COUNT + SKILL_COUNT + HOOK_COUNT + SETTINGS_CHANGED + CLAUDE_MD_CHANGED))
if [[ $TOTAL -eq 0 && $DEP_COUNT -eq 0 ]]; then
  success "Everything is already up to date!"
else
  success "Updated $AGENT_COUNT agent(s), $SKILL_COUNT skill(s), $REF_COUNT reference(s), $HOOK_COUNT hook(s)"
  [[ $SETTINGS_CHANGED -eq 1 ]] && info "settings.json updated (backup saved as settings.json.bak)"
  [[ $CLAUDE_MD_CHANGED -eq 1 ]] && info "CLAUDE.md updated"
  [[ $DEP_COUNT -gt 0 ]] && warn "$DEP_COUNT file(s) deprecated (moved to .claude/deprecated/)"
fi
echo ""
echo -e "   ${DIM}Restart Claude Code to pick up the changes.${NC}"
echo ""
