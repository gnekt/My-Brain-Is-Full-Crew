---
name: concept-hub-navigation
description: >
  Build canonical concept hubs and converge root navigation across an Obsidian vault.
  Creates or updates landing pages for root folders, adds canonical wrapper hubs for
  high-frequency concepts, tightens root index/MOC/entities scan, verifies navigation
  links, and records a STATUS file. Triggers:
  EN: "concept hub", "root navigation", "navigation cleanup", "folder landings", "canonical hub".
  ZH: "補 concept hub", "收斂 root navigation", "每個資料夾 landing", "導航整理".
---

# Concept Hub + Root Navigation

Always respond to the user in their language. Match the language the user writes in.

This skill is for navigation convergence, not content rewriting. Use it when the vault already has multiple content domains or old hub systems, but the user needs one stable navigation layer and canonical concept entry points.

## User Profile

Before starting, read `Meta/user-profile.md` if it exists.

## Risk-Tier Contract

- **Low-risk**: create or update landing pages, create canonical wrapper hubs, update root navigation files, update reports/status files, add aliases to existing landing pages when deterministic.
- **Medium-risk**: mass folder moves, renaming existing hub files, replacing existing topic systems, semantic taxonomy changes. Put these in a `Pending Approval Plan`.
- **High-risk**: vault-shape redesign, deleting large navigation systems, or changing ownership boundaries between content domains. Do not auto-execute.

## Goal

Produce a navigation layer where:

1. Every human-facing root folder has a clear landing page or is explicitly covered by a meta navigation note.
2. High-frequency concept targets have canonical wrappers if old hub filenames do not match the names people actually link to.
3. `index.md`, `MOC/Index.md`, and any full-vault entities/concepts scan point to the same navigation model.
4. Navigation files verify cleanly with no broken internal wikilinks.

## Workflow

### Phase 1: Baseline Scan

1. List root folders in the vault.
2. Check which folders already have `index.md` or `_index.md`.
3. Inspect current navigation files:
   - `index.md`
   - `MOC/Index.md`
   - `Meta/vault-structure.md`
   - any entities/concepts scan page if present
4. Identify high-frequency broken concept targets from a link scan.

### Phase 2: Coverage Model

Apply these rules:

- Human-facing root folders should expose `index.md` or `_index.md`.
- Hidden runtime folders such as `.claude`, `.codex`, `.obsidian`, `.venv` should usually be documented through a `Meta/` note instead of placing notes inside those system folders.
- If the vault already has old hubs like `Workflow-Index.md` but people link to `[[Workflow]]`, create a canonical wrapper hub rather than renaming the old file immediately.

### Phase 3: Landing Pages

For each root folder missing a landing page:

1. Create a minimal landing page with:
   - purpose
   - role in the vault
   - key entry points if they exist
   - short operating rule
2. Keep empty or lightly used folders concise.
3. Do not invent content just to fill a landing page.

Suggested root folders to inspect:
- `00-Inbox`
- `01-Projects`
- `02-Areas`
- `03-Resources`
- `04-Archive`
- `05-People`
- `06-Meetings`
- `07-Daily`
- `Learning`
- `article-notes`
- `Lumentum`
- `WorkNotes`
- `MOC`
- `Templates`
- `Meta`
- `CodexDocs`
- `docs`
- `graphify-out`

### Phase 4: Canonical Concept Wrappers

When a concept is heavily linked but the existing hub filename does not match the common target name:

1. Create a canonical wrapper note under a stable concept-hub zone such as `03-Resources/Concept-Hubs/`.
2. Name the file using the common target exactly, for example:
   - `Workflow.md`
   - `NotebookLM.md`
   - `Obsidian.md`
   - `Skills.md`
   - `OpenClaw.md`
3. The wrapper should:
   - define the concept briefly
   - link to the old canonical hub/index
   - link to nearby related concepts
   - link to the main content zones where the topic lives
4. Prefer wrappers over file renames unless the user explicitly approves a rename campaign.

### Phase 5: Root Navigation Convergence

Update these pages so they all reflect the same structure:

- `index.md`
- `MOC/Index.md`
- entities/concepts scan page if present
- `Meta/vault-structure.md`

Required convergence outcomes:

- the same folder model appears across all root navigation pages
- concept hubs are surfaced once in a stable section
- documentation/derived zones are clearly separated from core knowledge domains
- runtime internals are covered deliberately rather than accidentally omitted

### Phase 6: Verification

Run a navigation-focused verification pass:

1. Re-scan key navigation files for broken wikilinks.
2. Re-check the specific concept targets you intended to fix.
3. Confirm that the main root navigation files have zero broken links.
4. Record the before/after metrics if available.

### Phase 7: Status Update

Create or update a `STATUS_*.md` file containing:

- what was created or updated
- which concept hubs were added
- which folders gained landing pages
- verification results
- remaining risks or deferred work
- recommended next step

## Output Format

Use this structure when reporting back:

1. **核心摘要**
2. **詳細分析**
3. **關鍵資料**
4. **風險與限制**

## Suggested Follow-up

- Use `vault-audit` after this skill when the user wants a quality re-check.
- Use `deep-clean` after this skill when navigation is fixed but stale links, duplicates, and content drift still remain.
- Use `defrag` later for routine structural maintenance.
