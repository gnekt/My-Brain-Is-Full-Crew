# Codex-First Migration Design Rule

Date: 2026-04-09
Status: Approved baseline
Product owner: pigo

## Goal

Rewrite this project from Claude-first to Codex-first while preserving the product shape: a local workspace system that installs runtime assets into the user's vault or working directory and exposes a central dispatcher plus two execution layers, `agents` and `skills`.

This is not a compatibility patch. It is a host-platform rewrite.

## Hard Decisions

These decisions are fixed unless pigo explicitly changes them later.

1. The new product is `Codex-only`.
2. Claude compatibility is not a delivery goal.
3. The primary runtime model is `Codex CLI workspace mode`.
4. The system keeps a `central dispatcher` as the main entrypoint.
5. The system keeps both `agents` and `skills` as first-class concepts.
6. Installation still materializes runtime files into the user's workspace.
7. The installed runtime root becomes `.codex/`.
8. The migration target includes all `8 core agents`.
9. The migration target also includes all `13 skills`.
10. `Postman` external integrations are out of scope for this migration.

## Required Product Shape

The Codex-first version must preserve these user-facing properties:

- The user interacts through one main entrypoint instead of manually selecting internal units.
- Dispatch logic decides whether the request should go to a skill or an agent.
- Installed runtime assets live in the user's workspace, not only inside this repo.
- The repo remains the source of truth, and installer/updater scripts push runtime assets into the workspace.
- Agents remain reactive, focused units.
- Skills remain longer, guided, multi-step flows.

## Scope of Functional Parity

Functional parity means:

- Each of the 8 agents must remain present in the Codex-first system.
- Each of the 13 skills must remain present in the Codex-first system.
- Behavior may be reimplemented, but capability loss should be treated as a defect unless explicitly accepted by pigo.
- File layout, wording, and internal mechanics may change when needed for Codex, but the product experience should still feel like the same system.

Functional parity does not mean:

- Preserving Claude-specific files, naming, or plugin mechanisms.
- Preserving Claude-only hooks, manifests, or runtime assumptions.
- Preserving external service integrations that were explicitly excluded.

## Explicit Non-Goals

These items are not part of the current migration target:

- Gmail integration
- Google Calendar integration
- Hey CLI integration
- MCP fallback for Postman
- Maintaining `.claude/` runtime compatibility
- Maintaining `CLAUDE.md` as the production dispatcher entrypoint

## Migration Principles

### 1. Codex-first, not Claude-shaped emulation

When Claude-specific structures block good Codex design, prefer native Codex execution patterns over mechanical one-to-one copying.

### 2. Preserve product semantics before file semantics

What matters most is preserving:
- dispatcher behavior
- agent vs skill separation
- installed runtime model
- user workflow

It is acceptable to rename, relocate, or redesign internal files to achieve that in Codex.

### 3. Source-of-truth repo, generated workspace runtime

This repo remains the authoring source. The installed `.codex/` tree in the user workspace is a deployed runtime artifact produced by installer/updater flows.

### 4. Rebuild the runtime contract explicitly

Anything currently implied by Claude conventions must be made explicit for Codex:
- dispatcher entrypoint
- runtime directory layout
- installed references
- hooks/settings behavior
- invocation model for agents and skills

### 5. Avoid half-migration states in product design

New design work should not assume long-term coexistence of `.claude/` and `.codex/` as equal production runtimes. Temporary migration helpers are acceptable, but the target architecture is single-host and Codex-only.

## Required Architecture Outcomes

The final Codex-first architecture must define:

1. What file acts as the top-level dispatcher rule source.
2. How `.codex/agents/`, `.codex/skills/`, and `.codex/references/` are organized.
3. How installer and updater scripts deploy runtime assets into `.codex/`.
4. How hooks or equivalent protections work in a Codex environment.
5. How skill-first vs agent-second routing is represented under Codex.
6. How repo docs teach users to run the system entirely through Codex.

## Acceptance Criteria For Design Compliance

Any implementation is compliant only if it satisfies all of the following:

- No production path depends on `CLAUDE.md`.
- No production path depends on `.claude/` runtime directories.
- The runtime installed into the workspace is `.codex/`.
- Dispatcher logic remains central and user-facing.
- Both `agents` and `skills` remain separately modeled.
- The eight core agents are represented in the new runtime.
- The thirteen skills are represented in the new runtime.
- Postman external integrations remain excluded unless pigo reopens scope.
- Repo documentation describes Codex as the primary and only supported host.

## Delivery Priorities

When tradeoffs are required, prioritize in this order:

1. Dispatcher correctness under Codex
2. Runtime installation and update into `.codex/`
3. Agent and skill migration fidelity
4. Documentation consistency
5. Cleanup of legacy Claude artifacts

## Working Rules For Future Changes

- Do not add new Claude-specific runtime behavior.
- Do not deepen coupling to `.claude/`, `CLAUDE.md`, or Claude plugin assumptions.
- Any new runtime helper, script, or function added during migration must also be recorded in `func.md`.
- If a design choice weakens the central dispatcher, agent/skill split, or installed-runtime model, it must be treated as a design regression and explicitly approved by pigo.

## Approval Note

This document records the design requirements already confirmed by pigo during the Codex migration clarification session.

Implementation may proceed against this rule set.
