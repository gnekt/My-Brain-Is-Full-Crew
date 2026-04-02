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
echo -e "   ${DIM}Custom agent files in .claude/agents/ will not be deleted or overwritten.${NC}"
echo -e "   ${DIM}Custom agent entries in registry/directory will be preserved during update.${NC}"
echo -e "   ${DIM}Your vault notes are never touched.${NC}"
echo ""
echo -e "   ${BOLD}c)${NC} Continue"
echo -e "   ${BOLD}q)${NC} Quit"
if ! read -r -p "   > " UPDATE_ANSWER 2>/dev/null; then UPDATE_ANSWER=""; fi
if [[ ! "$UPDATE_ANSWER" =~ ^[Cc]$ ]]; then
  echo ""
  info "Update cancelled."
  echo ""
  exit 0
fi
echo ""

# ── Deprecate removed core agents ─────────────────────────────────────────
# Read the OLD manifest first (before rewriting it) so we know which files
# were previously installed as core. Agents removed from the repo will still
# be in the old manifest and can be correctly deprecated.
MANIFEST="$VAULT_DIR/.claude/agents/.core-manifest"
DEPRECATED_COUNT=0
for vault_agent in "$VAULT_DIR/.claude/agents/"*.md; do
  [[ -f "$vault_agent" ]] || continue
  name="$(basename "$vault_agent")"
  # Skip if it still exists in repo
  [[ -f "$REPO_DIR/agents/$name" ]] && continue
  # Skip if already deprecated
  [[ "$name" == *"-DEPRECATED"* ]] && continue
  # Require manifest to distinguish core from custom agents
  if [[ ! -f "$MANIFEST" ]]; then
    continue
  fi
  # Skip custom agents: only deprecate if listed in the manifest
  if ! grep -qxF "$name" "$MANIFEST"; then
    continue
  fi
  deprecated_name="${name%.md}-DEPRECATED.md"
  mkdir -p "$VAULT_DIR/.claude/deprecated"
  # Skip if already deprecated in a previous run
  [[ -f "$VAULT_DIR/.claude/deprecated/$deprecated_name" ]] && continue
  mv "$vault_agent" "$VAULT_DIR/.claude/deprecated/$deprecated_name"
  # Prepend deprecation header
  { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.claude/deprecated/$deprecated_name"; } > "$VAULT_DIR/.claude/deprecated/$deprecated_name.tmp"
  mv "$VAULT_DIR/.claude/deprecated/$deprecated_name.tmp" "$VAULT_DIR/.claude/deprecated/$deprecated_name"
  warn "Deprecated agent: $name -> deprecated/$deprecated_name"
  DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
  # Remove deprecated agent from manifest
  if [[ -f "$MANIFEST" ]]; then
    grep -vxF "$name" "$MANIFEST" > "$MANIFEST.tmp" || true
    mv "$MANIFEST.tmp" "$MANIFEST"
  fi
done

# ── Update agents and rewrite manifest ────────────────────────────────────
AGENT_COUNT=0
: > "$VAULT_DIR/.claude/agents/.core-manifest"
for agent in "$REPO_DIR/agents/"*.md; do
  name="$(basename "$agent")"
  basename "$agent" >> "$VAULT_DIR/.claude/agents/.core-manifest"
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

# ── Deprecate removed references ──────────────────────────────────────────
# Read the old manifest before rewriting, same logic as agents.
REF_MANIFEST="$VAULT_DIR/.claude/references/.core-manifest"
for vault_ref in "$VAULT_DIR/.claude/references/"*.md; do
  [[ -f "$vault_ref" ]] || continue
  name="$(basename "$vault_ref")"
  [[ -f "$REPO_DIR/references/$name" ]] && continue
  [[ "$name" == *"-DEPRECATED"* ]] && continue
  # Require manifest to distinguish core from user-created references
  if [[ ! -f "$REF_MANIFEST" ]]; then
    continue
  fi
  # Skip user-created references: only deprecate if listed in the manifest
  if ! grep -qxF "$name" "$REF_MANIFEST"; then
    continue
  fi
  deprecated_name="${name%.md}-DEPRECATED.md"
  mkdir -p "$VAULT_DIR/.claude/deprecated"
  [[ -f "$VAULT_DIR/.claude/deprecated/$deprecated_name" ]] && continue
  mv "$vault_ref" "$VAULT_DIR/.claude/deprecated/$deprecated_name"
  { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.claude/deprecated/$deprecated_name"; } > "$VAULT_DIR/.claude/deprecated/$deprecated_name.tmp"
  mv "$VAULT_DIR/.claude/deprecated/$deprecated_name.tmp" "$VAULT_DIR/.claude/deprecated/$deprecated_name"
  warn "Deprecated reference: $name -> deprecated/$deprecated_name"
  DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
done

# ── Update references and rewrite manifest ────────────────────────────────
# Files the Architect modifies with user content (custom agent rows/sections).
# These need special merge logic to preserve the "## Custom Agents" section.
USER_MUTABLE_REFS="agents-registry.md agents.md"

# ── Ensure Meta/states/ exists (agent post-its) ─────────────────────────────
mkdir -p "$VAULT_DIR/Meta/states"

REF_COUNT=0
mkdir -p "$VAULT_DIR/.claude/references"
: > "$VAULT_DIR/.claude/references/.core-manifest"
for ref in "$REPO_DIR/references/"*.md; do
  name="$(basename "$ref")"
  basename "$ref" >> "$VAULT_DIR/.claude/references/.core-manifest"
  vault_copy="$VAULT_DIR/.claude/references/$name"

  # For user-mutable files: preserve custom agent content
  if [[ " $USER_MUTABLE_REFS " == *" $name "* ]] && [[ -f "$vault_copy" ]]; then
    # Extract user's custom section (from "## Custom Agents" to end of file)
    custom_section=""
    if grep -qn "^## Custom Agents" "$vault_copy"; then
      custom_line=$(grep -n "^## Custom Agents" "$vault_copy" | head -1 | cut -d: -f1)
      custom_section=$(tail -n +"$custom_line" "$vault_copy")
    fi

    # For agents-registry.md: also extract custom rows from the Registry table
    # Custom rows are table lines whose agent name is NOT a core agent
    custom_table_rows=""
    if [[ "$name" == "agents-registry.md" ]]; then
      CORE_NAMES="architect scribe sorter seeker connector librarian transcriber postman"
      while IFS= read -r row; do
        # Extract agent name from first column: | name | ...
        agent_name=$(echo "$row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        if [[ -n "$agent_name" ]] && ! echo "$CORE_NAMES" | grep -qw "$agent_name"; then
          custom_table_rows="${custom_table_rows}${row}"$'\n'
        fi
      done < <(grep "^|" "$vault_copy" | grep -v "^|[[:space:]]*Name[[:space:]]*|" | grep -v "^|[-[:space:]]*|")
    fi

    # Copy the new repo version
    if ! diff -q "$ref" "$vault_copy" >/dev/null 2>&1; then
      cp "$ref" "$vault_copy"

      # Re-insert custom table rows into the registry table (after the last table row)
      if [[ -n "$custom_table_rows" ]]; then
        # Find the last table row (any line starting with |) — avoids hard-coding a specific agent name
        last_table_line=$(grep -n "^|" "$vault_copy" | tail -1 | cut -d: -f1)
        if [[ -n "$last_table_line" ]]; then
          { head -n "$last_table_line" "$vault_copy"; printf "%s" "$custom_table_rows"; tail -n +"$((last_table_line + 1))" "$vault_copy"; } > "$vault_copy.tmp"
          mv "$vault_copy.tmp" "$vault_copy"
        fi
      fi

      # Re-append preserved custom section (replace the repo's empty custom section)
      if [[ -n "$custom_section" ]]; then
        repo_custom_line=$(grep -n "^## Custom Agents" "$vault_copy" | head -1 | cut -d: -f1)
        if [[ -n "$repo_custom_line" ]]; then
          head -n "$((repo_custom_line - 1))" "$vault_copy" > "$vault_copy.tmp"
          printf '%s\n' "$custom_section" >> "$vault_copy.tmp"
          mv "$vault_copy.tmp" "$vault_copy"
        fi
      fi
      info "Updated reference: $name (preserved custom content)"
      REF_COUNT=$((REF_COUNT + 1))
    fi
    continue
  fi

  if [[ ! -f "$vault_copy" ]] || ! diff -q "$ref" "$vault_copy" >/dev/null 2>&1; then
    cp "$ref" "$vault_copy"
    info "Updated reference: $name"
    REF_COUNT=$((REF_COUNT + 1))
  fi
done

# ── Update skills ────────────────────────────────────────────────────────────
SKILL_COUNT=0
if [[ -d "$REPO_DIR/skills" ]]; then
  for skill_dir in "$REPO_DIR/skills/"*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    dst="$VAULT_DIR/.claude/skills/$skill_name/SKILL.md"
    if [[ ! -f "$dst" ]] || ! diff -q "$src" "$dst" >/dev/null 2>&1; then
      mkdir -p "$VAULT_DIR/.claude/skills/$skill_name"
      cp "$src" "$dst"
      info "Updated skill: $skill_name"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
  done
fi

# ── Update hooks ──────────────────────────────────────────────────────────
HOOK_COUNT=0
if [[ -d "$REPO_DIR/hooks" ]]; then
  mkdir -p "$VAULT_DIR/.claude/hooks"
  for hook in "$REPO_DIR/hooks/"*.sh; do
    [[ -f "$hook" ]] || continue
    name="$(basename "$hook")"
    dst="$VAULT_DIR/.claude/hooks/$name"
    if [[ ! -f "$dst" ]] || ! diff -q "$hook" "$dst" >/dev/null 2>&1; then
      cp "$hook" "$dst"
      chmod +x "$dst"
      info "Updated hook: $name"
      HOOK_COUNT=$((HOOK_COUNT + 1))
    fi
  done
fi

# ── Update settings.json ──────────────────────────────────────────────────
SETTINGS_UPDATED=""
if [[ -f "$REPO_DIR/settings.json" ]]; then
  dst="$VAULT_DIR/.claude/settings.json"
  if [[ ! -f "$dst" ]] || ! diff -q "$REPO_DIR/settings.json" "$dst" >/dev/null 2>&1; then
    mkdir -p "$VAULT_DIR/.claude"
    cp "$REPO_DIR/settings.json" "$dst"
    info "Updated settings.json"
    SETTINGS_UPDATED="1"
  fi
fi

# ── Update CLAUDE.md ──────────────────────────────────────────────────────
CLAUDE_MD_UPDATED=""
if [[ -f "$REPO_DIR/CLAUDE.md" ]]; then
  if [[ ! -f "$VAULT_DIR/CLAUDE.md" ]] || ! diff -q "$REPO_DIR/CLAUDE.md" "$VAULT_DIR/CLAUDE.md" >/dev/null 2>&1; then
    if [[ -f "$VAULT_DIR/CLAUDE.md" ]]; then
      if [[ -f "$VAULT_DIR/CLAUDE_ORIGINAL.md" ]]; then
        CLAUDE_BACKUP="$VAULT_DIR/CLAUDE_ORIGINAL_$(date +%Y%m%d_%H%M%S).md"
      else
        CLAUDE_BACKUP="$VAULT_DIR/CLAUDE_ORIGINAL.md"
      fi
      cp "$VAULT_DIR/CLAUDE.md" "$CLAUDE_BACKUP"
      warn "Existing CLAUDE.md backed up to $(basename "$CLAUDE_BACKUP") — ask Claude to merge your customizations into the new CLAUDE.md"
    fi
    cp "$REPO_DIR/CLAUDE.md" "$VAULT_DIR/CLAUDE.md"
    info "Updated CLAUDE.md"
    CLAUDE_MD_UPDATED="1"
  fi
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
if [[ $AGENT_COUNT -eq 0 && $REF_COUNT -eq 0 && $SKILL_COUNT -eq 0 && $HOOK_COUNT -eq 0 && $DEPRECATED_COUNT -eq 0 && -z "$CLAUDE_MD_UPDATED" && -z "$SETTINGS_UPDATED" ]]; then
  success "Everything is already up to date!"
else
  success "Updated $AGENT_COUNT agent(s), $SKILL_COUNT skill(s), $REF_COUNT reference(s), $HOOK_COUNT hook(s)"
  if [[ $DEPRECATED_COUNT -gt 0 ]]; then
    warn "Deprecated $DEPRECATED_COUNT file(s) no longer in the project"
  fi
fi
echo ""
echo -e "   ${DIM}Restart Claude Code to pick up the changes.${NC}"
echo ""
