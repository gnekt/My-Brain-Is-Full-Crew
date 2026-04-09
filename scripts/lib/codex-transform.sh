#!/usr/bin/env bash
# Shared text transformation helpers for Codex runtime artifacts.

set -euo pipefail

render_for_codex_file() {
  local src="$1"
  local dst="$2"

  # NOTE: avoid \b word-boundary assertions — they are a GNU extension
  # and silently fail on macOS BSD sed, causing Claude tokens to leak.
  sed -E \
    -e 's/\.claude\//.codex\//g' \
    -e 's/CLAUDE\.md/AGENTS.md/g' \
    -e 's/`Skill` tool/skills system/g' \
    -e 's/`Agent` tool/spawn_agent tool/g' \
    -e 's/Skill tool/skills system/g' \
    -e 's/Agent tool/spawn_agent tool/g' \
    -e 's/AskUserQuestion/request_user_input/g' \
    -e 's/scripts\/launchme\.sh/scripts\/launchme-codex.sh/g' \
    -e 's/scripts\/updateme\.sh/scripts\/updateme-codex.sh/g' \
    -e 's/`launchme\.sh`/`launchme-codex.sh`/g' \
    -e 's/`updateme\.sh`/`updateme-codex.sh`/g' \
    -e 's/launchme\.sh/launchme-codex.sh/g' \
    -e 's/updateme\.sh/updateme-codex.sh/g' \
    -e 's/Claude Code/Codex CLI/g' \
    "$src" > "$dst"
}
