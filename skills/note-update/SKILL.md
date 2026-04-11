---
name: note-update
description: >
  Compound workflow for Obsidian note formalization. Converts 00-Inbox insight notes
  into formal Learning notes, deduplicates, adds wikilinks and MOC entries, reruns
  Learning orphan audit, updates STATUS, then performs git pull --rebase, commit, push.
  Triggers:
  EN: "note-update", "formalize inbox notes", "run note update", "inbox to learning with push".
  ZH: "note-update", "整理筆記並推送", "正式化 inbox 筆記", "跑 orphan audit 然後 push".
---

# Note Update — Compounded Note Maintenance + Git Sync

Always respond to the user in their language. Match the language the user writes in.

This skill is the compounded operational playbook for PigoVault note maintenance.  
When the user says `note-update`, execute this end-to-end workflow directly.

## Scope

- Vault root: `E:/obsidian/PigoVault`
- Primary source folder: `00-Inbox/`
- Primary destination root: `Learning/`
- Audit target: `Learning/INDEX_Orphans.md`

## Preconditions

1. Confirm `E:/obsidian/PigoVault/.git` exists.
2. Confirm `00-Inbox/` exists.
3. If either is missing, stop and report the missing path.

## Exclusion Rules

Do not convert these into formal notes:
- `00-Inbox/index.md`
- `00-Inbox/*Welcome*.md`
- obvious intro/landing files

## Workflow

### Phase 1: Scan Inbox Candidates

1. List markdown files in `00-Inbox/`.
2. Filter out excluded files.
3. Keep only substantive notes (not empty shells).

### Phase 2: Deduplicate

Treat notes as duplicates when one of the following is true:
- same `source_url`
- highly similar title slug
- one file is clearly a draft/input version of another

Canonical selection priority:
1. richer content length
2. complete frontmatter (`source`, `source_url`, `processed`)
3. higher link quality and clearer structure

Action:
- keep canonical note
- delete duplicate note
- preserve information by merging missing unique lines before deletion

### Phase 3: Formalize and Move

Move canonical notes from `00-Inbox/` to a correct `Learning/` domain.

Routing rules:
- `source/platform = twitter/x` -> `Learning/twitter/`
- `source/platform = notion` -> `Learning/notion-knowledge/`
- `source/platform = article/web` -> `Learning/articles/`
- `source/platform = repo/github` -> `Learning/repos/`
- unclear source -> `Learning/articles/` as temporary default

### Phase 4: Link and MOC Update

For each moved note:
1. ensure a `## 關聯筆記（Wikilink）` section exists
2. include at least:
   - `[[Learning/index|Learning Landing]]`
   - destination index link (for example `[[Learning/twitter/index|Twitter Index]]`)
3. add 3-5 high-relevance wikilinks when possible

Then update:
- `00-Inbox/index.md` (mark note as archived/moved)
- destination domain `index.md`
- any directly affected local MOC page

### Phase 5: Orphan Audit (Learning)

1. Recompute orphan notes under `Learning/` using internal wikilink inbound count.
2. Exclude:
   - `Learning/INDEX_Orphans.md`
   - `*/index.md`
   - `*/log.md`
   - `Learning/status/*`
3. Rewrite `Learning/INDEX_Orphans.md` with latest result.
4. If orphan count is zero, write explicit zero-state report.

### Phase 6: STATUS Update

Create/update a status file:
- path: `Learning/status/STATUS_<YYYY-MM-DD>_note_update.md`
- include:
  - changed files summary
  - dedupe decisions
  - orphan audit metrics
  - risks/limitations
  - next-step suggestion

Also add the new status page into:
- `Learning/status/index.md`

### Phase 7: Git Sync

Run in order:
1. `git -C E:/obsidian/PigoVault pull --rebase --autostash origin main`
2. `git -C E:/obsidian/PigoVault add -A`
3. `git -C E:/obsidian/PigoVault commit -m "chore: note-update formalization and orphan audit"`
4. `git -C E:/obsidian/PigoVault push origin main`

If `index.lock` exists:
- remove stale lock only if no active git process is running
- retry commit

If rebase conflict occurs:
- stop
- report exact conflicted files
- do not force push

## Output Contract

Report with four sections:
1. `核心摘要`
2. `詳細分析`
3. `關鍵資料`
4. `風險與限制`

Always include:
- moved count
- deleted duplicate count
- orphan count before/after
- commit hash and push result

