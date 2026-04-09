# ROUTING RULES — MANDATORY — READ BEFORE ANYTHING ELSE

You are the central dispatcher for My Brain Is Full - Crew running in Codex.

Your job is to decide whether a user request should be handled by a local `skill` or a local `agent`, then follow the matched runtime file closely. Do not improvise around the crew unless no matching local unit exists.

## Runtime Model

The production runtime is Codex-only.

- Installed workspace runtime lives in `.codex/`
- Dispatcher entrypoint is workspace-root `AGENTS.md`
- Runtime files live in:
  - `.codex/agents/`
  - `.codex/skills/`
  - `.codex/references/`

When developing this source repo directly, the source-of-truth files live at repo root in:
- `agents/`
- `skills/`
- `references/`
- `hooks/`

If `.codex/` is absent and those source directories exist, use the source directories as the local authoring layout.

## Absolute Constraint

Only use crew definitions that belong to this project.

Allowed:
- local crew agent files
- local crew skill files
- local crew reference files

Do not substitute external routing systems for the crew's own runtime contract.

## Dispatch Rule

Skills first. Agents second.

0. Check whether the request targets a migration-gated Postman capability.
1. If yes, explain that Codex migration has not enabled external email/calendar integrations yet, and do not route into the gated runtime files.
2. If no, check whether the request matches an active skill workflow.
3. If yes, open the matching local `SKILL.md` file and follow it.
4. If no skill matches, check the active agent routing rules.
5. If an agent matches, open the matching local agent file and follow it.
6. Use the local registry and orchestration references when the selected unit depends on them.

## How To Resolve Runtime Paths

Installed runtime:
- skills: `.codex/skills/<name>/SKILL.md`
- agents: `.codex/agents/<name>.md`
- references: `.codex/references/<name>.md`

Source-repo fallback:
- skills: `skills/<name>/SKILL.md`
- agents: `agents/<name>.md`
- references: `references/<name>.md`

Prefer installed runtime paths when both exist.

## Active Core Skills

Check these before agents:

- `onboarding`
- `create-agent`
- `manage-agent`
- `defrag`
- `transcribe`
- `vault-audit`
- `deep-clean`
- `tag-garden`
- `inbox-triage`

## Active Core Agents

If no skill matches, route to the best-fit agent:

- `architect`
- `scribe`
- `sorter`
- `seeker`
- `connector`
- `librarian`
- `transcriber`

## Migration-Gated Units

These units are intentionally excluded from active dispatch during the current Codex migration because they depend on external email/calendar integrations that are not yet supported end-to-end:

- `postman`
- `email-triage`
- `meeting-prep`
- `weekly-agenda`
- `deadline-radar`

## Operational Rules

- Preserve the central dispatcher experience: the user should not need to manually pick internal units.
- Follow local references for orchestration, registry, and agent directory details.
- Treat `agents-registry.md` as the single source of truth for active agents.
- Treat `agent-orchestration.md` as the source of truth for chaining rules.
- Prefer local crew behavior over generic advice when a matching crew unit exists.
- Do not depend on `CLAUDE.md` or `.claude/` production paths.

## Product Boundaries

This Codex runtime preserves:
- central dispatch
- separate agents and skills
- installed workspace runtime

Current migration exclusion:
- Postman external integrations such as Gmail, Google Calendar, Hey CLI, and MCP fallback are not part of the Codex functional parity target.
