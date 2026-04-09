#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if rg -n '~/.codex/agents|agents/ folder of the plugin|\.mcp\.json exists \(if integrations were enabled\)' skills/onboarding/SKILL.md; then
  echo "Onboarding still contains stale runtime installation assumptions." >&2
  exit 1
fi

if rg -n '\*\*Postman\*\*.*Gmail and Google Calendar integration|Gmail integration|Google Calendar integration' skills/onboarding/SKILL.md agents/architect.md; then
  echo "Active runtime docs still describe Postman as an active integration surface." >&2
  exit 1
fi

if rg -n '\*\*Postman\*\*|Claude cannot directly transcribe audio' skills/transcribe/SKILL.md agents/transcriber.md; then
  echo "Transcription runtime still depends on gated Postman behavior or stale host wording." >&2
  exit 1
fi

if rg -n 'Do you use Gmail, Hey.com, or Google Calendar|\.mcp\.json|/email-triage skill scans Gmail|The Postman needs at least one email backend|Talk to Claude' docs/getting-started.md; then
  echo "Getting-started guide still advertises inactive Postman setup or stale host wording." >&2
  exit 1
fi

echo "codex_active_runtime_consistency_smoke: PASS"
