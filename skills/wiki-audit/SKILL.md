---
name: wiki-audit
description: >
  Periodically lint, audit, and repair the LLM Wiki (`references/wiki/`)
  graph, and roll back unwanted changes. The Wiki's quality guardian: walks the
  whole graph for orphans, broken wikilinks, duplicate concepts, stale project
  status, unsupported claims, source/page contradictions, and oversized pages,
  then applies conservative patch-style fixes — each preceded by a `.history/`
  snapshot and recorded in a machine-readable lint diff so every change is
  reversible. Use when the user (or the Librarian on a schedule) wants Wiki
  health, cleanup, or rollback. Triggers: "audit the wiki", "wiki audit", "lint
  the wiki", "check wiki health", "wiki health", "clean the wiki", "fix the
  wiki", "are there wiki orphans?", "broken wiki links", "wiki duplicates",
  "stale wiki projects", "resolve wiki contradictions", "rollback the wiki",
  "undo wiki change", "revert a wiki page", "split this wiki page", "what's
  wrong with the wiki", "audita il wiki", "controlla il wiki", "pulisci il
  wiki", "verifica il wiki", "audite le wiki", "vérifie le wiki", "nettoie le
  wiki", "maintenance du wiki", "audita el wiki", "revisa el wiki", "limpia el
  wiki", "auditiere das Wiki", "Wiki prüfen", "Wiki aufräumen", "audita o wiki",
  "verifica o wiki", "limpa o wiki", or when the Librarian runs periodic graph
  hygiene or resolves items in `_contradictions.md`.
---

# Wiki Audit — Graph Hygiene, Lint & Rollback

Always respond to the user in their language. Match the language the user writes in.

The Wiki Audit skill is one of the **only two** paths that write to
`references/wiki/` (the other being `/wiki-ingest`). It is the Wiki's
quality guardian: it reads the **whole graph** (it is exempt from the per-agent
context budget — see `context-injection.md`), finds decay, and applies
**conservative, patch-style** repairs — each snapshotted first and logged in a
machine-readable lint diff so nothing is ever silently lost.

> **Single most important rule (same as ingest):** prefer leaving the Wiki
> untouched over rewriting accurate prior knowledge. Audit *detects* far more
> than it *writes*. When a fix is not high-confidence, route it to
> `_contradictions.md` for a human — do not auto-resolve.

This skill implements the lint / audit / rollback layer the source proposal
omitted (PLAN §3.5 / §4-step5). It complements `/wiki-ingest` (which compiles)
and the `Meta/agent-messages.md` short-term board (which it does not replace).

---

## Wiki Root & Path Convention

- **Canonical root** (this repo, flat layout): `references/wiki/`
- **Other layout variant** (`.codex/`-prefixed canonical): `.codex/references/wiki/`

The structure and rules are identical either way; only the prefix differs. Use
whichever root exists. If neither exists, stop and tell the user — do not invent
a location.

All paths below are relative to the Wiki root.

---

## User Profile & Message Board

Before auditing anything:

1. Read `Meta/user-profile.md` to understand the user's context, preferences,
   and active projects. Use it to judge "stale" thresholds and to avoid
   flagging reference material as stale.
2. Open `Meta/agent-messages.md` and resolve any `⏳` / `[pending]` messages
   addressed `→ TO: Wiki Audit` (or `→ TO: Librarian`) before starting.

For message format and routing, see `.claude/references/inter-agent-messaging.md`
(or `references/inter-agent-messaging.md` on the flat layout).

---

## Inter-Agent Messaging Protocol

### Step 0A: Check Your Messages First
Resolve pending messages addressed to Wiki Audit / Librarian before each run
(typically: `/wiki-ingest` or a capture agent flagged orphans / broken links /
duplicates / oversized pages near pages it touched, and is waiting for cleanup).

### Step 0B: Leave Messages When You Hand Off or Halt
**As Wiki Audit, you might write to:**

- **Architect** → for structural decay that is not content-level: naming-
  convention drift, category folders missing or misused, taxonomy problems,
  pages whose `type:` does not match their folder. The Architect owns structure;
  you detect, it resolves.
- **Connector** → clusters of orphan pages that should be linked but have no
  obvious home yet; hand the cluster over for bridge/constellation work rather
  than forcing links yourself.
- **Sorter** → pages filed in the wrong category folder for their `type:`.
- **Seeker** → content-level reconciliation between two pages that genuinely
  conflict but neither is clearly wrong (deeper than a lint auto-fix).
- **Scribe** → pages missing required frontmatter or structurally malformed
  (reformatting is Scribe's job, not the linter's).
- **`/wiki-ingest`** → when audit reveals a source/page contradiction that needs
  re-compilation against the raw capture in `inbox/` (ingest owns the compile
  path; audit only patches in place).
- **The user, via `_contradictions.md`** → any finding you cannot fix with high
  confidence (see *Contradiction Resolution*). Notify on the message board only
  when a routed item is blocking a downstream task.

Notify via `Meta/agent-messages.md` **only** when something needs someone's
attention. A clean audit needs no broadcast — the lint diff and health report
are the record.

---

## Modes

### Mode 1: Quick Lint
Fast scan for the cheap, mechanical defects only: broken wikilinks, missing
required frontmatter, empty `sources:`, oversized pages, naming violations. No
semantic checks, no writes — proposes fixes for batch confirm. Use for "quick
wiki check".

### Mode 2: Full Audit (default)
The comprehensive lint: every check in *Lint Checks* below, a health report,
and conservative patch proposals. May write (snapshot + patch + lint diff) only
on batch confirmation.

### Mode 3: Rollback
Restore one or more pages to a prior `.history/` snapshot. Always snapshots the
*current* version first (so the rollback itself is reversible), then restores.
Never deletes a snapshot. See *Rollback*.

### Mode 4: Resolve Contradictions
Work through `_contradictions.md`: for each `[open]` item, apply a high-
confidence resolution (snapshot → patch → mark `[resolved]` with a
**Resolution**:` line), or leave it `[open]` / escalate to the user. Never
silently resolve a low-confidence item.

### Mode 5: Dry-Run (default for the first audit on a new installation, and on request)
Run the full lint, write the findings to the lint diff and/or
`_contradictions.md`, but **write nothing** to live pages. Use whenever
confidence is low, the graph is large, or automatic writes are not yet trusted
(PLAN §4-step9).

---

## Audit Workflow (every mode)

### Step 1 — Read the index, then the whole graph
Read `index.md` for categories, naming, and frontmatter rules. **Unlike
`/wiki-ingest`, you may read the entire Wiki** — coherence-critical work is the
one place full-context is allowed (`context-injection.md`). Read
`_contradictions.md` too. Skip `inbox/` raw captures (they are not compiled
pages) and `.history/` (snapshots, not content).

### Step 2 — Run the lint checks
Run every check in *Lint Checks* against every compiled page. Record each
finding in the lint diff (see *Snapshot, Lint Diff & Rollback*).

### Step 3 — Snapshot before any write
Before changing any page, copy its **current** version to
`.history/{{page-path}}.{{YYYYMMDD-HHMMSS}}.md` (same naming convention as
`/wiki-ingest`). This is what makes the change reversible. No snapshot, no
write — even for a one-line status fix.

### Step 4 — Propose patch-style fixes
For each high-confidence finding, emit the smallest change that fixes it
(insertion / edit / link addition / rename / split), exactly as `/wiki-ingest`
would. Never regenerate a page. Group all proposed patches into one batch.

### Step 5 — Write the machine-readable lint diff
On every run (including Dry-Run), write a lint diff to
`.history/_lint/{{YYYYMMDD-HHMMSS}}--wiki-audit.md` recording findings, patches
applied, items routed to review, and snapshots written (format in *Snapshot,
Lint Diff & Rollback*). This is the machine-readable audit trail; the
snapshots are the reversibility. The two together are the design from PLAN §3.5.

### Step 6 — Resolve or route contradictions
For each contradiction: if high-confidence → snapshot, patch, mark resolved
(Mode 4). If not → append to the **top** of `_contradictions.md` as `[open]`
using its entry format, and do **not** touch the live page. Never silently
resolve.

### Step 7 — Emit the health report
Produce the report in *Output to the User* and (optionally) save a copy at
`.history/_lint/{{YYYYMMDD-HHMMSS}}--health-report.md` so trends can be tracked
across runs.

### Step 8 — Confirm and write
Present the lint summary + proposed patches + review items as a single batch.
On approval, in this order: **snapshot the affected pages to `.history/` first
(Step 3), then apply the patches, then write the lint diff (Step 5), then
update `index.md` category indexes if pages were created/renamed/split.** The
snapshot must always precede the live-page change. In Dry-Run, stop after
presenting — write nothing but the lint diff / staging file.

---

## Lint Checks

Run all of these in a Full Audit; the starred (★) ones also run in Quick Lint.

1. **★ Broken wikilinks** — `[[X]]` (or `[[X|alias]]`) whose target resolves to
   no file, accounting for `aliases:`. Fix: re-point to the correct page, or
   route to review if the target was deleted.
2. **Orphan pages** — compiled pages with **zero incoming** `[[wikilinks]]`.
   Route to Connector if it should be linked; otherwise leave (some pages are
   legitimately leaf nodes).
3. **Duplicate concepts** — two pages describing the same thing (overlapping
   `aliases:`, near-identical titles, >70% content overlap). Never auto-merge —
   route to `_contradictions.md`; merging is a human/Seeker call.
4. **★ Stale project status** — `projects/` pages where `status: active` but
   `updated:` is older than the user's threshold (default 90 days; confirm
   against `Meta/user-profile.md`), or where prose describes completion but
   `status:` still says `active`. Fix high-confidence cases (flip to `stale`);
   route ambiguous ones.
5. **★ Unsupported claims** — any assertion on a page whose `sources:` is empty
   or whose specific claim has no nearby `> From [[source]]` provenance. Route
   to review (do not delete the claim); `/wiki-ingest` re-sources on re-compile.
6. **Source / page contradictions** — a compiled page diverges from the source
   it cites (e.g., page says "12%", `sources/` note says "8%"). Route to
   `_contradictions.md`; `/wiki-ingest` re-compiles from the raw capture.
7. **★ Oversized pages** — any page over ~300 lines (the `index.md` convention).
   Propose a split plan (which subsections become new pages + the wikilinks that
   replace them); apply only on confirmation. A split is a set of patches, not a
   rewrite — original prose is preserved verbatim, just relocated and linked.
   Each new sub-page has no prior version, so record a `.history` creation stub
   for it (same convention as `/wiki-ingest` for brand-new pages), so the split
   is fully traceable and reversible.
8. **★ Provenance hygiene** — missing/empty `updated:`, `sources:`, `title:`, or
   `type:`; `type:` not matching the page's folder. Auto-fix the mechanical ones
   (normalize `updated:` to `YYYY-MM-DD HH:MM`); route the semantic ones.
9. **★ Naming conventions** — non-`kebab-case.md` filenames; wikilinks that
   should be `[[wikilinks]]` but are markdown links. Propose renames (renames
   snapshot first and update inbound links).

> Thresholds (90-day stale, 300-line split, >70% overlap) are defaults — state
> them in the report and defer to `Meta/user-profile.md` or the user when they
> conflict with context. Reference material is exempt from staleness.

---

## Snapshot, Lint Diff & Rollback

### Snapshots (reversibility)
Identical convention to `/wiki-ingest`: before changing a page, copy its current
version to `.history/{{page-path}}.{{YYYYMMDD-HHMMSS}}.md`, preserving subfolders.
Snapshots are the audit trail — **never edit or delete them** as part of a normal
audit (a rollback *restores from* them; it does not consume them).

### Lint diff (machine-readable audit trail)
Every run writes `.history/_lint/{{YYYYMMDD-HHMMSS}}--wiki-audit.md`:

```markdown
---
type: wiki/audit-log
run: {{YYYYMMDD-HHMMSS}}
agent: wiki-audit
mode: {{Quick Lint | Full Audit | Rollback | Resolve Contradictions | Dry-Run}}
pages_scanned: {{N}}
findings: {{N}}
patches_applied: {{N}}
routed_to_review: {{N}}
snapshots_written: {{N}}
---

# Wiki Audit Log — {{run}}

## Findings
- ! orphan         | `people/marco-rossi.md`                | zero incoming links
- ! broken-link    | `concepts/llm-wiki-pattern.md`        | `[[foo]]` → no file
- ! duplicate      | `concepts/rag.md` ~ `concepts/retrieval.md` | alias overlap
- ! stale          | `projects/q3-pricing.md`              | status:active, updated 2026-01-10 (136d)
- ! unsourced      | `concepts/active-learning.md`         | "X is Y" — empty sources:
- ! contradiction  | `projects/q3-pricing.md` ⇄ `sources/2026-06-25-email-marco.md` | 12% vs 8%
- ! oversized      | `concepts/llm-wiki-pattern.md`        | 412 lines (>300)
- ! naming         | `concepts/LLM Wiki.md`                | not kebab-case

## Patches Applied   (Dry-Run: none — proposed only)
- + edit   `projects/q3-pricing.md`        status active→stale   (snap `projects/q3-pricing.md.20260625-014500.md`)
- + rename `concepts/LLM Wiki.md` → `concepts/llm-wiki.md`        (snap + 3 inbound links updated)

## Routed to Review
- → _contradictions.md  [open]  {{short title}} — {{why}}
```

The pipe-delimited finding lines are deliberately machine-parseable (`! type |
target | detail`) while still human-skimmable. This is the "machine-readable diff
to `.history/`" PLAN §3.5 requires so updates are reversible and reviewable.

### Rollback (Mode 3)
To roll a page back to before a given timestamp (or "undo the last change"):

1. **Snapshot the current version first** — a rollback must itself be reversible.
2. List `.history/{{page-path}}.*.md`, pick the newest snapshot whose timestamp
   is **before** the target time (default: the snapshot immediately prior to the
   change being undone).
3. Restore it over the live page.
4. Log the rollback in a lint diff (`mode: Rollback`, note the restored snapshot
   in *Patches Applied*).

Rollback restores content; it does **not** delete the snapshots on either side.
For a graph-wide revert ("undo everything the last audit changed"), restore from
that run's lint diff: every *Patches Applied* line names the snapshot to restore.

---

## Contradiction Resolution (Mode 4)

Walk `_contradictions.md` top-to-bottom. For each `[open]` item:

- **High-confidence resolution** (one option is clearly correct and sourced) →
  snapshot the affected page(s), apply the minimal patch, then change `[open]` to
  `[resolved]` and add a `**Resolution**:` line naming the snapshot. This is the
  only place audit may *change* a contradiction rather than just route it.
- **Low-confidence / needs judgement** → leave `[open]`. Optionally tighten the
  *Recommended* line or add evidence; do not resolve.

Never silently drop or overwrite an item. The whole point of
`_contradictions.md` is that ambiguous merges wait for a human.

---

## Context Budget

Wiki Audit is **exempt** from the per-agent budget — it is one of the two
coherence-critical full-graph readers (`context-injection.md`). Everyone else
treats their budget as a hard ceiling. As a side effect of reading the whole
graph, audit can also **flag agents whose observed Wiki reads chronically exceed
their budget**, so budgets can be tuned from real usage (see the *Consistency &
Maintenance* note in `context-injection.md`).

---

## Output to the User

After a run, report concisely:

```
Wiki Audit — {{date}}
Mode: {{Quick Lint | Full Audit | Rollback | Resolve Contradictions | Dry-Run}}

Pages scanned: {{N}}
Findings: {{N}}
  - {{orphan / broken-link / duplicate / stale / unsourced / contradiction / oversized / naming}} ×{{N}}

Patches proposed ({{N}}):  {{applied: {{N}} in non-dry-run}}
  - {{edit | insert | link | rename | split}}  {{page}}  — {{one-line summary}}

Routed to review ({{N}}):
  - [open] {{short title}} — {{why}}  →  _contradictions.md

Snapshots written: {{N}}   (in .history/)
Lint diff: .history/_lint/{{YYYYMMDD-HHMMSS}}--wiki-audit.md
Index updated: {{yes/no}}
```

Ask for batch confirmation before writing (unless Dry-Run, which writes only the
lint diff / staging file). For Rollback mode, state exactly which snapshot is
being restored and over what.

---

## Operating Principles

1. **Detect more than you write** — audit's value is the lint, not the edits.
   Default to proposing; write only high-confidence, snapshotted patches.
2. **Conservative by default** — when uncertain, route to `_contradictions.md`,
   do not write. Same rule as `/wiki-ingest`.
3. **Snapshot first, always** — no snapshot, no write. The snapshot precedes the
   live-page change; that ordering is what makes updates reversible.
4. **Patch, don't rewrite** — smallest change that fixes the defect. Existing
   prose is load-bearing until proven otherwise; a split relocates prose verbatim.
5. **Reversible & transparent** — every change is recorded in a machine-readable
   lint diff and backed by a snapshot; every rollback is itself snapshotted.
6. **Full-graph only here** — only `/wiki-audit` (and `/wiki-ingest` on its
   subgraph) may read broadly. Flag any other agent overstepping its budget.
7. **Never delete** — snapshots, old lint diffs, and `_contradictions.md` history
   are the audit trail. Rollback restores; it does not destroy.
