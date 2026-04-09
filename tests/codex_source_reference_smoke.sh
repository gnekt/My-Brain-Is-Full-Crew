#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if rg -n 'CLAUDE\.md|\.claude/|Claude Code|claude --plugin-dir|Claude Code Desktop|Claude Code CLI|Claude mobile app' \
  agents \
  skills \
  references \
  README.md \
  CONTRIBUTING.md \
  docs/getting-started.md \
  docs/mobile-access.md \
  .claude-plugin/plugin.json
then
  echo "Found Claude-specific runtime/source references that must be migrated." >&2
  exit 1
fi

echo "codex_source_reference_smoke: PASS"
