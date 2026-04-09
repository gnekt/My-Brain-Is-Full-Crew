#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if ! rg -n '1\. `raw audio only`' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing the raw-audio source gate." >&2
  exit 1
fi

if ! rg -n '2\. `transcript or transcript-like text`' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing the transcript source gate." >&2
  exit 1
fi

if ! rg -n 'cannot natively transcribe raw audio by itself' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing the immediate raw-audio limitation disclosure." >&2
  exit 1
fi

if ! rg -n '### Layer 1: Required minimum intake' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing the Layer 1 intake section." >&2
  exit 1
fi

if ! rg -n '1\. \*\*Purpose\*\*:' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing Layer 1 Purpose intake." >&2
  exit 1
fi

if ! rg -n '2\. \*\*Output target\*\*:' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing Layer 1 Output target intake." >&2
  exit 1
fi

if ! rg -n '3\. \*\*Destination\*\*:' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing Layer 1 Destination intake." >&2
  exit 1
fi

if ! rg -n '4\. \*\*Speaker context\*\*:' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing Layer 1 Speaker context intake." >&2
  exit 1
fi

if ! rg -n 'Do not make `date`, `language`, `priority flags`, or `transcript format` default first-layer requirements' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill is missing the first-layer boundary against legacy broad intake." >&2
  exit 1
fi

if ! rg -n 'first separates `raw audio only` from `transcript or transcript-like text`' agents/transcriber.md >/dev/null; then
  echo "Transcriber agent is missing the raw-audio versus transcript intake contract." >&2
  exit 1
fi

if ! rg -n '1\. `Purpose`|2\. `Output target`|3\. `Destination`|4\. `Speaker context`' agents/transcriber.md >/dev/null; then
  echo "Transcriber agent is missing the four-field Layer 1 intake contract." >&2
  exit 1
fi

if ! rg -n 'should not invent a parallel intake model|imply that Codex can natively transcribe raw audio by itself' agents/transcriber.md >/dev/null; then
  echo "Transcriber agent is missing the explicit alignment boundary with /transcribe." >&2
  exit 1
fi

if rg -n '^## Intake Interview$|^\d+\. \*\*Date & time\*\* of the recording|^\d+\. \*\*Priority flags\*\*:' skills/transcribe/SKILL.md >/dev/null; then
  echo "Transcribe skill still contains the legacy front-loaded intake interview." >&2
  exit 1
fi

echo "codex_transcribe_intake_smoke: PASS"
