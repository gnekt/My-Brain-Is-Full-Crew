---
name: engram-briefing
description: >
  Cross-agent status report from Engram shared memory. Queries all 8 agent scopes
  and produces a single read-only briefing showing what every agent has discovered
  and committed. No writes to vault or Engram.
  Trigger: "/engram-briefing"
---

# Engram Briefing — Cross-Agent Status Report

Always respond to the user in their language. Match the language the user writes in.

Query Engram shared memory for all 8 agent scopes and produce a single cross-agent status report. This skill is read-only — no writes to the vault or to Engram.

---

## Procedure

Call `engram_query` once per agent scope, in order:

1. topic: `"vault structure decisions"` — scope: `"architect/findings"`
2. topic: `"note capture patterns"` — scope: `"scribe/findings"`
3. topic: `"inbox triage filing decisions"` — scope: `"sorter/findings"`
4. topic: `"vault search gaps"` — scope: `"seeker/findings"`
5. topic: `"link gaps orphan clusters"` — scope: `"connector/findings"`
6. topic: `"vault health issues findings"` — scope: `"librarian/findings"`
7. topic: `"transcription findings"` — scope: `"transcriber/findings"`
8. topic: `"email calendar import findings"` — scope: `"postman/findings"`

For each scope, extract and display facts up to a limit of 10 per agent. Include each fact's confidence score and fact_type for transparency. After collecting all 8 scopes, scan for cross-agent conflicts (findings that contradict each other) and list them separately.

---

## Output Format

```
Engram Briefing — {{date}}

## Architect — Vault Structure
{{findings from architect/findings with confidence and fact_type, or "No recorded findings."}}

## Scribe — Note Capture
{{findings from scribe/findings with confidence and fact_type, or "No recorded findings."}}

## Sorter — Inbox Triage
{{findings from sorter/findings with confidence and fact_type, or "No recorded findings."}}

## Seeker — Search & Retrieval
{{findings from seeker/findings with confidence and fact_type, or "No recorded findings."}}

## Connector — Knowledge Graph
{{findings from connector/findings with confidence and fact_type, or "No recorded findings."}}

## Librarian — Vault Health
{{findings from librarian/findings with confidence and fact_type, or "No recorded findings."}}

## Transcriber — Audio & Meetings
{{findings from transcriber/findings with confidence and fact_type, or "No recorded findings."}}

## Postman — Email & Calendar
{{findings from postman/findings with confidence and fact_type, or "No recorded findings."}}

---
Cross-agent conflicts: {{list any findings that contradict each other across agent scopes, or "None detected."}}
```

---

## Rules

- This skill is **read-only**. Do not call `engram_commit`. Do not write or modify any vault files.
- If `engram_query` returns no results for a scope, write "No recorded findings." for that agent.
- List each finding with its confidence score and fact_type for transparency.
- Highlight any cross-agent conflicts (e.g., Librarian flagged an area the Architect just created as missing).
