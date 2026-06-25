---
title: LLM Wiki — Index & Manifest
type: wiki-index
purpose: routing-table + per-agent budget + dispatcher routing
updated: 2026-06-25
---

# LLM Wiki — Index

Manifest, routing rules, per-agent context budget, and dispatcher routing for
the Wiki. Page content lives in the category folders; this file points to them,
states the rules, and carries the paste-ready text the Crew's agents and
dispatcher need.

The Wiki is the Crew's **compiled long-term memory cortex** — *compiled-wiki-
first, retrieval-when-needed*. It does **not** replace the
`Meta/agent-messages.md` short-term board, search, embeddings, or the optional
read-only MCP mount. The two skills `/wiki-ingest` and `/wiki-audit` are the
**only** sanctioned writers.

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

---

## Routing Rules (for every agent)

1. **When to consult the Wiki.** For tasks involving **projects, people,
   policies, preferences, or prior decisions**, first read this `index.md`,
   then follow only the directly relevant `[[wikilinks]]`. Do **not** load the
   whole Wiki.
2. **Context budget.** Per agent: the index manifest + up to your budget of
   relevant page slices (table below). Full-corpus synthesis is reserved for
   `/wiki-ingest` and `/wiki-audit`.
3. **Missing or stale?** Note the gap (`_contradictions.md` or your task
   report) and proceed. Do not silently fabricate.
4. **Never write to the Wiki directly.** Only `/wiki-ingest` and `/wiki-audit`
   write, and only with patch-style updates + a `.history/` snapshot first.
5. **Writing is conservative.** Ambiguous merges and low-confidence claims go
   to `_contradictions.md` for a human, never silently resolved.

---

## Per-Agent Context Budget

Budget = the `index.md` manifest **plus** this many tokens of relevant page
slices, per task. Capture agents run low (speed > completeness); the read and
synthesis agents run at the default; the two write skills are exempt.

| Agent | Budget | Consultation scope | When to consult |
|-------|-------:|--------------------|-----------------|
| **Architect** | ~6k | `projects/`, `concepts/` for prior structural/governance decisions, naming, area history | Creating/refactoring an area, project, template, or tag taxonomy |
| **Scribe** | ~2k | `index.md` + one hop on a named entity only when disambiguation is needed | Capture — do **not** load Wiki by default; tag/connect from the index alone |
| **Sorter** | ~4k | `projects/`, `people/` to resolve "which project/area does this belong to" | Filing an ambiguous note; verifying a destination against prior decisions |
| **Seeker** | ~8k | Any category — Seeker is the primary read/synthesis agent | Answering a factual question; verifying before acting; cross-referencing |
| **Connector** | ~6k | `concepts/`, `people/`, `projects/` to find related pages for linking | After a batch is filed; suggesting links; bridge/constellation work |
| **Librarian** | ~8k+ (full subgraph) | Whole Wiki during audits — coherence-critical | Running `/wiki-audit`; resolving `_contradictions.md` items |
| **Transcriber** | ~2k | `index.md` + one hop on a named entity only when disambiguation is needed | Capture — do **not** load Wiki by default |
| **Postman** | ~4k | `people/` (VIPs), `projects/` (thread context) | Identifying a sender, prioritizing, cross-referencing a thread |
| **Food Coach** | ~4k | `concepts/`, `people/` for compiled food preferences and diet context | Suggesting meals; reading preferences; coordinating with Wellness Guide |
| **Wellness Guide** | ~4k | `people/` (the user), `projects/` for prior emotional/decision context | Read-only — never writes; requests `/wiki-ingest` via Scribe |
| **`/wiki-ingest`** | full subgraph | Affected pages + one hop of wikilinks | Compiling input — coherence-critical |
| **`/wiki-audit`** | full graph | Whole Wiki | Lint/audit/rollback — coherence-critical |

**Defaults for new agents:** ~4k unless the agent is a fast capture/streaming
agent (use ~2k) or a coherence-critical writer (exempt). Start low; raise only
on evidence.

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
  note/email/file in `sources:` and records `updated:`.
- **Wikilinks, not copies.** Link related pages with `[[Concept]]`; do not
  duplicate content across pages.
- **Patch, don't rewrite.** Updates insert/edit lines; they do not regenerate
  the whole page.
- **Naming.** `kebab-case.md` matching the canonical concept name, e.g.
  `concepts/llm-wiki-pattern.md`. Aliases handle alternate spellings.
- **Size.** If a page exceeds ~300 lines, split it (the `/wiki-audit` skill
  flags this).

---

## Wiki Context Injection Snippet

Paste this block into every Crew agent file (after *Inter-Agent Messaging
Protocol*, before *Core Philosophy*), and append one budget line per the table
above:

```markdown
## Wiki Context (Long-Term Memory)

The LLM Wiki (`references/wiki/`) is the Crew's compiled long-term memory.
Treat it as **compiled-wiki-first, retrieval-when-needed**:

1. For tasks involving **projects, people, policies, preferences, or prior
   decisions**, first read `index.md`, then follow **only** the directly
   relevant `[[wikilinks]]`. Do **not** load the whole Wiki.
2. Stay within your **Wiki context budget** (see `index.md` table): the index
   manifest + up to your budget of relevant page slices.
3. If the Wiki is missing or stale on the needed topic, note the gap and
   proceed — do not fabricate.
4. **Never write to the Wiki directly.** To record or update compiled
   knowledge, invoke `/wiki-ingest` (it snapshots, patches, and cites sources).
   Ambiguous merges and contradictions go to `_contradictions.md` for a human.

Full-Wiki synthesis is reserved for `/wiki-ingest` and `/wiki-audit`.
```

**For the dispatcher (`CLAUDE.md`)**, also add a one-line global note:

> For tasks involving projects, people, policies, preferences, or prior
> decisions, the chosen agent consults `references/wiki/index.md` and follows
> only the relevant linked pages. `/wiki-ingest` compiles; `/wiki-audit`
> maintains.

---

## Dispatcher Routing — Wiki Memory

Wiki-memory routing should sit **above** generic note capture so "remember this
in the wiki" reaches `/wiki-ingest` instead of being captured as a plain note,
and above generic maintenance so "audit the wiki" is not swallowed by a full-
vault audit. Add this as a new section in `CLAUDE.md` (above **scribe** and
**librarian** in the routing-priority table):

```markdown
## WIKI MEMORY (compiled long-term memory)

The LLM Wiki (`references/wiki/`) is the Crew's compiled long-term memory. Two
skills write to it; everything else reads selectively (see `index.md`).

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
"split this wiki page", "what's wrong with the wiki", "audita il wiki",
"controlla il wiki", "pulisci il wiki", "vérifie le wiki", "nettoie le wiki",
"audita el wiki", "limpia el wiki", "Wiki prüfen", "Wiki aufräumen", "audita o
wiki", "limpa o wiki". Also activate when the Librarian runs periodic graph
hygiene or resolves `_contradictions.md` items.
```

**One non-obvious disambiguation:** "What do I know about X?" with no record-
intent is a **read** → route to **Seeker** (which consults the Wiki within its
budget), not to `/wiki-ingest`. Only route to `/wiki-ingest` if the user also
wants the answer recorded/updated.

Also amend `CLAUDE.md` → *ABSOLUTE CONSTRAINT* to add `/wiki-ingest` and
`/wiki-audit` to the sanctioned-writers list, and add their rows to the
routing-priority table.

---

## Optional: MCP Mount

For a read-only MCP mount of the Wiki (so all agents can read it via the
`Wiki` MCP server as a scoped retrieval fallback), see `mcp-server.md` for the
`.mcp.json` block and the closed-world dispatcher amendment it requires. The
mount is optional — every agent can already read the Wiki directly via its
filesystem tools under the budget above.

---

## Related Skills

- `/wiki-ingest` — conservative compile of `inbox/` and inline input into
  patch-style page updates. (`skills/wiki-ingest/SKILL.md`)
- `/wiki-audit` — periodic graph hygiene: orphans, broken links, duplicates,
  stale status, oversized pages. (`skills/wiki-audit/SKILL.md`)
- `mcp-server.md` — optional read-only MCP mount of the Wiki (with the
  closed-world dispatcher amendment it requires).
