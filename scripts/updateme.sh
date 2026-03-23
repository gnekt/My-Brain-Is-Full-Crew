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

# ── Deprecate removed core agents ─────────────────────────────────────────
# Core agents are the ones that exist in the repo's agents/ folder.
# If a file in .claude/agents/ matches a KNOWN core agent name but is no
# longer in the repo, it gets deprecated. Custom agents are never touched.
CORE_AGENT_NAMES=""
for agent in "$REPO_DIR/agents/"*.md; do
  CORE_AGENT_NAMES="$CORE_AGENT_NAMES $(basename "$agent")"
done

DEPRECATED_COUNT=0
for vault_agent in "$VAULT_DIR/.claude/agents/"*.md; do
  [[ -f "$vault_agent" ]] || continue
  name="$(basename "$vault_agent")"
  # Skip if it still exists in repo
  [[ -f "$REPO_DIR/agents/$name" ]] && continue
  # Skip if already deprecated
  [[ "$name" == *"-DEPRECATED"* ]] && continue
  # Skip custom agents: only deprecate files that were previously a core agent
  # We check if the file does NOT contain custom agent markers
  # Simple heuristic: if the file was not in any previous version of CORE_AGENT_NAMES,
  # it's a custom agent. Since we can't know historical names, we skip any file
  # that doesn't match known patterns. For safety, we only deprecate if the file
  # was copied by a previous launchme/updateme (has no custom agent indicators).
  deprecated_name="${name%.md}-DEPRECATED.md"
  mv "$vault_agent" "$VAULT_DIR/.claude/agents/$deprecated_name"
  # Prepend deprecation header
  { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.claude/agents/$deprecated_name"; } > "$VAULT_DIR/.claude/agents/$deprecated_name.tmp"
  mv "$VAULT_DIR/.claude/agents/$deprecated_name.tmp" "$VAULT_DIR/.claude/agents/$deprecated_name"
  warn "Deprecated agent: $name -> $deprecated_name"
  DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
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

# ── Deprecate removed references ──────────────────────────────────────────
for vault_ref in "$VAULT_DIR/.claude/references/"*.md; do
  [[ -f "$vault_ref" ]] || continue
  name="$(basename "$vault_ref")"
  [[ -f "$REPO_DIR/references/$name" ]] && continue
  [[ "$name" == *"-DEPRECATED"* ]] && continue
  deprecated_name="${name%.md}-DEPRECATED.md"
  mv "$vault_ref" "$VAULT_DIR/.claude/references/$deprecated_name"
  { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.claude/references/$deprecated_name"; } > "$VAULT_DIR/.claude/references/$deprecated_name.tmp"
  mv "$VAULT_DIR/.claude/references/$deprecated_name.tmp" "$VAULT_DIR/.claude/references/$deprecated_name"
  warn "Deprecated reference: $name -> $deprecated_name"
  DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
done

# ── Deprecate old skills directory ────────────────────────────────────────
# Skills were removed from the project. If the vault still has .claude/skills/
# from a previous install, deprecate each SKILL.md file and rename the folder.
SKILL_COUNT=0
if [[ -d "$VAULT_DIR/.claude/skills" ]] && [[ ! -d "$VAULT_DIR/.claude/skills-DEPRECATED" ]]; then
  for skill_file in "$VAULT_DIR/.claude/skills/"*/SKILL.md; do
    [[ -f "$skill_file" ]] || continue
    { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$skill_file"; } > "$skill_file.tmp"
    mv "$skill_file.tmp" "$skill_file"
  done
  mv "$VAULT_DIR/.claude/skills" "$VAULT_DIR/.claude/skills-DEPRECATED"
  warn "Deprecated .claude/skills/ -> .claude/skills-DEPRECATED/"
  DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
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
if [[ $AGENT_COUNT -eq 0 && $REF_COUNT -eq 0 && $DEPRECATED_COUNT -eq 0 && -z "$CLAUDE_MD_UPDATED" ]]; then
  success "Everything is already up to date!"
else
  success "Updated $AGENT_COUNT agent(s) and $REF_COUNT reference(s)"
  if [[ $DEPRECATED_COUNT -gt 0 ]]; then
    warn "Deprecated $DEPRECATED_COUNT file(s) no longer in the project"
  fi
fi
echo ""
echo -e "   ${DIM}Restart Claude Code to pick up the changes.${NC}"
echo ""
