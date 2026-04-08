#!/usr/bin/env bash
# =============================================================================
# My Brain Is Full - Crew :: Shared library
# Sourced by launchme.sh and updateme.sh — do NOT execute directly.
# =============================================================================

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
  RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
  GREEN=''; CYAN=''; YELLOW=''; RED=''; BOLD=''; DIM=''; NC=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
# Everything is on stderr to keep stdout clean for machine-readable output in updateme.sh.
info()    { echo -e "   ${CYAN}>${NC} $*" >&2; }
success() { echo -e "   ${GREEN}✓${NC} $*" >&2; }
warn()    { echo -e "   ${YELLOW}!${NC} $*" >&2; }
die()     { echo -e "\n   ${RED}Error: $*${NC}\n" >&2; exit 1; }

# ── Path resolution ───────────────────────────────────────────────────────────
# Sets SCRIPT_DIR, REPO_DIR, VAULT_DIR globals.
# Usage: resolve_paths "${BASH_SOURCE[0]}"
resolve_paths() {
  SCRIPT_DIR="$(cd "$(dirname "$1")" && pwd)"
  REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  VAULT_DIR="$(cd "$REPO_DIR/.." && pwd)"
  [[ -d "$REPO_DIR/agents"     ]] || die "Can't find agents/ in $REPO_DIR — are you running this from the repo?"
  [[ -d "$REPO_DIR/references" ]] || die "Can't find references/ in $REPO_DIR"
}

# ── Change tracking ───────────────────────────────────────────────────────────
# Set by copy_if_changed and merge_marked_file after every call.
_LAST_CHANGED=0

# Controls per-file logging in install_* functions.
# Set VERBOSE_COPY=1 in the caller for per-file change output (used by updateme.sh).
VERBOSE_COPY=0

# ── copy_if_changed <src> <dst> ───────────────────────────────────────────────
# Copies src to dst only when they differ or dst doesn't exist.
# Sets _LAST_CHANGED=1 if a copy was made, 0 otherwise.
copy_if_changed() {
  local src="$1" dst="$2"
  _LAST_CHANGED=0
  if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    _LAST_CHANGED=1
  fi
}

# ── _insert_after_start_marker <dst> <content> ───────────────────────────────
# Inserts <content> immediately after the MBIFC:CUSTOM_AGENTS_START line in dst.
# dst must already exist and contain the marker.
_insert_after_start_marker() {
  local dst="$1" content="$2"
  [[ -z "$content" ]] && return 0

  local start_line
  start_line=$(grep -n '<!-- MBIFC:CUSTOM_AGENTS_START -->' "$dst" | head -1 | cut -d: -f1)
  [[ -z "$start_line" ]] && return 0

  local saved_file tmpfile
  saved_file="$(mktemp)"
  tmpfile="$(mktemp)"
  # printf '%s\n' ensures a trailing newline so the next file line starts cleanly.
  # bash $() strips trailing newlines, so content never has one already.
  printf '%s\n' "$content" > "$saved_file"

  {
    head -n "$start_line" "$dst"
    cat "$saved_file"
    tail -n +"$((start_line + 1))" "$dst"
  } > "$tmpfile"

  mv "$tmpfile" "$dst"
  rm -f "$saved_file"
}

# ── merge_marked_file <src> <dst> ─────────────────────────────────────────────
# Copies src to dst, preserving content between <!-- MBIFC:CUSTOM_AGENTS_START -->
# and <!-- MBIFC:CUSTOM_AGENTS_END --> markers from the existing dst.
#
# Handles three cases:
#   1. dst doesn't exist              → plain copy
#   2. Both src and dst have markers  → marker-based merge (primary path)
#   3. src has markers, dst doesn't   → migration: extracts legacy custom rows
#                                       from pre-marker installations
#
# Sets _LAST_CHANGED=1 if dst was written.
merge_marked_file() {
  local src="$1" dst="$2"
  _LAST_CHANGED=0

  # Case 1: dst doesn't exist yet
  if [[ ! -f "$dst" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    _LAST_CHANGED=1
    return 0
  fi

  local src_has_markers=0 dst_has_markers=0
  grep -q '<!-- MBIFC:CUSTOM_AGENTS_START -->' "$src" 2>/dev/null && src_has_markers=1
  grep -q '<!-- MBIFC:CUSTOM_AGENTS_START -->' "$dst" 2>/dev/null && dst_has_markers=1

  # src has no markers → standard copy-if-changed
  if [[ $src_has_markers -eq 0 ]]; then
    copy_if_changed "$src" "$dst"
    return 0
  fi

  # Case 3: src has markers, dst doesn't → migration from old format
  if [[ $dst_has_markers -eq 0 ]]; then
    local custom_rows=""
    local CORE_NAMES="architect scribe sorter seeker connector librarian transcriber postman"
    while IFS= read -r row; do
      local aname
      aname=$(printf '%s' "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
      if [[ -n "$aname" ]] && ! echo " $CORE_NAMES " | grep -qw " $aname "; then
        custom_rows="${custom_rows}${row}"$'\n'
      fi
    done < <(grep "^|" "$dst" 2>/dev/null \
               | grep -v "^|[[:space:]]*Name[[:space:]]*|" \
               | grep -v "^|[-:[:space:]]*|")

    cp "$src" "$dst"
    _LAST_CHANGED=1

    if [[ -n "$custom_rows" ]]; then
      _insert_after_start_marker "$dst" "$custom_rows"
      warn "Migrated legacy custom agents in $(basename "$dst") to MBIFC marker format"
    fi
    return 0
  fi

  # Case 2: both have markers → extract saved content, build merged result,
  # only update dst if the result actually differs (ensures idempotency).
  local saved_content
  saved_content=$(awk \
    '/<!-- MBIFC:CUSTOM_AGENTS_START -->/{f=1; next}
     /<!-- MBIFC:CUSTOM_AGENTS_END -->/{f=0}
     f{print}' \
    "$dst")

  local merged; merged="$(mktemp)"
  cp "$src" "$merged"
  [[ -n "$saved_content" ]] && _insert_after_start_marker "$merged" "$saved_content"

  if ! diff -q "$merged" "$dst" >/dev/null 2>&1; then
    cp "$merged" "$dst"
    _LAST_CHANGED=1
    [[ $VERBOSE_COPY -eq 1 && -n "$saved_content" ]] && info "Merged: $(basename "$src") (custom content preserved)"
  fi
  rm -f "$merged"
}

# ── Manifest helpers ──────────────────────────────────────────────────────────
# Single unified manifest at $VAULT_DIR/.claude/.mbifc-manifest
# Format: INI-style with [section] headers, one entry per line.

manifest_read() {
  local section="$1"
  local file="$VAULT_DIR/.claude/.mbifc-manifest"
  [[ -f "$file" ]] || return 0
  awk -v sec="[$section]" '
    $0 == sec         { found=1; next }
    found && /^\[[a-zA-Z0-9_-]+\]$/ { exit }
    found && NF > 0   { print }
  ' "$file"
}

manifest_write() {
  local section="$1"; shift
  local entries=("$@")
  local file="$VAULT_DIR/.claude/.mbifc-manifest"
  mkdir -p "$(dirname "$file")"
  local tmpfile; tmpfile="$(mktemp)"
  local in_section=0 section_written=0

  if [[ -f "$file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "[$section]" ]]; then
        in_section=1; continue
      fi
      if [[ "$line" =~ ^\[[a-zA-Z0-9_-]+\]$ ]] && [[ $in_section -eq 1 ]]; then
        in_section=0
        # Write the replacement section, then the next section header
        { printf '[%s]\n' "$section"
          for e in "${entries[@]}"; do [[ -n "$e" ]] && printf '%s\n' "$e"; done
          printf '\n'
        } >> "$tmpfile"
        section_written=1
      fi
      [[ $in_section -eq 0 ]] && printf '%s\n' "$line" >> "$tmpfile"
    done < "$file"
  fi

  # Section wasn't encountered, or was at end of file with no following section
  if [[ $section_written -eq 0 ]]; then
    { printf '[%s]\n' "$section"
      for e in "${entries[@]}"; do [[ -n "$e" ]] && printf '%s\n' "$e"; done
      printf '\n'
    } >> "$tmpfile"
  fi

  mv "$tmpfile" "$file"
}

manifest_remove() {
  local section="$1" name="$2"
  local file="$VAULT_DIR/.claude/.mbifc-manifest"
  [[ -f "$file" ]] || return 0
  local tmpfile; tmpfile="$(mktemp)"
  local in_section=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "[$section]" ]]; then in_section=1; printf '%s\n' "$line" >> "$tmpfile"; continue; fi
    if [[ "$line" =~ ^\[[a-zA-Z0-9_-]+\]$ ]]; then in_section=0; fi
    if [[ $in_section -eq 1 && "$line" == "$name" ]]; then continue; fi
    printf '%s\n' "$line" >> "$tmpfile"
  done < "$file"
  mv "$tmpfile" "$file"
}

# Converts legacy per-directory .core-manifest files to the unified format.
# Runs only when legacy files are present; idempotent thereafter.
manifest_migrate() {
  local agents_mf="$VAULT_DIR/.claude/agents/.core-manifest"
  local refs_mf="$VAULT_DIR/.claude/references/.core-manifest"
  [[ -f "$agents_mf" ]] || [[ -f "$refs_mf" ]] || return 0

  warn "Migrating legacy manifests to unified .mbifc-manifest..."

  if [[ -f "$agents_mf" ]]; then
    local entries=()
    while IFS= read -r line || [[ -n "$line" ]]; do [[ -n "$line" ]] && entries+=("$line"); done < "$agents_mf"
    manifest_write "agents" "${entries[@]}"
    rm "$agents_mf"
  fi

  if [[ -f "$refs_mf" ]]; then
    local entries=()
    while IFS= read -r line || [[ -n "$line" ]]; do [[ -n "$line" ]] && entries+=("$line"); done < "$refs_mf"
    manifest_write "references" "${entries[@]}"
    rm "$refs_mf"
  fi

  success "Manifest migrated to .claude/.mbifc-manifest"
}

# ── Deprecation ───────────────────────────────────────────────────────────────

# deprecate_removed <section> <src_dir> <dst_dir>
# Moves files listed in the manifest for <section> that no longer exist in
# <src_dir> to $VAULT_DIR/.claude/deprecated/, prepending a DEPRECATED header.
# Prints the count of deprecated files to stdout.
deprecate_removed() {
  local section="$1" src_dir="$2" dst_dir="$3"
  local count=0

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    [[ -f "$src_dir/$name" ]] && continue        # still in repo — keep it
    local vault_file="$dst_dir/$name"
    [[ -f "$vault_file" ]] || continue            # not present — skip
    [[ "$name" == *"-DEPRECATED"* ]] && continue  # already deprecated

    local dep_name="${name%.md}-DEPRECATED.md"
    local dep_dir="$VAULT_DIR/.claude/deprecated"
    mkdir -p "$dep_dir"
    [[ -f "$dep_dir/$dep_name" ]] && continue     # already done in a prior run

    mv "$vault_file" "$dep_dir/$dep_name"
    { printf '########\nDEPRECATED DO NOT USE\n########\n\n'
      cat "$dep_dir/$dep_name"
    } > "$dep_dir/$dep_name.tmp"
    mv "$dep_dir/$dep_name.tmp" "$dep_dir/$dep_name"

    manifest_remove "$section" "$name"
    warn "Deprecated: $name → .claude/deprecated/$dep_name"
    count=$((count + 1))
  done < <(manifest_read "$section")

  printf '%d' "$count"
}

# ── Component installers ──────────────────────────────────────────────────────
# Each function installs one component type and prints the changed-file count
# to stdout. All respect VERBOSE_COPY for per-file logging.
#
# USER_MUTABLE_REFS: space-separated list of reference filenames that may
# contain user-added content between MBIFC markers. These use merge_marked_file
# instead of copy_if_changed.
USER_MUTABLE_REFS="agents-registry.md agents.md"

install_agents() {
  local src_dir="$1" dst_dir="$2"
  local count=0 manifest=()
  mkdir -p "$dst_dir"
  for src in "$src_dir/"*.md; do
    [[ -f "$src" ]] || continue
    local name; name="$(basename "$src")"
    manifest+=("$name")
    copy_if_changed "$src" "$dst_dir/$name"
    if [[ $_LAST_CHANGED -eq 1 ]]; then
      [[ $VERBOSE_COPY -eq 1 ]] && info "Updated agent: $name"
      count=$((count + 1))
    fi
  done
  manifest_write "agents" "${manifest[@]}"
  printf '%d' "$count"
}

install_refs() {
  local src_dir="$1" dst_dir="$2"
  local count=0 manifest=()
  mkdir -p "$dst_dir"
  for src in "$src_dir/"*.md; do
    [[ -f "$src" ]] || continue
    local name; name="$(basename "$src")"
    local dst="$dst_dir/$name"
    manifest+=("$name")
    if [[ " $USER_MUTABLE_REFS " == *" $name "* ]]; then
      merge_marked_file "$src" "$dst"
    else
      copy_if_changed "$src" "$dst"
    fi
    if [[ $_LAST_CHANGED -eq 1 ]]; then
      [[ $VERBOSE_COPY -eq 1 ]] && info "Updated reference: $name"
      count=$((count + 1))
    fi
  done
  manifest_write "references" "${manifest[@]}"
  printf '%d' "$count"
}

install_skills() {
  local src_dir="$1" dst_dir="$2"
  local count=0 manifest=()
  [[ -d "$src_dir" ]] || { printf '0'; return 0; }
  for skill_src in "$src_dir/"*/; do
    [[ -f "${skill_src}SKILL.md" ]] || continue
    local name; name="$(basename "$skill_src")"
    manifest+=("$name")
    mkdir -p "$dst_dir/$name"
    copy_if_changed "${skill_src}SKILL.md" "$dst_dir/$name/SKILL.md"
    if [[ $_LAST_CHANGED -eq 1 ]]; then
      [[ $VERBOSE_COPY -eq 1 ]] && info "Updated skill: $name"
      count=$((count + 1))
    fi
  done
  manifest_write "skills" "${manifest[@]}"
  printf '%d' "$count"
}

install_hooks() {
  local src_dir="$1" dst_dir="$2"
  local count=0 manifest=()
  [[ -d "$src_dir" ]] || { printf '0'; return 0; }
  mkdir -p "$dst_dir"
  for src in "$src_dir/"*.sh; do
    [[ -f "$src" ]] || continue
    local name; name="$(basename "$src")"
    local dst="$dst_dir/$name"
    manifest+=("$name")
    copy_if_changed "$src" "$dst"
    if [[ $_LAST_CHANGED -eq 1 ]]; then
      chmod +x "$dst"
      [[ $VERBOSE_COPY -eq 1 ]] && info "Updated hook: $name"
      count=$((count + 1))
    fi
  done
  manifest_write "hooks" "${manifest[@]}"
  printf '%d' "$count"
}

# install_settings <src_json> <dst_dir>
# Always syncs settings.json from src to dst when they differ.
# Creates a .bak of the previous version so users can recover custom entries.
# Sets _LAST_CHANGED.
install_settings() {
  local src="$1" dst_dir="$2"
  local dst="$dst_dir/settings.json"
  _LAST_CHANGED=0
  [[ -f "$src" ]] || return 0
  mkdir -p "$dst_dir"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    _LAST_CHANGED=1
  elif ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    cp "$dst" "${dst}.bak"
    cp "$src" "$dst"
    _LAST_CHANGED=1
    [[ $VERBOSE_COPY -eq 1 ]] && info "Updated settings.json (previous version saved as settings.json.bak)"
    [[ $VERBOSE_COPY -eq 1 ]] && info "For custom hooks, use settings.local.json instead"
  fi
}

# install_claude_md <src> <vault_dir>
# Copies DISPATCHER.md (src) to vault_dir/CLAUDE.md.
# Sets _LAST_CHANGED.
install_claude_md() {
  local src="$1" vault_dir="$2"
  [[ -f "$src" ]] || return 0
  copy_if_changed "$src" "$vault_dir/CLAUDE.md"
  [[ $_LAST_CHANGED -eq 1 && $VERBOSE_COPY -eq 1 ]] && info "Updated CLAUDE.md"
}

# ── UI helpers ────────────────────────────────────────────────────────────────

print_banner() {
  local title="$1"
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║  My Brain Is Full - Crew :: ${title}${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
  echo ""
}
