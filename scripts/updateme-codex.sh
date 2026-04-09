#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Codex Updater
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

[[ -d "$VAULT_DIR/.codex/agents" ]] || die "No .codex/agents found in $VAULT_DIR. Run launchme-codex.sh first."

read -r -p "Update Codex core files in this vault? [c/q]: " UPDATE_ANSWER || true
[[ "${UPDATE_ANSWER:-q}" =~ ^[Cc]$ ]] || { info "Update cancelled"; exit 0; }

# Deprecate removed core agents
MANIFEST="$VAULT_DIR/.codex/agents/.core-manifest"
if [[ -f "$MANIFEST" ]]; then
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
    warn "Deprecated removed core agent: $old_name"
  done < "$MANIFEST"
fi

# Update agents
AGENT_COUNT=0
: > "$VAULT_DIR/.codex/agents/.core-manifest"
for agent in "$REPO_DIR/agents/"*.md; do
  name="$(basename "$agent")"
  dst="$VAULT_DIR/.codex/agents/$name"
  tmp="$dst.tmp"
  render_for_codex_file "$agent" "$tmp"
  if [[ ! -f "$dst" ]] || ! diff -q "$tmp" "$dst" >/dev/null 2>&1; then
    mv "$tmp" "$dst"
    info "Updated agent: $name"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  else
    rm -f "$tmp"
  fi
  echo "$name" >> "$VAULT_DIR/.codex/agents/.core-manifest"
done

# Deprecate removed core references
REF_MANIFEST="$VAULT_DIR/.codex/references/.core-manifest"
if [[ -f "$REF_MANIFEST" ]]; then
  while IFS= read -r old_ref; do
    [[ -z "$old_ref" ]] && continue
    [[ -f "$REPO_DIR/references/$old_ref" ]] && continue
    dst="$VAULT_DIR/.codex/references/$old_ref"
    [[ -f "$dst" ]] || continue
    mkdir -p "$VAULT_DIR/.codex/deprecated"
    deprecated_name="${old_ref%.md}-DEPRECATED.md"
    [[ -f "$VAULT_DIR/.codex/deprecated/$deprecated_name" ]] && continue
    mv "$dst" "$VAULT_DIR/.codex/deprecated/$deprecated_name"
    { echo "########"; echo "DEPRECATED DO NOT USE"; echo "########"; echo ""; cat "$VAULT_DIR/.codex/deprecated/$deprecated_name"; } > "$VAULT_DIR/.codex/deprecated/$deprecated_name.tmp"
    mv "$VAULT_DIR/.codex/deprecated/$deprecated_name.tmp" "$VAULT_DIR/.codex/deprecated/$deprecated_name"
    warn "Deprecated removed core reference: $old_ref"
  done < "$REF_MANIFEST"
fi

# Update references
USER_MUTABLE_REFS="agents-registry.md agents.md"
REF_COUNT=0
mkdir -p "$VAULT_DIR/.codex/references"
: > "$VAULT_DIR/.codex/references/.core-manifest"
for ref in "$REPO_DIR/references/"*.md; do
  ref_name="$(basename "$ref")"
  dst="$VAULT_DIR/.codex/references/$ref_name"
  echo "$ref_name" >> "$VAULT_DIR/.codex/references/.core-manifest"

  # For user-mutable files: merge upstream core changes while preserving custom content
  if [[ " $USER_MUTABLE_REFS " == *" $ref_name "* ]] && [[ -f "$dst" ]]; then
    custom_section=""
    if grep -qn "^## Custom Agents" "$dst"; then
      custom_line=$(grep -n "^## Custom Agents" "$dst" | head -1 | cut -d: -f1)
      custom_section=$(tail -n +"$custom_line" "$dst")
    fi

    custom_table_rows=""
    if [[ "$ref_name" == "agents-registry.md" ]]; then
      CORE_NAMES="architect scribe sorter seeker connector librarian transcriber postman"
      while IFS= read -r row; do
        agent_name=$(echo "$row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        if [[ -n "$agent_name" ]] && ! echo "$CORE_NAMES" | grep -qw "$agent_name"; then
          custom_table_rows="${custom_table_rows}${row}"$'\n'
        fi
      done < <(grep "^|" "$dst" | grep -v "^|[[:space:]]*Name[[:space:]]*|" | grep -v "^|[-[:space:]]*|")
    fi

    tmp="$dst.tmp"
    render_for_codex_file "$ref" "$tmp"

    if [[ -n "$custom_table_rows" && "$ref_name" == "agents-registry.md" ]]; then
      last_table_line=$(grep -n "^|" "$tmp" | tail -1 | cut -d: -f1)
      if [[ -n "$last_table_line" ]]; then
        { head -n "$last_table_line" "$tmp"; printf "%s" "$custom_table_rows"; tail -n +"$((last_table_line + 1))" "$tmp"; } > "$tmp.merge"
        mv "$tmp.merge" "$tmp"
      fi
    fi

    if [[ -n "$custom_section" ]]; then
      repo_custom_line=$(grep -n "^## Custom Agents" "$tmp" | head -1 | cut -d: -f1)
      if [[ -n "$repo_custom_line" ]]; then
        head -n "$((repo_custom_line - 1))" "$tmp" > "$tmp.merge"
        printf '%s\n' "$custom_section" >> "$tmp.merge"
        mv "$tmp.merge" "$tmp"
      fi
    fi

    if ! diff -q "$tmp" "$dst" >/dev/null 2>&1; then
      mv "$tmp" "$dst"
      info "Updated reference: $ref_name (preserved custom content)"
      REF_COUNT=$((REF_COUNT + 1))
    else
      rm -f "$tmp"
    fi
    continue
  fi

  tmp="$dst.tmp"
  render_for_codex_file "$ref" "$tmp"
  if [[ ! -f "$dst" ]] || ! diff -q "$tmp" "$dst" >/dev/null 2>&1; then
    mv "$tmp" "$dst"
    info "Updated reference: $ref_name"
    REF_COUNT=$((REF_COUNT + 1))
  else
    rm -f "$tmp"
  fi
done

# Update skills
SKILL_COUNT=0
if [[ -d "$REPO_DIR/skills" ]]; then
  for skill_dir in "$REPO_DIR/skills/"*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$VAULT_DIR/.codex/skills/$skill_name"
    dst="$VAULT_DIR/.codex/skills/$skill_name/SKILL.md"
    tmp="$dst.tmp"
    render_for_codex_file "$skill_dir/SKILL.md" "$tmp"
    if [[ ! -f "$dst" ]] || ! diff -q "$tmp" "$dst" >/dev/null 2>&1; then
      mv "$tmp" "$dst"
      info "Updated skill: $skill_name"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    else
      rm -f "$tmp"
    fi
  done
fi

# Update AGENTS.md
MANAGED_HEADER="<!-- managed-by: my-brain-is-full-crew -->"
TMP_AGENTS="$VAULT_DIR/.codex/AGENTS.generated.md"
printf '%s\n' "$MANAGED_HEADER" > "$TMP_AGENTS"
cat "$REPO_DIR/AGENTS.md" >> "$TMP_AGENTS"

if [[ -f "$VAULT_DIR/AGENTS.md" ]]; then
  if grep -qF "$MANAGED_HEADER" "$VAULT_DIR/AGENTS.md"; then
    cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.md"
    info "Updated managed AGENTS.md"
  else
    warn "Vault AGENTS.md is unmanaged"
    read -r -p "Overwrite unmanaged AGENTS.md? [o/s]: " AGENTS_ANSWER || true
    if [[ "${AGENTS_ANSWER:-s}" =~ ^[Oo]$ ]]; then
      cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.md"
      info "Overwrote AGENTS.md"
    else
      cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.crew.md"
      warn "Wrote AGENTS.crew.md instead"
    fi
  fi
else
  cp "$TMP_AGENTS" "$VAULT_DIR/AGENTS.md"
  info "Installed AGENTS.md"
fi
rm -f "$TMP_AGENTS"

success "Codex update complete"
echo "Updated: $AGENT_COUNT agent(s), $SKILL_COUNT skill(s), $REF_COUNT reference(s)"
