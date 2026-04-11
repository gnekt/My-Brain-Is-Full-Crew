# Codex Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Claude runtime foundation with a Codex runtime foundation for dispatcher entry, workspace installation, updater behavior, and local runtime protections.

**Architecture:** Keep the repo as the source of truth and deploy runtime assets into the user workspace, but switch the installed runtime from `.claude/` plus `CLAUDE.md` to `.codex/` plus `AGENTS.md`. Preserve the existing agents/skills/references source directories for now while changing the deployed runtime contract and Codex entrypoint.

**Tech Stack:** Bash, Markdown, Git, Codex workspace instructions

---

### Task 1: Add a failing installer smoke test

**Files:**
- Create: `tests/install_runtime_smoke.sh`
- Modify: `.gitignore`

- [ ] **Step 1: Write the failing test**

Create a shell smoke test that:
- copies the repo to a temporary directory
- creates a sibling fake vault directory
- runs `scripts/launchme.sh` non-interactively
- asserts `.codex/agents`, `.codex/skills`, `.codex/references`, `.codex/hooks`, `.codex/settings.json`, and workspace-root `AGENTS.md` exist
- asserts workspace-root `CLAUDE.md` is not installed

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install_runtime_smoke.sh`

Expected: FAIL because the current installer still writes `.claude/` and `CLAUDE.md`.

### Task 2: Introduce the Codex dispatcher entrypoint

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Write the dispatcher source file**

Create a Codex-focused root `AGENTS.md` that:
- declares this project as Codex-first and Codex-only
- routes through local runtime files under `.codex/`
- preserves skill-first, agent-second dispatch semantics
- stops depending on `CLAUDE.md`

- [ ] **Step 2: Verify source file exists and is readable**

Run: `test -f AGENTS.md && echo OK`

Expected: `OK`

### Task 3: Migrate installer and updater runtime targets

**Files:**
- Modify: `scripts/launchme.sh`
- Modify: `scripts/updateme.sh`

- [ ] **Step 1: Change runtime install targets**

Update scripts to deploy runtime assets into `.codex/agents`, `.codex/skills`, `.codex/references`, `.codex/hooks`, `.codex/settings.json`, and workspace-root `AGENTS.md`.

- [ ] **Step 2: Remove production dependence on `.claude/` and `CLAUDE.md`**

Replace installer and updater checks, prompts, copy paths, and summary output so the runtime contract is Codex-only.

- [ ] **Step 3: Run installer smoke test**

Run: `bash tests/install_runtime_smoke.sh`

Expected: PASS

### Task 4: Migrate runtime protections and settings

**Files:**
- Modify: `settings.json`
- Modify: `hooks/protect-system-files.sh`
- Modify: `hooks/validate-frontmatter.sh`
- Modify: `hooks/notify.sh`

- [ ] **Step 1: Update settings hook paths**

Point the installed runtime settings at `.codex/hooks/...`.

- [ ] **Step 2: Update hook logic and copy**

Replace `.claude` and `CLAUDE.md` assumptions with `.codex` and `AGENTS.md`, and make notification copy Codex-first.

- [ ] **Step 3: Re-run smoke test**

Run: `bash tests/install_runtime_smoke.sh`

Expected: PASS

### Task 5: Record new reusable runtime entrypoints

**Files:**
- Modify: `func.md`

- [ ] **Step 1: Update registry notes**

Record any newly introduced Codex-specific runtime entrypoints or helpers added during Tasks 2-4.

- [ ] **Step 2: Check git diff**

Run: `git diff -- func.md AGENTS.md scripts/launchme.sh scripts/updateme.sh settings.json hooks`

Expected: Codex runtime changes visible and no unrelated file drift.
