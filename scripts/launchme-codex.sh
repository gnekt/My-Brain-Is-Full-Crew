#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Codex Installer
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_DIR="$(cd "$REPO_DIR/.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_DIR/scripts/lib/codex-transform.sh"

info()    { echo "[INFO] $*"; }
success() { echo "[OK]   $*"; }
warn()    { echo "[WARN] $*"; }
die()     { echo "[ERR]  $*" >&2; exit 1; }

[[ -d "$REPO_DIR/agents" ]] || die "Missing agents/ in repository"
[[ -d "$REPO_DIR/references" ]] || die "Missing references/ in repository"
[[ -f "$REPO_DIR/AGENTS.md" ]] || die "Missing AGENTS.md in repository"

echo "Codex installer"
echo "Repo:  $REPO_DIR"
echo "Vault: $VAULT_DIR"

read -r -p "Install to this vault path? [Y/n]: " CONFIRM || true
if [[ "${CONFIRM:-y}" =~ ^[Nn]$ ]]; then
  read -r -p "Enter full vault path: " VAULT_DIR || die "Unable to read vault path"
  [[ -d "$VAULT_DIR" ]] || die "Directory not found: $VAULT_DIR"
fi

EXISTING=0
[[ -d "$VAULT_DIR/.codex" ]] && EXISTING=1

if [[ $EXISTING -eq 1 ]]; then
  warn "Existing .codex installation found."
  read -r -p "Continue and overwrite core Codex files? [c/q]: " OVERWRITE_ANSWER || true
  [[ "${OVERWRITE_ANSWER:-q}" =~ ^[Cc]$ ]] || { info "Installation cancelled"; exit 0; }
fi

mkdir -p "$VAULT_DIR/.codex/agents" "$VAULT_DIR/.codex/references" "$VAULT_DIR/.codex/skills"

# Deprecate removed core agents using old manifest
OLD_MANIFEST="$VAULT_DIR/.codex/agents/.core-manifest"
if [[ -f "$OLD_MANIFEST" ]]; then
  while IFS= read -r old_name; do
    [[ -z "$old_name" ]] && continue
    [[ -f "$REPO_DIR/agents/$old_name" ]] && continue
    dst="$VAULT_DIR/.codex/agents/$old_name"
    [[ -f "$dst" ]] || continue
    mkdir -p "$VAULT_DIR/.codex/deprecated"
    deprecated_name="${old_name%.md}-DEPRECATED.md"
    [[ -f "$VAULT_DIR/.codex/deprecated/$deprecated_name" ]] && continue
    mv "$dst" "$VAULT_DIR/.codex/deprecated/$deprecated_name"
    { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.codex/deprecated/$deprecated_name"; } > "$VAULT_DIR/.codex/deprecated/$deprecated_name.tmp"
    mv "$VAULT_DIR/.codex/deprecated/$deprecated_name.tmp" "$VAULT_DIR/.codex/deprecated/$deprecated_name"
    warn "Deprecated stale Codex agent: $old_name"
  done < "$OLD_MANIFEST"
fi

# Copy core agents (transformed)
: > "$VAULT_DIR/.codex/agents/.core-manifest"
AGENT_COUNT=0
for agent in "$REPO_DIR/agents/"*.md; do
  name="$(basename "$agent")"
  render_for_codex_file "$agent" "$VAULT_DIR/.codex/agents/$name"
  echo "$name" >> "$VAULT_DIR/.codex/agents/.core-manifest"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done
success "Installed $AGENT_COUNT Codex agents"

mkdir -p "$VAULT_DIR/Meta/states"

# Copy references (preserve mutable refs on reinstall)
USER_MUTABLE_REFS="agents-registry.md agents.md"
: > "$VAULT_DIR/.codex/references/.core-manifest"
REF_COUNT=0
for ref in "$REPO_DIR/references/"*.md; do
  ref_name="$(basename "$ref")"
  dst="$VAULT_DIR/.codex/references/$ref_name"
  if [[ $EXISTING -eq 1 && -f "$dst" && " $USER_MUTABLE_REFS " == *" $ref_name "* ]]; then
    warn "Preserving existing $ref_name"
    echo "$ref_name" >> "$VAULT_DIR/.codex/references/.core-manifest"
    continue
  fi
  render_for_codex_file "$ref" "$dst"
  echo "$ref_name" >> "$VAULT_DIR/.codex/references/.core-manifest"
  REF_COUNT=$((REF_COUNT + 1))
done
success "Installed/updated $REF_COUNT Codex references"

# Copy skills (transformed)
SKILL_COUNT=0
if [[ -d "$REPO_DIR/skills" ]]; then
  for skill_dir in "$REPO_DIR/skills/"*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$VAULT_DIR/.codex/skills/$skill_name"
    render_for_codex_file "$skill_dir/SKILL.md" "$VAULT_DIR/.codex/skills/$skill_name/SKILL.md"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  done
fi
success "Installed $SKILL_COUNT Codex skills"

# Install AGENTS.md with conflict prompt
MANAGED_HEADER="<!-- managed-by: my-brain-is-full-crew -->"
TMP_AGENTS="$VAULT_DIR/.codex/AGENTS.generated.md"
printf '%s\n' "$MANAGED_HEADER" > "$TMP_AGENTS"
cat "$REPO_DIR/AGENTS.md" >> "$TMP_AGENTS"

if [[ -f "$VAULT_DIR/AGENTS.md" ]]; then
  if grep -qF "$MANAGED_HEADER" "$VAULT_DIR/AGENTS.md"; then
    cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.md"
    success "Updated managed AGENTS.md"
  else
    warn "Found existing unmanaged AGENTS.md"
    read -r -p "Overwrite vault AGENTS.md with Crew dispatcher? [o/s]: " AGENTS_ANSWER || true
    if [[ "${AGENTS_ANSWER:-s}" =~ ^[Oo]$ ]]; then
      cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.md"
      success "Overwrote AGENTS.md"
    else
      cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.crew.md"
      warn "Wrote AGENTS.crew.md instead"
    fi
  fi
else
  cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.md"
  success "Installed AGENTS.md"
fi
rm -f "$TMP_AGENTS"

# Optional MCP file
read -r -p "Set up Gmail + Google Calendar MCP (.mcp.json)? [y/N]: " MCP_ANSWER || true
if [[ "${MCP_ANSWER:-n}" =~ ^[Yy]$ ]]; then
  if [[ -f "$VAULT_DIR/.mcp.json" ]]; then
    warn ".mcp.json already exists, not overwriting"
  else
    cp "$REPO_DIR/.mcp.json" "$VAULT_DIR/.mcp.json"
    success "Created .mcp.json"
  fi
fi

echo
echo "Codex setup complete."
echo "Installed to: $VAULT_DIR/.codex"
echo "Next steps:"
echo "1) Open Codex CLI inside the vault folder"
echo "2) Ensure AGENTS.md (or AGENTS.crew.md) is active for this vault"
echo "3) Start with: Initialize my vault"
