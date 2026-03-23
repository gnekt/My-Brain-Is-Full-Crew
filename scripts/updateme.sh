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

[[ -d "$REPO_DIR/agents" ]] || die "Can't find agents/ — are you running this from the repo?"

# ── Check vault has been set up ─────────────────────────────────────────────
if [[ ! -d "$VAULT_DIR/.claude/agents" ]]; then
  die "No .claude/agents/ found in $VAULT_DIR — run launchme.sh first"
fi

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  My Brain Is Full - Crew :: Update       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Confirm overwrite ────────────────────────────────────────────────────
echo -e "${BOLD}This will overwrite core agent files, references, and CLAUDE.md.${NC}"
echo -e "   ${DIM}Custom agents in .claude/agents/ will NOT be touched.${NC}"
echo -e "   ${DIM}Your vault notes are never touched.${NC}"
echo ""
echo -e "   ${BOLD}c)${NC} Continue"
echo -e "   ${BOLD}q)${NC} Quit"
read -r -p "   > " UPDATE_ANSWER
if [[ ! "$UPDATE_ANSWER" =~ ^[Cc]$ ]]; then
  echo ""
  info "Update cancelled."
  echo ""
  exit 0
fi
echo ""

# ── Update agents ───────────────────────────────────────────────────────────
AGENT_COUNT=0
for agent in "$REPO_DIR/agents/"*.md; do
  name="$(basename "$agent")"
  if [[ -f "$VAULT_DIR/.claude/agents/$name" ]]; then
    if ! diff -q "$agent" "$VAULT_DIR/.claude/agents/$name" >/dev/null 2>&1; then
      cp "$agent" "$VAULT_DIR/.claude/agents/"
      info "Updated $name"
      AGENT_COUNT=$((AGENT_COUNT + 1))
    fi
  else
    cp "$agent" "$VAULT_DIR/.claude/agents/"
    info "Added $name (new agent)"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  fi
done

# ── Update references ───────────────────────────────────────────────────────
REF_COUNT=0
mkdir -p "$VAULT_DIR/.claude/references"
for ref in "$REPO_DIR/references/"*.md; do
  name="$(basename "$ref")"
  if ! diff -q "$ref" "$VAULT_DIR/.claude/references/$name" >/dev/null 2>&1; then
    cp "$ref" "$VAULT_DIR/.claude/references/"
    info "Updated reference: $name"
    REF_COUNT=$((REF_COUNT + 1))
  fi
done

# ── Regenerate and update skills ───────────────────────────────────────────
SKILL_COUNT=0
if command -v python3 >/dev/null 2>&1 && [[ -f "$REPO_DIR/scripts/generate-skills.py" ]]; then
  python3 "$REPO_DIR/scripts/generate-skills.py" >/dev/null 2>&1
fi

if [[ -d "$REPO_DIR/skills" ]]; then
  for skill_dir in "$REPO_DIR/skills/"*/; do
    skill_name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    dst="$VAULT_DIR/.claude/skills/$skill_name/SKILL.md"
    if [[ -f "$src" ]]; then
      if [[ ! -f "$dst" ]] || ! diff -q "$src" "$dst" >/dev/null 2>&1; then
        mkdir -p "$VAULT_DIR/.claude/skills/$skill_name"
        cp "$src" "$dst"
        info "Updated skill: $skill_name"
        SKILL_COUNT=$((SKILL_COUNT + 1))
      fi
    fi
  done
fi

# ── Update CLAUDE.md ──────────────────────────────────────────────────────
CLAUDE_MD_UPDATED=""
if [[ -f "$REPO_DIR/CLAUDE.md" ]]; then
  if [[ ! -f "$VAULT_DIR/CLAUDE.md" ]] || ! diff -q "$REPO_DIR/CLAUDE.md" "$VAULT_DIR/CLAUDE.md" >/dev/null 2>&1; then
    cp "$REPO_DIR/CLAUDE.md" "$VAULT_DIR/CLAUDE.md"
    info "Updated CLAUDE.md"
    CLAUDE_MD_UPDATED="1"
  fi
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
if [[ $AGENT_COUNT -eq 0 && $REF_COUNT -eq 0 && $SKILL_COUNT -eq 0 && -z "$CLAUDE_MD_UPDATED" ]]; then
  success "Everything is already up to date!"
else
  success "Updated $AGENT_COUNT agent(s), $SKILL_COUNT skill(s), and $REF_COUNT reference(s)"
fi
echo ""
echo -e "   ${DIM}Restart Claude Code to pick up the changes.${NC}"
echo ""
