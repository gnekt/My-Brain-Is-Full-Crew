---
type: wiki/governance
title: Wiki Context Injection — Per-Agent Specification
purpose: agent-embedding spec for selective Wiki consultation
updated: 2026-06-25 00:30
sources:
  - "[[.overnight/PLAN.md]] §3.4 (Phase 3 — Selective Context Injection)"
  - "[[.overnight/PLAN.md]] §4-step8 (Update agent prompts conservatively)"
status: active
---

# Wiki Context Injection — Selective, Per-Agent

This document is the **single source of truth** for (a) the canonical Wiki-consult
instruction that gets embedded in every Crew agent, and (b) the per-agent
context budget. The user-facing summary lives in `index.md` → *Routing Rules*;
this file carries the exact paste-ready text and the per-agent table.

It implements PLAN §3.4 / §4-step8: agents consult the Wiki **selectively**
(index as a routing table → follow only relevant `[[wikilinks]]`), **never**
load the full corpus, and each agent carries an explicit token budget. Full-
context synthesis is reserved for `/wiki-ingest` and `/wiki-audit`.

---

## Design Principle — Compiled-Wiki-First, Retrieval-When-Needed

The source proposal told every agent to load the full Wiki before every task.
That wastes tokens and dilutes attention (recent 2026 compiled-memory work
shows full-context injection on a large corpus causes attention dilution and
cost blowup). The corrected stance, embedded here:

- **Routine task** → agent reads `index.md`, follows at most the directly
  relevant `[[wikilinks]]`, stays under its budget, then proceeds.
- **Coherence-critical task** (compiling, linting, auditing) → `/wiki-ingest`
  and `/wiki-audit` may read the affected subgraph fully. No one else does.
- **Missing or stale** → note the gap (in `_contradictions.md` or the task
  report) and proceed. Never fabricate, never silently rewrite.
- **Large / low-signal / stale corpus** → fall back to retrieval (vault search,
  embeddings, MCP reads — the optional read-only Wiki mount in
  `mcp-server.md`). The Wiki is compiled memory, not a search replacement.

---

## The Canonical Injection Snippet

Paste the block below into **every** agent file, in the position described under
*Wiring*. It is written to be agent-agnostic; the per-agent scope and budget
that follow it specialize it.

```markdown
## Wiki Context (Long-Term Memory)

The LLM Wiki (`references/wiki/`, or `references/wiki/` on the flat
layout) is the Crew's compiled long-term memory. Treat it as
**compiled-wiki-first, retrieval-when-needed**:

1. For tasks involving **projects, people, policies, preferences, or prior
   decisions**, first read `index.md`, then follow **only** the directly
   relevant `[[wikilinks]]`. Do **not** load the whole Wiki.
2. Stay within your **Wiki context budget** (see `context-injection.md`):
   the index manifest + up to your budget of relevant page slices.
3. If the Wiki is missing or stale on the needed topic, note the gap and
   proceed — do not fabricate.
4. **Never write to the Wiki directly.** To record or update compiled
   knowledge, invoke `/wiki-ingest` (it snapshots, patches, and cites sources).
   Ambiguous merges and contradictions go to `_contradictions.md` for a human.

Full-Wiki synthesis is reserved for `/wiki-ingest` and `/wiki-audit`.
```

> The snippet deliberately does **not** name a token figure — the figure lives
> in the per-agent table below and is stated in each agent's budget line, so
> there is one place to tune it.

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
agent (use ~2k) or a coherence-critical writer (exempt). When in doubt, start
low and raise only if the agent demonstrably needs more.

---

## Per-Agent Consultation Guidance

### Capture agents — Scribe, Transcriber, Postman
Low budget by design: their job is **fast capture**, not synthesis. They read
`index.md` for the routing table and follow a wikilink only when a named entity
is genuinely ambiguous (e.g., "which Marco?"). They do **not** compile — they
hand the raw capture to `inbox/` and invoke `/wiki-ingest` (PLAN §4-step7) for
the second-step compile. Loading more would slow capture and dilute attention.

### Read / decision agents — Seeker, Connector, Sorter, Architect
Default budget. Seeker is the heaviest reader (it answers factual questions and
synthesizes); Connector walks the link graph; Sorter and Architect consult
prior project/structure decisions. All stay within budget and fall back to
vault search when the Wiki is stale or the corpus is large.

### Domain agents — Food Coach, Wellness Guide
Moderate budget, scoped to their domain (food/health, emotional context).
Wellness Guide is **read-only** — it never writes; it requests `/wiki-ingest`
(through Scribe) when something should be recorded.

### Wiki writers — `/wiki-ingest`, `/wiki-audit`
Exempt from the per-agent budget cap: these are the only coherence-critical
full-context readers. Everyone else treats the budget as a hard ceiling.

---

## Wiring — How to Apply

### In each agent file (`agents/<name>.md` on the flat layout)

1. Keep the YAML frontmatter as-is.
2. Paste the **Canonical Injection Snippet** above as a new `## Wiki Context
   (Long-Term Memory)` section, immediately **after** the *Inter-Agent
   Messaging Protocol* section and **before** *Core Philosophy* / mode
   sections. This keeps messaging (read-first) and memory (consult-first)
   together, ahead of task logic.
3. Append **one budget line** to that section, e.g. for Scribe:
   > **Your Wiki context budget: ~2k tokens** (index manifest + ~2k of page
   > slices). You are a fast capture agent — do not load the Wiki by default.

### In the dispatcher (`CLAUDE.md` on the flat layout / `AGENTS.md`)

Add a short global note (not per-agent) so the dispatcher itself routes
memory-related phrasing:

> For tasks involving projects, people, policies, preferences, or prior
> decisions, the chosen agent consults `references/wiki/index.md` and
> follows only the relevant linked pages (see `context-injection.md` for
> budgets). `/wiki-ingest` compiles; `/wiki-audit` maintains.

### In the agent directory (`references/agents.md` on the flat layout)

Add a one-line *Wiki memory* note to each of the ten agent entries pointing at
this file, so every agent's directory entry records its budget and scope.

### What NOT to do

- Do **not** instruct any agent (except `/wiki-ingest`, `/wiki-audit`) to load
  the full Wiki. PLAN §3.4 calls this out as the core correction.
- Do **not** raise a budget speculatively — start low, raise on evidence.
- Do **not** let an agent write to the Wiki directly; route through
  `/wiki-ingest`.

---

## Consistency & Maintenance

- **This file** owns the snippet text and the budget table — edit budgets here,
  not in ten agent files.
- **`index.md`** *Routing Rules* is the user-facing summary of the same rules;
  if you change the principle, update both.
- **Per-agent files** carry only the snippet + their single budget line, both
  copied from here. If a budget drifts, this file is the source of truth.
- When `/wiki-audit` (Phase 4) runs, it flags agents whose observed Wiki reads
  chronically exceed their budget, so budgets can be tuned from real usage.
