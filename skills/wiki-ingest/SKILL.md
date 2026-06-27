---
name: wiki-ingest
description: >
  Compile raw input into the LLM Wiki (`references/wiki/`) as conservative,
  patch-style page updates with mandatory provenance — never full rewrites. Use when
  the user (or another agent) wants the Crew to remember, compile, or absorb
  information into long-term memory. Triggers: "remember this", "update the wiki",
  "compile this into the wiki", "add this to my knowledge", "absorb this", "ingest
  this", "learn this", "wire this into the wiki", "what do I know about X" (when
  the answer is missing/stale and the input should be recorded), "wiki this",
  "ricorda questo nel wiki", "aggiorna il wiki", "memorizza questo", "mets ça dans
  le wiki", "mets à jour le wiki", "memoriza esto", "actualiza el wiki", "merke
  dir das im Wiki", "aktualisiere das Wiki", "anota isso no wiki", "atualiza o
  wiki", or when a capture skill (inbox-triage, email-triage, transcribe, contact-sync)
  hands off an `inbox/` item or structured payload for compilation.
---

# Wiki Ingest — Conservative Knowledge Compiler

Always respond to the user in their language. Match the language the user writes in.

The Wiki Ingest skill is the **only** routine path that writes to `references/wiki/`
(other than `/wiki-audit`). Its job is to turn raw input — a file, inline text, or a
structured payload from a capture skill — into durable, linked, source-cited Wiki pages,
**without ever silently rewriting what is already there**.

> **Single most important rule:** prefer leaving the Wiki untouched over rewriting
> accurate prior knowledge. When in doubt, snapshot, propose a patch, and route the
> ambiguity to `_contradictions.md` for a human.

The Wiki is *compiled-wiki-first, retrieval-when-needed* long-term memory. It does not
replace search, embeddings, or MCP reads. See `index.md` for the routing rules and page
conventions; this skill follows them exactly.

---

## Vault Path Resolution

Read `{{meta}}/vault-map.md` to resolve any `{{...}}` vault-role tokens in this file
(`{{inbox}}`, `{{meta}}`, etc.). Substitute only the 11 tokens defined in
`docs/vault-mapping.md`; leave other `{{...}}` patterns (like `{{date}}`, `{{Name}}`)
untouched — they are template placeholders.

If `vault-map.md` is missing, the defaults are:

| Token | Default |
|-------|---------|
| `{{inbox}}` | `00-Inbox` |
| `{{meta}}` | `Meta` |

The Wiki itself is at `references/wiki/` — that path is **not** tokenized, it is a
fixed source-tree location that ships with the Crew.

---

## User Profile

Read `{{meta}}/user-profile.md` to understand the user's context, preferences, and
active projects. Use it to disambiguate names, choose the right project, and pick
tags.

---

## Inter-Skill Coordination

The dispatcher (`DISPATCHER.md`) handles all routing and chaining. **This skill does
not communicate directly with other skills or agents.** When you detect work that
belongs to another skill, include a `### Suggested next skill` (or `### Suggested
next agent`) section at the end of your output. The dispatcher reads this and decides
whether to chain.

**As Wiki Ingest, you might suggest:**

- **`/wiki-audit`** — when you notice orphans, broken links, duplicates, or
  oversized pages near the pages you touched.
- **`/connector`** (or the **connector** agent) — when you created pages that clearly
  relate to existing notes but you didn't have budget to add all the links.
- **The handing-off capture skill** — when an `inbox/` item was ambiguous, partial,
  or low-confidence, so you routed it to `_contradictions.md` instead of compiling.
  Tell them what is blocked and what extra context would unblock it.
- **The user, via `_contradictions.md`** — for any merge/claim you could not resolve
  with confidence. Suggest a `/wiki-audit` follow-up to resolve it later.

A clean compile needs no suggestion — the page itself is the record.

For full dispatcher semantics (skill-first routing, call chains, max depth), see
`references/agent-orchestration.md`.

---

## Wiki Root & Path Convention

The Wiki root is the literal path `references/wiki/` (a fixed source-tree location
that ships with the Crew). If the directory does not exist, stop and tell the user —
do not invent a location.

All paths below are relative to the Wiki root.

---

## Inputs

Accept any one of the following. Detect from the request, or let the user pass it explicitly:

1. **File path** — a vault note, an `inbox/` capture, an email export, or any Markdown/text
   file. Read it as-is. Leave the original untouched.
2. **Inline text** — raw text pasted in chat (a quote, a decision, a fact, a thread).
3. **Structured payload** — `entities` + `relations` handed off by a capture skill
   (e.g., `/email-triage`). Example:

   ```yaml
   source: "[[{{inbox}}/2026-06-25 — Email — Marco re pricing.md]]"
   entities:
     - {kind: person, name: "Marco Rossi", alias: ["Marco"]}
     - {kind: project, name: "Q3 Pricing Revision"}
   relations:
     - {from: "Marco Rossi", to: "Q3 Pricing Revision", type: "raised objection to"}
   claims:
     - "Marco objected to the 12% increase; proposed 8% phased over two quarters."
   dates: ["2026-06-25"]
   ```

When given a file path, the **raw capture stays unchanged** in `inbox/`. Wiki compilation
is always a separate second step that writes linked summary pages and points back at the
raw source.

---

## Modes

### Mode 1: Standard Ingest (default)
Compile one input into patch-style updates on existing or new pages, then ask the user to
confirm before writing. Structured payloads (the third input type) skip the extraction
step and go straight to matching against existing pages — same workflow, no different
output shape.

### Mode 2: Dry-Run (default for the first compiles on a new installation, and on request)
Propose the diff **without writing anything**. Write the proposed patches to
`_contradictions.md` (or a `inbox/_staging-{{timestamp}}.md` file) for human review. Use
this whenever confidence is low, the affected subgraph is large, or the user has not yet
trusted automatic writes.

### Mode 3: Batch Inbox Sweep
Process every file in `inbox/` in age order (oldest first), one at a time, each through the
Standard or Dry-Run workflow. Stop at the first item that needs human review.

---

## Ingest Workflow (every mode)

### Step 1 — Read the input and the index
Read the input fully. Read `index.md` to learn the categories, naming, and frontmatter
rules. **Do not load the whole Wiki.**

### Step 2 — Extract candidates
Identify in the input:
- **Concepts** (durable ideas, definitions, mental models) → `concepts/`
- **Projects** (active/past efforts, goals, decisions, status) → `projects/`
- **People / entities** (contacts, orgs, teams) → `people/`
- **Decisions, claims, dates, and links** to other pages.

### Step 3 — Load only the relevant subgraph
For each candidate, check if a page already exists (by filename and by `aliases`). Read
**only** the directly relevant existing pages. Follow `[[wikilinks]]` on demand when a
candidate clearly relates to a named page. Do not preload the rest of the Wiki.

### Step 4 — Produce patch-style updates, not rewrites
For each affected page, emit the smallest change that records the new fact:
- **Insertion** — add a line, a bullet, a `## Decision` subsection.
- **Edit** — change a specific value (e.g., a status, a date) in place.
- **Link addition** — add a `[[wikilink]]` to a related page.

Never regenerate a page from scratch. Never reorder or reword existing prose to "improve"
it. If a page does not exist, create it from the template in *Page Templates*.

### Step 5 — Preserve provenance on every change
Every new or edited page **must**:
- List at least one source in `sources:` (the input file, `inbox/` capture, email, or URL).
- Update the `updated:` timestamp.
- Where useful, add a one-line `> From [[source]] — {{what changed}}` note near the edit.

A claim with no source is a draft — route it to `_contradictions.md`, do not compile it.

### Step 6 — Snapshot before writing
Before any write (including new files), copy the **current** version of each affected page
to `.history/{{page-path}}.{{YYYYMMDD-HHMMSS}}.md` (preserving subfolders). For a brand-new
page, there is no prior version to snapshot — record a `.history` stub noting "created" so
the page's birth is reversible/traceable too.

### Step 7 — Route uncertainty to the review queue
Send to `_contradictions.md` (never silently resolve):
- **Ambiguous merges** — two pages might be the same concept/person but you are not sure.
- **Low-confidence claims** — a fact with weak or single sourcing, or an inferred relation.
- **Contradictions** — the new input conflicts with an existing page.
- **Destructive edits** — anything that would remove or overwrite existing content.

Use the entry format already documented at the top of `_contradictions.md`.

Only **high-confidence, additive, well-sourced** changes are written directly.

### Step 8 — Confirm and write
Present the proposed patches (and any review items) to the user as a single batch. On
approval, in this order: **snapshot the current pages to `.history/` first (Step 6), then
write the patches**, then update `index.md` category indexes (newest-first) if pages were
created, and leave a message for the relevant skill/agent if a review item is blocking.
The snapshot must always precede the live-page change — that ordering is what makes the
update reversible. In Dry-Run, stop after presenting — write nothing but the staging
file.

---

## Page Templates

Follow the frontmatter spec in `index.md` (*Page Conventions*). Skeletons:

```markdown
---
type: wiki/concept
title: "{{Concept Name}}"
aliases: ["{{alternate spellings}}"]
updated: {{YYYY-MM-DD HH:MM}}
sources: ["[[sources/...]]"]
status: active
---

# {{Concept Name}}

{{One-paragraph definition / mental model.}}

## Related
- [[other-concept]]
```

```markdown
---
type: wiki/project
title: "{{Project Name}}"
aliases: []
updated: {{YYYY-MM-DD HH:MM}}
sources: ["[[sources/...]]"]
status: active   # active | stale | archived
---

# {{Project Name}}

**Goal**: {{…}}

## Decisions
- {{YYYY-MM-DD}} — {{decision}} — from [[source]]

## Status
{{current state}}
```

`wiki/person` and `wiki/source` follow the same shape (a person page records role/context +
links; a source page is a one-per-source summary that the other pages cite).

A patch on an existing page does **not** re-emit the frontmatter template — it edits the
page in place and only bumps `updated:` (and `sources:` if a new source applies).

---

## Snapshot & Rollback

- Snapshots live in `.history/` and are named `{{page-path}}.{{YYYYMMDD-HHMMSS}}.md`.
- To roll back a page, copy the most recent `.history` snapshot before a given timestamp
  back over the live page (the `/wiki-audit` skill automates this).
- Snapshots are the audit trail — never edit or delete them as part of a normal ingest.

---

## Contradiction Handling

When Step 7 routes an item, append it to the **top** of `_contradictions.md` using the
`[open]` entry format defined there (surfaced-by, pages involved, conflict, options,
recommendation, impact). Do **not** also write the conflicting content into the page —
the page stays as it was until a human resolves the item.

Marking resolved is a human action (or `/wiki-audit`): change `[open]` to `[resolved]`
and add a `**Resolution**:` line.

---

## Context Budget

Reserve full-Wiki reading for `/wiki-audit`. For ingest, stay within: the input +
`index.md` + the directly relevant existing pages + the pages reached by following one
hop of `[[wikilinks]]`. If you find yourself wanting to load more, you are probably doing
a synthesis — that belongs in `/wiki-audit`, not here.

---

## Output to the User

After a run, report concisely:

```
Wiki Ingest — {{date}}

Input: {{file / inline / payload}}
Mode: {{Standard | Dry-Run | Batch}}

Patches proposed ({{N}}):
- {{edit | insert | link | create}}  {{page}}  — {{one-line summary}}

Routed to review ({{N}}):
- [open] {{short title}} — {{why}}  →  _contradictions.md

Snapshots written: {{N}}   (in .history/)
Index updated: {{yes/no}}
```

Ask for batch confirmation before writing (unless Dry-Run, which writes only the staging file).
