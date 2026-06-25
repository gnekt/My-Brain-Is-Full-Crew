---
title: LLM Wiki — Index & Manifest
type: wiki-index
purpose: routing-table
updated: 2026-06-25
---

# LLM Wiki — Index

This file is a **manifest and routing table**, not a concatenation of entries.
Keep it short. Page content lives in the category folders; this file only
points to categories, states the rules, and (later) lists top-level pages.

The Wiki is the Crew's **compiled long-term memory cortex**. It is
*compiled-wiki-first, retrieval-when-needed*: prefer full-context synthesis on
this small curated corpus; fall back to search / embeddings / MCP reads when
the corpus is large, low-signal, or stale. The Wiki does **not** replace
retrieval or the `Meta/agent-messages.md` short-term board — it complements
them.

---

## Directory Map

| Path | Holds |
|------|-------|
| `concepts/` | Durable ideas, definitions, mental models, how-things-work. |
| `projects/` | Active and past projects: goals, decisions, status, history. |
| `people/` | People & entities the user interacts with (contacts, orgs, teams). |
| `sources/` | One summary per source note/email/file, with provenance back-link. |
| `inbox/` | Uncompiled raw captures, staged before `/wiki-ingest` runs. |
| `_contradictions.md` | Human-review queue for ambiguous merges / conflicts. |
| `.history/` | Timestamped snapshots of changed pages (rollback source) + machine-readable lint diffs from `/wiki-audit` (under `.history/_lint/`). |

> Path scheme note: this canonical layout (`references/wiki/`) follows
> the integration strategy §3.1 (see `.overnight/PLAN.md`). On installations where the Crew uses flat
> `references/`, `agents/`, `skills/` dirs, mirror this tree under
> `references/wiki/`. The structure and rules are identical either way.

---

## Routing Rules (for every agent)

1. **When to consult the Wiki.** For tasks involving **projects, people,
   policies, preferences, or prior decisions**, first read this `index.md`,
   then follow only the directly relevant `[[wikilinks]]`. Do **not** load the
   whole Wiki.
2. **Context budget.** Per agent: the index manifest + up to ~8k tokens of
   relevant page slices. Full-corpus synthesis is reserved for the
   `/wiki-ingest` and `/wiki-audit` skills, where coherence matters most.
3. **Missing or stale?** Note the gap (`_contradictions.md` or your task
   report) and proceed. Do not silently fabricate.
4. **Never auto-rewrite.** Only `/wiki-ingest` and `/wiki-audit` write here,
   and only with patch-style updates + a `.history/` snapshot first.
5. **Writing is conservative.** Ambiguous merges and low-confidence claims go
   to `_contradictions.md` for a human, never silently resolved.

---

## Page Conventions

Every compiled page **must** carry:

```yaml
---
type: wiki/<concept|project|person|source>
title: "{{Page Title}}"
aliases: ["{{alternate spellings / names}}"]
updated: {{YYYY-MM-DD HH:MM}}
sources: ["[[path/to/source note]]"]   # provenance — never omit
status: {{active|stale|archived}}
---
```

- **Provenance is mandatory.** Every claim links back to at least one source
  note/email/file in `sources/` and records `updated`.
- **Wikilinks, not copies.** Link related pages with `[[Concept]]`; do not
  duplicate content across pages.
- **Patch, don't rewrite.** Updates insert/edit lines; they do not regenerate
  the whole page.
- **Naming.** `kebab-case.md` matching the canonical concept name, e.g.
  `concepts/llm-wiki-pattern.md`. Aliases handle alternate spellings.
- **Size.** If a page exceeds ~300 lines, split it (the `/wiki-audit` skill
  flags this).

---

## Category Indexes

> Populated by `/wiki-ingest` as pages are created. Listed newest-first.

### Concepts
*(none yet)*

### Projects
*(none yet)*

### People
*(none yet)*

### Sources
*(none yet)*

---

## Related Skills & Governance

- `/wiki-ingest` — conservative compile of `inbox/` and inline input into
  patch-style page updates. (`skills/wiki-ingest/SKILL.md`)
- `/wiki-audit` — periodic graph hygiene: orphans, broken links, duplicates,
  stale status, oversized pages. (`skills/wiki-audit/SKILL.md`)
- `context-injection.md` — per-agent Wiki consultation spec: the canonical
  injection snippet (paste into every agent) + the per-agent context-budget
  table. This `index.md` is the user-facing summary; that file is the
  agent-embedding source of truth.
- `dispatcher-routing.md` — the global-dispatcher trigger map: how the Crew
  dispatcher routes Wiki-memory phrasing ("remember this", "audit the wiki",
  "what do I know about X") to `/wiki-ingest` vs. `/wiki-audit`, with paste-ready
  blocks for `AGENTS.md` and the flat-layout `CLAUDE.md`.
- `mcp-server.md` — **optional**: mount the Wiki as a read-only MCP resource
  (scoped retrieval fallback, not a compiled-context replacement). Paste-ready
  config for Codex TOML and the flat-layout `.mcp.json`, plus the
  closed-world dispatcher amendment the mount requires.
