---
name: note-update
description: >
  Execute the compounded note maintenance workflow: formalize substantive notes from
  00-Inbox into Learning domains, deduplicate safely, update wikilinks and MOCs, rerun
  Learning orphan audit, update STATUS, then perform git pull/rebase + commit + push.
  Use when the user says "note-update", "整理筆記並推送", "正式化 inbox 筆記",
  "跑 orphan audit 然後 push", or asks to complete this full sequence end-to-end.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# Note-Update — Formalize, Link, Audit, and Push

Always respond to the user in their language. Match the language the user writes in.

This agent executes the full compounded maintenance flow for PigoVault notes.  
Default workspace target: `E:/obsidian/PigoVault`.

## Scope

- Source: `00-Inbox/`
- Destination: `Learning/*`
- Audit target: `Learning/INDEX_Orphans.md`
- Status target: `Learning/status/`

## Exclusion Rules

Do not formalize:
- `00-Inbox/index.md`
- `00-Inbox/*Welcome*.md`
- obvious intro/landing notes

## Workflow

### 1) Scan and Select Candidates

1. List markdown files in `00-Inbox/`.
2. Exclude intro/index files.
3. Keep substantive notes only.

### 2) Deduplicate

Prefer deterministic rules:
- same `source_url`
- draft/input variant of a richer canonical note

If duplicate confidence is low, do not delete automatically. Keep both and report.

### 3) Formalize and Move

Route by source:
- twitter/x -> `Learning/twitter/`
- notion -> `Learning/notion-knowledge/`
- article/web -> `Learning/articles/`
- repo/github -> `Learning/repos/`
- unknown -> `Learning/articles/` (temporary default)

### 4) Update Links and MOCs

For each formalized note:
- ensure `## 關聯筆記（Wikilink）` exists
- include:
  - `[[Learning/index|Learning Landing]]`
  - destination index link (for example `[[Learning/twitter/index|Twitter Index]]`)
- add 3-5 high-relevance links when possible

Then update:
- `00-Inbox/index.md` (mark archived/moved)
- destination `index.md`
- directly affected MOC files

### 5) Run Learning Orphan Audit

Recompute inbound links for `Learning/` notes, excluding:
- `Learning/INDEX_Orphans.md`
- `*/index.md`
- `*/log.md`
- `Learning/status/*`

Rewrite `Learning/INDEX_Orphans.md` with the latest count.

### 6) Update STATUS

Create/update `Learning/status/STATUS_<YYYY-MM-DD>_note_update.md` with:
- changed files
- dedupe decisions
- orphan metrics before/after
- risks and limitations
- next-step recommendation

Also append the new status link into `Learning/status/index.md`.

### 7) Git Sync (on user intent to sync)

Run:
1. `git pull --rebase --autostash origin main`
2. `git add -A`
3. `git commit -m "chore: note-update formalization and orphan audit"`
4. `git push origin main`

If `.git/index.lock` exists and no active git process is running, remove stale lock and retry.
If rebase conflicts occur, stop and report exact conflicted files. Do not force-push.

## Inter-Agent Coordination

When structural changes exceed note-maintenance scope (new area taxonomy, large architecture redesign), finish safe work and add:

```markdown
### Suggested next agent
- **Agent**: architect
- **Reason**: Structural update required beyond note-update scope
- **Context**: Exact folders/files and proposed target structure
```

