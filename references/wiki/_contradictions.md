---
title: Wiki Contradiction & Review Queue
type: wiki-review-queue
updated: 2026-06-25
---

# Wiki Contradictions & Review Queue

Human-review queue for ambiguous merges, low-confidence claims, and
contradictions surfaced by `/wiki-ingest`. New items are appended at the top.
Do **not** silently resolve these — that is the whole point of this file.

**Entry format:**

```markdown
## [open] [YYYY-MM-DD HH:MM] — {{short title}}
**Surfaced by**: {{agent / skill}}
**Pages involved**: [[page-a]], [[page-b]]
**Source(s)**: [[source-note]]

**Conflict**: {{what contradicts what, concretely}}

**Options**:
- A: {{option}} — evidence: {{…}}
- B: {{option}} — evidence: {{…}}

**Recommended**: {{A/B/none}} — {{why, or "needs human judgement"}}

**Impact if unresolved**: {{what the Wiki currently says / omits}}
```

Mark resolved by changing `[open]` to `[resolved]` and adding a `**Resolution**:` line.

---

*(No items yet.)*
