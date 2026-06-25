---
type: wiki/governance
title: Wiki Dispatcher Routing — Trigger Map
purpose: single source of truth for routing Wiki-memory phrasing to the two Wiki skills
updated: 2026-06-25 01:15
sources:
  - "[[.overnight/PLAN.md]] §4-step6 (Register in dispatcher)"
  - "[[.overnight/PLAN.md]] §3.3 / §3.5 (the two Wiki skills)"
status: active
---

# Wiki Dispatcher Routing — `/wiki-ingest` & `/wiki-audit`

This document is the **single source of truth** for how the Crew dispatcher
recognizes Wiki-memory intent and routes it to the two Wiki skills. It carries
the exact paste-ready routing text for both layouts. The per-skill trigger
phrases also live in each skill's `description` (how skill loaders match); this
file covers the **global dispatcher** layer PLAN §4-step6 calls for.

The two Wiki skills are the **only** writers to the Wiki (see `index.md` →
*Routing Rules*). Everything else reads selectively (`context-injection.md`).

| Skill | Owns | Writes? |
|-------|------|---------|
| `/wiki-ingest` | Compile raw input / `inbox/` into patch-style page updates with provenance | Yes (snapshot → patch) |
| `/wiki-audit` | Periodic lint, graph hygiene, contradiction resolution, rollback | Yes (snapshot → patch + lint diff) |

---

## Canonical Routing Block

Paste this into the dispatcher. On the **canonical** layout the dispatcher is
`AGENTS.md`; on the **flat** layout (vault `My-Brain-Is-Full-Crew`) it is
`CLAUDE.md`. Insert it as a new routing entry, immediately after the existing
read/capture agents and before low-priority maintenance — Wiki-memory routing
should sit **above** generic note capture so "remember this in the wiki" reaches
`/wiki-ingest` instead of being captured as a plain note.

```markdown
## WIKI MEMORY (compiled long-term memory)

The LLM Wiki (`references/wiki/`, or `references/wiki/` on the flat
layout) is the Crew's compiled long-term memory. Two skills write to it;
everything else reads selectively (see `references/wiki/context-injection.md`).

### /wiki-ingest — COMPILE into the Wiki
Activate to **record, compile, or absorb** information as durable, linked,
source-cited Wiki pages. This is the ONLY routine compile path.

Triggers: "remember this", "update the wiki", "compile this into the wiki",
"add this to my knowledge", "absorb this", "ingest this", "learn this",
"wire this into the wiki", "wiki this", "what do I know about X" (when the
answer is missing/stale AND the input should be recorded), "ricorda questo nel
wiki", "aggiorna il wiki", "memorizza questo", "mets ça dans le wiki",
"memoriza esto", "actualiza el wiki", "merke dir das im Wiki", "anota isso no
wiki". Also route here when a capture agent (Scribe, Sorter, Postman,
Transcriber, Connector) hands off an `inbox/` item or structured payload for
compilation.

### /wiki-audit — LINT, REPAIR, or ROLLBACK the Wiki
Activate for **Wiki health, cleanup, or undo**. Periodic graph hygiene and
reversibility.

Triggers: "audit the wiki", "wiki audit", "lint the wiki", "check wiki health",
"wiki health", "clean the wiki", "fix the wiki", "are there wiki orphans?",
"broken wiki links", "wiki duplicates", "stale wiki projects", "resolve wiki
contradictions", "rollback the wiki", "undo wiki change", "revert a wiki page",
"split this wiki page", "what's wrong with the wiki", "audita il wiki", "controlla il wiki", "pulisci il wiki", "vérifie le wiki",
"nettoie le wiki", "audita el wiki", "limpia el wiki", "Wiki prüfen", "Wiki
aufräumen", "audita o wiki", "limpa o wiki". Also activate when the Librarian
runs periodic graph hygiene or resolves `_contradictions.md` items.

### Routing priority vs. capture agents
- "Remember this in the wiki" → `/wiki-ingest` (NOT Scribe). Scribe captures the
  raw note to `inbox/`; `/wiki-ingest` compiles it as a second step.
- "What do I know about X?" with no record-intent → **Seeker** (read-only
  answer). With record-intent ("…and add this") → `/wiki-ingest`.
- "Audit / clean / fix the vault" (general) → **Librarian**. "Audit / clean /
  fix the **wiki**" → `/wiki-audit`. When ambiguous, prefer `/wiki-audit` only
  if the user explicitly says "wiki".
```

---

## Disambiguation Notes (for the dispatcher)

These three confusions are the common ones — call them out so the dispatcher
does not misroute:

1. **Compile vs. capture.** "Remember this" alone is ambiguous. If the user
   wants it in the *Wiki* (durable, cross-referenced memory) → `/wiki-ingest`.
   If they just want a quick note → Scribe. When unsure, Scribe captures raw and
   `/wiki-ingest` compiles — they compose, they do not conflict.
2. **Read vs. write.** "What do I know about X?" is a **read** → Seeker (which
   consults the Wiki within its budget). Only route to `/wiki-ingest` if the
   user also wants the answer *recorded/updated*.
3. **Whole-vault vs. Wiki.** "Audit the vault" → Librarian (whole Obsidian
   vault). "Audit the wiki" → `/wiki-audit` (the Wiki subtree only). The
   Librarian may **invoke** `/wiki-audit` for the Wiki portion of a full audit.

---

## Wiring — How to Apply

### On the canonical layout (`AGENTS.md`)
1. Add the **Canonical Routing Block** above as a new top-level routing section.
2. Add a one-line entry to the routing-priority table (if one exists):
   `| wiki-ingest | record/compile into the long-term-memory Wiki |` and
   `| wiki-audit | lint/repair/rollback the Wiki |`, placed above generic
   capture/maintenance.

### On the flat layout (`CLAUDE.md`, vault `My-Brain-Is-Full-Crew`)
1. Paste the same block, with `references/wiki/` paths, as a new `##` section.
2. Add the two rows to the *Routing priority* table. Wiki-memory routing should
   sit above **scribe** (so "remember this in the wiki" is not swallowed by plain
   capture) and above **librarian** (so "audit the wiki" is not swallowed by a
   full-vault audit).
3. Note in the *ABSOLUTE CONSTRAINT* section that `/wiki-ingest` and
   `/wiki-audit` are the two sanctioned Wiki writers; no agent writes to
   `references/wiki/` directly except via them.

### In the agent directory (`references/agents.md` on the flat layout)
Add a *Wiki memory* line to each agent entry (one already lives in
`context-injection.md` per agent) noting whether that agent may invoke
`/wiki-ingest` (capture + decision agents) or `/wiki-audit` (Librarian only).

---

## What NOT to do

- Do **not** let any agent except `/wiki-ingest` and `/wiki-audit` write to the
  Wiki. This is the single hardest rule; the dispatcher must never route a write
  intent to Scribe/Librarian/etc. for Wiki pages.
- Do **not** route "what do I know about X?" (pure read) to `/wiki-ingest` —
  that is Seeker. Ingest is for *recording*.
- Do **not** duplicate the full trigger list in ten agent files — the canonical
  list lives in each skill's `description`; this file owns the *dispatcher*-level
  routing text only.

---

## Consistency & Maintenance

- **This file** owns the dispatcher routing text for the two Wiki skills — edit
  triggers here, not in the dispatcher prose (mirror the change to the skill
  `description` if a trigger is added, so skill-loader matching stays in sync).
- **Each skill's `description`** is the authoritative trigger list for skill
  loaders; this file is the authoritative list for the global dispatcher. Keep
  them aligned.
- **`index.md`** *Related Skills & Governance* points here (and at
  `context-injection.md`) so there is one entry point, no orphans.
- When `/wiki-audit` (Phase 4) runs, it can flag dispatcher routes that chronically
  misroute (e.g., Wiki writes landing on Scribe) so this map can be tightened.
